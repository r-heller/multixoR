# Strategy / opening analysis built on `mxo_simulate`.

#' Opening-cell win-rate table
#'
#' For each empty cell of the spatial start board, plays X's first move there
#' against a fixed opponent policy and aggregates the X win-rate.
#'
#' @param opponent An `mxo_policy` for the O player. Defaults to a random
#'   policy.
#' @param n_games_per_cell Integer scalar, games to play per opening cell.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @return A tibble with columns `idx` (int), `x_win_rate`, `o_win_rate`,
#'   `draw_rate`, `n_games`.
#' @export
mxo_opening_table <- function(opponent = mxo_policy("random"),
                              n_games_per_cell = 30L,
                              config = mxo_config_default(),
                              seed = NULL) {
  call <- rlang::current_env()
  if (!is_mxo_policy(opponent)) {
    cli::cli_abort(
      "{.arg opponent} must be an {.cls mxo_policy}.", call = call
    )
  }
  board_size <- as.integer(config$n ^ config$d_spatial)
  if (!is.null(seed)) withr::local_seed(seed)
  cell_seeds <- as.integer(sample.int(.Machine$integer.max - 1L, board_size))
  out <- vector("list", board_size)
  for (i in seq_len(board_size)) {
    forced <- mxo_policy_force_first(
      first = list(kind = "present", L_src = 0L, t_src = 0L,
                   idx = as.integer(i - 1L)),
      fallback = mxo_policy("heuristic", branch_policy = "none")
    )
    sim <- mxo_simulate(forced, opponent, n_games = n_games_per_cell,
                        config = config, seed = cell_seeds[[i]],
                        record_eval = FALSE, progress = FALSE)
    g <- sim$games
    out[[i]] <- list(
      idx = as.integer(i - 1L),
      x_win_rate = mean(g$outcome == "x_win"),
      o_win_rate = mean(g$outcome == "o_win"),
      draw_rate = mean(g$outcome == "draw"),
      n_games = nrow(g)
    )
  }
  tibble::tibble(
    idx = vapply(out, function(o) o$idx, integer(1L)),
    x_win_rate = vapply(out, function(o) o$x_win_rate, numeric(1L)),
    o_win_rate = vapply(out, function(o) o$o_win_rate, numeric(1L)),
    draw_rate = vapply(out, function(o) o$draw_rate, numeric(1L)),
    n_games = vapply(out, function(o) o$n_games, integer(1L))
  )
}

# Wrap an existing policy so that its first move is fixed to `first`, while
# all subsequent moves come from `fallback`. Internal helper for opening
# studies and forced openings.
mxo_policy_force_first <- function(first, fallback) {
  params <- list(first = first, fallback = fallback)
  fn <- function(game) {
    if (length(game$history) == 0L) {
      m <- first
      moves <- mxo_legal_moves(game)
      if (nrow(moves) == 0L) return(.mxo_empty_move_row())
      hit <- which(moves$kind == m$kind & moves$L_src == m$L_src &
                   moves$t_src == m$t_src & moves$idx == m$idx)
      if (length(hit) == 0L) {
        return(moves[sample.int(nrow(moves), 1L), , drop = FALSE])
      }
      return(moves[hit[[1L]], , drop = FALSE])
    }
    fallback$fn(game)
  }
  structure(list(type = "forced_first", params = params, fn = fn),
            class = "mxo_policy")
}

