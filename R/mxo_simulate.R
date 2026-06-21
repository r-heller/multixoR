# Batch simulation between two policies.
#
# Returns an `mxo_sim_result` whose `games` field is the tidy one-row-per-game
# tibble required by Stack D and downstream analysis. A base `seed` spawns
# per-game sub-seeds so the entire run is reproducible.

# Empty 0-row games tibble — used for n_games = 0 and as a typed default.
.mxo_empty_games <- function() {
  tibble::tibble(
    game_id = integer(0L), seed = integer(0L), winner = integer(0L),
    outcome = character(0L), n_plies = integer(0L),
    n_timelines = integer(0L), win_axis_class = character(0L),
    cross_timeline_win = logical(0L), first_move_kind = character(0L),
    first_move_idx = integer(0L)
  )
}

#' Batch self-play simulation
#'
#' Runs `n_games` self-play games between the two policies with
#' reproducible per-game sub-seeds.
#'
#' @param policy_x,policy_o `mxo_policy` objects.
#' @param n_games Integer scalar, number of games to play.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @param record_eval Logical, passed through to [mxo_self_play()].
#' @param progress Logical. If `TRUE` (default), display a cli progress bar.
#' @return An object of class `mxo_sim_result` with components `games`
#'   (one-row-per-game tibble), `records` (list of `mxo_game_record`s),
#'   `policy_x`, `policy_o`, `config`, `seed`.
#' @export
#' @examples
#' set.seed(1)
#' sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
#'                     n_games = 3L,
#'                     config = mxo_config_default(n = 3L, ply_cap = 6L),
#'                     seed = 1L, record_eval = FALSE, progress = FALSE)
#' sim$games
mxo_simulate <- function(policy_x, policy_o, n_games = 100L,
                         config = mxo_config_default(),
                         seed = NULL,
                         record_eval = TRUE,
                         progress = TRUE) {
  call <- rlang::current_env()
  n_games <- as.integer(n_games)
  if (is.na(n_games) || n_games < 0L) {
    cli::cli_abort("{.arg n_games} must be a non-negative integer.", call = call)
  }
  if (n_games == 0L) {
    return(structure(list(
      games = .mxo_empty_games(),
      records = list(),
      policy_x = policy_x, policy_o = policy_o,
      config = config, seed = seed
    ), class = "mxo_sim_result"))
  }
  if (!is.null(seed)) {
    withr::local_seed(seed)
    sub_seeds <- as.integer(sample.int(.Machine$integer.max - 1L, n_games))
  } else {
    sub_seeds <- as.integer(sample.int(.Machine$integer.max - 1L, n_games))
  }
  records <- vector("list", n_games)
  if (progress) cli::cli_progress_bar("Simulating games", total = n_games)
  for (i in seq_len(n_games)) {
    records[[i]] <- mxo_self_play(policy_x, policy_o, config = config,
                                  seed = sub_seeds[[i]],
                                  record_eval = record_eval)
    if (progress) cli::cli_progress_update()
  }
  if (progress) cli::cli_progress_done()
  games <- tibble::tibble(
    game_id = seq_len(n_games),
    seed = sub_seeds,
    winner = vapply(records, function(r) {
      if (is.na(r$winner)) NA_integer_ else as.integer(r$winner)
    }, integer(1L)),
    outcome = vapply(records, function(r) r$outcome, character(1L)),
    n_plies = vapply(records, function(r) as.integer(r$n_plies), integer(1L)),
    n_timelines = vapply(records, function(r) as.integer(r$n_timelines),
                         integer(1L)),
    win_axis_class = vapply(records, function(r) {
      ax <- r$win_axis_class
      if (is.null(ax) || is.na(ax)) NA_character_ else ax
    }, character(1L)),
    cross_timeline_win = vapply(records, function(r)
      as.logical(r$cross_timeline_win), logical(1L)),
    first_move_kind = vapply(records, function(r)
      as.character(r$first_move$kind), character(1L)),
    first_move_idx = vapply(records, function(r) {
      v <- r$first_move$idx
      if (is.null(v) || is.na(v)) NA_integer_ else as.integer(v)
    }, integer(1L))
  )
  structure(list(
    games = games,
    records = records,
    policy_x = policy_x, policy_o = policy_o,
    config = config, seed = seed
  ), class = "mxo_sim_result")
}

#' Summarise a batch self-play result
#'
#' Returns the key strategic diagnostics (win-rate by colour, draw-rate,
#' mean plies/timelines, and the fraction of wins decided by a cross-
#' timeline line — the §12 stress-test number).
#'
#' @param object An `mxo_sim_result`.
#' @param ... Unused.
#' @return An `mxo_sim_summary` object.
#' @export
summary.mxo_sim_result <- function(object, ...) {
  rlang::check_dots_empty()
  g <- object$games
  n <- nrow(g)
  if (n == 0L) {
    return(structure(list(
      n_games = 0L, x_win_rate = NA_real_, o_win_rate = NA_real_,
      draw_rate = NA_real_, mean_plies = NA_real_,
      mean_timelines = NA_real_, cross_timeline_win_fraction = NA_real_
    ), class = "mxo_sim_summary"))
  }
  wins <- g$outcome
  n_wins <- sum(wins %in% c("x_win", "o_win"))
  cross <- if (n_wins == 0L) NA_real_ else
    sum(g$cross_timeline_win, na.rm = TRUE) / n_wins
  structure(list(
    n_games = as.integer(n),
    x_win_rate = mean(wins == "x_win"),
    o_win_rate = mean(wins == "o_win"),
    draw_rate = mean(wins == "draw"),
    mean_plies = mean(g$n_plies),
    mean_timelines = mean(g$n_timelines),
    cross_timeline_win_fraction = cross
  ), class = "mxo_sim_summary")
}

#' @rdname summary.mxo_sim_result
#' @param x An `mxo_sim_summary`.
#' @return Invisibly returns `x`.
#' @export
print.mxo_sim_summary <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("multixoR simulation summary")
  cli::cli_alert_info("Games: {x$n_games}")
  cli::cli_alert_info(
    "Win rates: X = {round(x$x_win_rate, 3L)}; O = {round(x$o_win_rate, 3L)}; draws = {round(x$draw_rate, 3L)}"
  )
  cli::cli_alert_info(
    "Mean plies: {round(x$mean_plies, 1L)}; mean timelines: {round(x$mean_timelines, 2L)}"
  )
  cli::cli_alert_info(
    "Cross-timeline-win fraction: {round(x$cross_timeline_win_fraction, 3L)}"
  )
  invisible(x)
}

#' Print an `mxo_sim_result`
#'
#' @param x An `mxo_sim_result`.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.mxo_sim_result <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("multixoR simulation result")
  cli::cli_alert_info("Games: {nrow(x$games)}")
  cli::cli_alert_info("X policy: {x$policy_x$type}; O policy: {x$policy_o$type}")
  invisible(x)
}
