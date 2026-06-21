# Win-probability mapping.
#
# Pass-1 (this file): the heuristic method uses placeholder logistic constants
# clearly marked PROVISIONAL; the MCTS method derives the win rate directly
# from the root visit values. Pass-2 (after Stack C self-play) will replace
# `.mxo_win_prob_constants` with a fitted calibrator, ship it as internal
# data, and a regression test will pin its outputs.

# PLACEHOLDER LOGISTIC CONSTANTS -- provisional, to be replaced by Stack C
# calibration. See `mxo_win_prob()`'s Calibration section.
.mxo_win_prob_constants <- list(a = 0.01, b = 0)

# Heuristic -> probability via logistic. Saturates smoothly for large |score|.
.mxo_logistic_win_prob <- function(score, a, b) {
  z <- a * score + b
  1 / (1 + exp(-z))
}

#' Probability that a player wins from the current position
#'
#' Maps the engine's evaluation or MCTS visit counts to a `[0, 1]`
#' probability for `player`. **Pass-1 release:** the heuristic logistic
#' constants are provisional; they will be refit from Stack C self-play data
#' in pass-2.
#'
#' @section Calibration:
#' The default `method = "heuristic"` uses placeholder logistic constants
#' (`.mxo_win_prob_constants` in this package). Pass-2 of the build replaces
#' them with values fit from `inst/extdata/self_play_results.rds` and pins
#' the result with a regression test. See `pipeline/00_ORCHESTRATOR.md` §4.
#'
#' @param game An `mxo_game` object.
#' @param player Integer scalar, `1L` (X) or `2L` (O). Defaults to the player
#'   to move.
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
  player <- as.integer(player)
  if (mxo_is_terminal(game)) {
    if (game$status == "draw") return(0.5)
    return(if (identical(game$winner, player)) 1 else 0)
  }
  if (method == "heuristic") {
    score <- mxo_evaluate(game, player = player, ...)
    a <- .mxo_win_prob_constants$a
    b <- .mxo_win_prob_constants$b
    return(.mxo_logistic_win_prob(score, a, b))
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

#' Win-probability curve along a game history
#'
#' Replays the history one ply at a time and returns the win probability for
#' each player after every ply.
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