#' Round-robin tournament between policies
#'
#' @param policies Named list of `mxo_policy` objects.
#' @param n_games Integer scalar, games per ordered pair.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @return A tibble with columns `x_policy`, `o_policy`, `x_win_rate`,
#'   `o_win_rate`, `draw_rate`, `n_games`, plus an attribute `ranking` (a
#'   tibble of overall win-rates ordered descending).
#' @export
mxo_policy_tournament <- function(policies, n_games = 10L,
                                  config = mxo_config_default(),
                                  seed = NULL) {
  call <- rlang::current_env()
  if (!is.list(policies) || is.null(names(policies)) ||
      any(!nzchar(names(policies)))) {
    cli::cli_abort(
      "{.arg policies} must be a named list of {.cls mxo_policy} objects.",
      call = call
    )
  }
  if (!is.null(seed)) withr::local_seed(seed)
  combos <- expand.grid(
    x = names(policies), o = names(policies),
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  combos <- combos[combos$x != combos$o, , drop = FALSE]
  combo_seeds <- as.integer(sample.int(.Machine$integer.max - 1L, nrow(combos)))
  rows <- vector("list", nrow(combos))
  for (i in seq_len(nrow(combos))) {
    sim <- mxo_simulate(policies[[combos$x[i]]], policies[[combos$o[i]]],
                        n_games = n_games, config = config,
                        seed = combo_seeds[[i]],
                        record_eval = FALSE, progress = FALSE)
    g <- sim$games
    rows[[i]] <- tibble::tibble(
      x_policy = combos$x[i], o_policy = combos$o[i],
      x_win_rate = mean(g$outcome == "x_win"),
      o_win_rate = mean(g$outcome == "o_win"),
      draw_rate = mean(g$outcome == "draw"),
      n_games = nrow(g)
    )
  }
  pair_table <- do.call(rbind, rows)
  ranking <- tibble::tibble(
    policy = names(policies),
    win_rate = vapply(names(policies), function(p) {
      as_x <- pair_table[pair_table$x_policy == p, ]
      as_o <- pair_table[pair_table$o_policy == p, ]
      total <- sum(as_x$n_games) + sum(as_o$n_games)
      if (total == 0L) return(NA_real_)
      (sum(as_x$x_win_rate * as_x$n_games) +
         sum(as_o$o_win_rate * as_o$n_games)) / total
    }, numeric(1L))
  )
  ranking <- ranking[order(-ranking$win_rate), , drop = FALSE]
  attr(pair_table, "ranking") <- ranking
  pair_table
}

#' Cross-timeline win-rate stress test
#'
#' Reports the fraction of decisive games (non-draws) whose winning line
#' includes a `dL != 0` step (axis class `"timeline"` or `"mixed"`). The
#' rules §12 stress-test number — a value far above the spatial baseline
#' suggests the timeline axis may be over-easy and warrants a rule review.
#'
#' @param policy_x,policy_o `mxo_policy` objects.
#' @param n_games Integer scalar, total games to play.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @return A tibble with columns `n_games`, `n_wins`, `cross_timeline_wins`,
#'   `cross_timeline_fraction`, plus a counts-by-axis-class breakdown.
#' @export
mxo_timeline_win_rate <- function(policy_x, policy_o,
                                  n_games = 30L,
                                  config = mxo_config_default(),
                                  seed = NULL) {
  sim <- mxo_simulate(policy_x, policy_o, n_games = n_games,
                      config = config, seed = seed,
                      record_eval = FALSE, progress = FALSE)
  g <- sim$games
  n_wins <- sum(g$outcome %in% c("x_win", "o_win"))
  cross <- sum(g$cross_timeline_win, na.rm = TRUE)
  by_class <- table(
    factor(g$win_axis_class[g$outcome %in% c("x_win", "o_win")],
           levels = c("spatial", "time", "timeline", "mixed"))
  )
  tibble::tibble(
    n_games = nrow(g),
    n_wins = n_wins,
    cross_timeline_wins = cross,
    cross_timeline_fraction = if (n_wins > 0L) cross / n_wins else NA_real_,
    spatial = as.integer(by_class[["spatial"]]),
    time = as.integer(by_class[["time"]]),
    timeline = as.integer(by_class[["timeline"]]),
    mixed = as.integer(by_class[["mixed"]])
  )
}

#' Branch-frequency study
#'
#' Compare outcomes under different branch policies to quantify whether
#' free branching is balanced.
#'
#' @param policy_factory A function `function(branch_policy) mxo_policy(...)`
#'   that returns a policy configured with the given `branch_policy`.
#' @param n_games Integer scalar, games per branch policy.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @return A tibble with one row per branch policy: `branch_policy`,
#'   `x_win_rate`, `o_win_rate`, `draw_rate`, `mean_plies`, `mean_timelines`,
#'   `cross_timeline_fraction`.
#' @export
mxo_branch_study <- function(policy_factory,
                             n_games = 30L,
                             config = mxo_config_default(),
                             seed = NULL) {
  call <- rlang::current_env()
  if (!is.function(policy_factory)) {
    cli::cli_abort(
      "{.arg policy_factory} must be a function of one argument.", call = call
    )
  }
  if (!is.null(seed)) withr::local_seed(seed)
  policies <- c("all", "promising", "none")
  ps_seeds <- as.integer(sample.int(.Machine$integer.max - 1L, length(policies)))
  rows <- vector("list", length(policies))
  for (i in seq_along(policies)) {
    bp <- policies[[i]]
    p <- policy_factory(bp)
    sim <- mxo_simulate(p, p, n_games = n_games, config = config,
                        seed = ps_seeds[[i]], record_eval = FALSE,
                        progress = FALSE)
    s <- summary(sim)
    rows[[i]] <- tibble::tibble(
      branch_policy = bp,
      x_win_rate = s$x_win_rate, o_win_rate = s$o_win_rate,
      draw_rate = s$draw_rate, mean_plies = s$mean_plies,
      mean_timelines = s$mean_timelines,
      cross_timeline_fraction = s$cross_timeline_win_fraction
    )
  }
  do.call(rbind, rows)
}
