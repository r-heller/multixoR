# Single self-play game between two policies. Produces a rich, replay-safe
# record consumed by batch simulation, calibration, and D's curves.

#' Default config list (used by self-play / simulate)
#'
#' @param n,d_spatial,k,ply_cap,max_timelines Game-config parameters, see
#'   [mxo_new_game()].
#' @return A configuration list.
#' @export
mxo_config_default <- function(n = 4L, d_spatial = 3L, k = 3L,
                               ply_cap = 60L, max_timelines = 32L) {
  list(n = as.integer(n), d_spatial = as.integer(d_spatial),
       k = as.integer(k), ply_cap = as.integer(ply_cap),
       max_timelines = as.integer(max_timelines))
}

# Classify a winning extent by its axis class (relies on direction-step deltas
# implied by the three cells of the line).
.mxo_classify_win_line <- function(win_line) {
  if (is.null(win_line) || length(win_line) < 2L) return(NA_character_)
  c1 <- win_line[[1L]]
  c2 <- win_line[[2L]]
  dL <- as.integer(c2$L - c1$L)
  dt <- as.integer(c2$t - c1$t)
  d_idx <- as.integer(c2$idx - c1$idx)
  if (dL == 0L && dt == 0L) return("spatial")
  if (dL == 0L && dt != 0L && d_idx == 0L) return("time")
  if (dL != 0L && dt == 0L && d_idx == 0L) return("timeline")
  "mixed"
}

#' Play a single self-play game between two policies
#'
#' Records per-ply diagnostics (when `record_eval` is `TRUE`) so the result
#' feeds the calibration model and D's win-prob curve directly.
#'
#' @param policy_x,policy_o Two `mxo_policy` objects (use [mxo_policy()]).
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer seed for deterministic policy stochasticity.
#' @param record_eval Logical. If `TRUE` (default), record `mxo_evaluate` and
#'   `mxo_win_prob` for each ply (X's perspective).
#' @return An object of class `mxo_game_record`.
#' @export
#' @examples
#' set.seed(1)
#' rec <- mxo_self_play(mxo_policy("random"), mxo_policy("random"),
#'                      config = mxo_config_default(n = 3L, ply_cap = 8L),
#'                      seed = 1L, record_eval = FALSE)
#' rec$outcome
mxo_self_play <- function(policy_x, policy_o,
                          config = mxo_config_default(),
                          seed = NULL,
                          record_eval = TRUE) {
  call <- rlang::current_env()
  if (!is_mxo_policy(policy_x) || !is_mxo_policy(policy_o)) {
    cli::cli_abort(
      "{.arg policy_x} and {.arg policy_o} must be {.cls mxo_policy} objects.",
      call = call
    )
  }
  if (!is.null(seed)) withr::local_seed(seed)
  game <- mxo_new_game(n = config$n, d_spatial = config$d_spatial,
                       k = config$k, ply_cap = config$ply_cap,
                       max_timelines = config$max_timelines)
  evals <- numeric(0L)
  win_probs <- numeric(0L)
  first_move <- list(kind = NA_character_, L_src = NA_integer_,
                     t_src = NA_integer_, idx = NA_integer_)
  ply <- 0L
  while (!mxo_is_terminal(game)) {
    pol <- if (mxo_to_move(game) == 1L) policy_x else policy_o
    mv <- pol$fn(game)
    if (nrow(mv) == 0L) break
    if (ply == 0L) {
      first_move <- list(kind = mv$kind, L_src = mv$L_src,
                         t_src = mv$t_src, idx = mv$idx)
    }
    game <- mxo_move(game, kind = mv$kind[[1L]], L_src = mv$L_src[[1L]],
                     t_src = mv$t_src[[1L]], idx = mv$idx[[1L]])
    ply <- ply + 1L
    if (record_eval) {
      evals <- c(evals, mxo_evaluate(game, player = 1L))
      win_probs <- c(win_probs, mxo_win_prob(game, player = 1L,
                                             method = "heuristic"))
    }
  }
  win_axis <- .mxo_classify_win_line(game$win_line)
  cross_timeline <- !is.na(win_axis) && win_axis %in% c("timeline", "mixed")
  out <- list(
    game = game,
    history = mxo_history(game),
    evals = evals,
    win_probs = win_probs,
    outcome = game$status,
    winner = game$winner,
    n_plies = as.integer(length(game$history)),
    n_timelines = as.integer(length(game$timelines)),
    win_axis_class = win_axis,
    cross_timeline_win = cross_timeline,
    first_move = first_move,
    config = config,
    record_eval = record_eval
  )
  structure(out, class = "mxo_game_record")
}

#' Print a self-play game record
#'
#' @param x An `mxo_game_record`.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.mxo_game_record <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("multixoR game record")
  cli::cli_alert_info("Outcome: {x$outcome} (winner: {x$winner})")
  cli::cli_alert_info("Plies: {x$n_plies}; timelines: {x$n_timelines}")
  cli::cli_alert_info("Win axis: {x$win_axis_class %||% NA_character_}")
  invisible(x)
}

#' Coerce an mxo_game_record to a tidy per-ply tibble
#'
#' @param x A self-play `mxo_game_record`.
#' @param ... Unused.
#' @return A tibble with one row per ply.
#' @export
as_tibble.mxo_game_record <- function(x, ...) {
  rlang::check_dots_empty()
  h <- x$history
  if (nrow(h) == 0L) {
    return(tibble::tibble(
      ply = integer(0L), player = integer(0L), kind = character(0L),
      L_src = integer(0L), t_src = integer(0L), idx = integer(0L),
      L_new = integer(0L), eval = numeric(0L), win_prob = numeric(0L)
    ))
  }
  evals <- if (length(x$evals)) x$evals else rep(NA_real_, nrow(h))
  wps <- if (length(x$win_probs)) x$win_probs else rep(NA_real_, nrow(h))
  tibble::tibble(
    ply = h$ply, player = h$player, kind = h$kind,
    L_src = h$L_src, t_src = h$t_src, idx = h$idx, L_new = h$L_new,
    eval = evals, win_prob = wps
  )
}
