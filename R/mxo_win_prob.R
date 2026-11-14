# Win estimates from the shipped heuristic calibrator or MCTS root values.
# Legacy logistic constants are used only if the package-internal fitted
# calibrator is absent. See data-raw/make_calibrator.R for its build recipe.
.mxo_win_prob_constants <- list(a = 0.01, b = 0)

# Heuristic -> probability via logistic. Saturates smoothly for large |score|.
.mxo_logistic_win_prob <- function(score, a, b) {
  z <- a * score + b
  1 / (1 + exp(-z))
}

# Resolve the active calibrator: prefer the fitted internal object, fall
# back to the placeholder logistic.
.mxo_active_calibrator <- function() {
  ns <- asNamespace("multixoR")
  if (exists("mxo_calibrator_default", envir = ns, inherits = FALSE)) {
    return(get("mxo_calibrator_default", envir = ns))
  }
  structure(list(type = "logistic",
                 a = .mxo_win_prob_constants$a,
                 b = .mxo_win_prob_constants$b),
            class = "mxo_calibrator")
}

#' Win estimate for a player from the current position
#'
#' Maps the engine's evaluation or MCTS root values to a `[0, 1]` estimate
#' for `player`. The interpretation depends on the selected method.
#'
#' @section Methods and calibration:
#' The default `method = "mcts"` converts visit-weighted rollout values to
#' an expected score, counting a draw as half a win, and applies smoothing
#' towards `0.5`. Unfinished rollouts use a bounded heuristic evaluation.
#' This is not the probability of a decisive win alone.
#'
#' `method = "heuristic"` uses the fitted logistic calibrator shipped in
#' `R/sysdata.rda`. Its build recipe, `data-raw/make_calibrator.R`, uses a
#' small batch of random-policy self-play on a `3^3` board. Calibration fits
#' exclude draws, so this estimate concerns wins among decisive outcomes in
#' that training setting. It is not validated across all board configurations
#' or against human players. Legacy logistic constants are used only if the
#' internal fitted calibrator is absent.
#'
#' Both methods return `1` for a terminal win, `0` for a terminal loss and
#' `0.5` for a terminal draw, without running a search or calibration fit.
#'
#' @param game An `mxo_game` object.
#' @param player Integer scalar, `1L` (X) or `2L` (O). Defaults to the player
#'   to move. Integer-valued numeric scalars are accepted; missing, fractional
#'   and other values are rejected, including for terminal games.
#' @param method One of `"mcts"` or `"heuristic"`. Default `"mcts"`.
#' @param ... Additional arguments forwarded to [mxo_mcts()] when
#'   `method = "mcts"` or to [mxo_evaluate()] when `method = "heuristic"`.
#' @return A numeric scalar in `[0, 1]`.
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' mxo_win_prob(g, method = "heuristic")
mxo_win_prob <- function(game, player = mxo_to_move(game),
                         method = c("mcts", "heuristic"), ...) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  method <- match.arg(method)
  player <- .mxo_validate_player(player, call = call)
  if (mxo_is_terminal(game)) {
    if (game$status == "draw") return(0.5)
    return(if (identical(game$winner, player)) 1 else 0)
  }
  if (method == "heuristic") {
    score <- mxo_evaluate(game, player = player, ...)
    cal <- .mxo_active_calibrator()
    return(.mxo_predict_calibrator(cal, score))
  }
  res <- mxo_mcts(game, ...)
  # Root's W/N is from POV of `mxo_to_move(game)`. Convert to [0,1] win-rate
  # for the requested `player`, with Laplace smoothing.
  if (length(res$visits) == 0L) return(0.5)
  total <- sum(res$visits)
  # Aggregate "value from root mover POV" across children:
  # since values[i] = -W_child/N_child (POV swap), root mover's expected value
  # equals sum_i (visits[i] * values[i]) / total.
  if (total == 0L) return(0.5)
  v_root_mover <- sum(res$visits * res$values) / total
  # v_root_mover in [-1, 1]; convert to [0, 1] win-rate.
  p_root_mover <- (v_root_mover + 1) / 2
  smoothed <- (p_root_mover * total + 0.5) / (total + 1)
  if (identical(player, mxo_to_move(game))) smoothed else 1 - smoothed
}

#' Win-estimate curve along a game history
#'
#' Replays the history one ply at a time and returns the method-specific win
#' estimate for each player after every ply. See [mxo_win_prob()] for the
#' interpretation of heuristic and MCTS estimates.
#'
#' @param game An `mxo_game` object whose `history` will be replayed.
#' @param method Win-probability method, forwarded to [mxo_win_prob()].
#'   Default `"heuristic"` for speed.
#' @param ... Additional arguments forwarded to [mxo_win_prob()].
#' @return A type-stable tibble with columns `ply` (int), `player` (int),
#'   `win_prob` (dbl).
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' g <- mxo_move(g, "present", 0L, 1L, 26L)
#' mxo_win_prob_curve(g)
mxo_win_prob_curve <- function(game,
                               method = c("heuristic", "mcts"),
                               ...) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  method <- match.arg(method)
  cfg <- game$config
  fresh <- mxo_new_game(n = cfg$n, d_spatial = cfg$d_spatial,
                        k = cfg$k, ply_cap = cfg$ply_cap,
                        max_timelines = cfg$max_timelines)
  if (length(game$history) == 0L) {
    return(tibble::tibble(ply = integer(0L),
                          player = integer(0L),
                          win_prob = numeric(0L)))
  }
  state <- fresh
  rows_ply <- integer(0L)
  rows_player <- integer(0L)
  rows_prob <- numeric(0L)
  for (i in seq_along(game$history)) {
    rec <- game$history[[i]]
    state <- mxo_move(state, kind = rec$kind, L_src = rec$L_src,
                      t_src = rec$t_src, idx = rec$idx)
    for (pl in c(1L, 2L)) {
      rows_ply <- c(rows_ply, as.integer(i))
      rows_player <- c(rows_player, pl)
      rows_prob <- c(rows_prob,
                     mxo_win_prob(state, player = pl, method = method, ...))
    }
  }
  tibble::tibble(ply = rows_ply, player = rows_player, win_prob = rows_prob)
}
