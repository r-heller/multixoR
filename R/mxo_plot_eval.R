# Win-probability and evaluation curves, plus the openings heatmap.
# All consumers feed in tibbles produced by Stacks B/C; no scoring here.

#' Plot a win-probability curve
#'
#' Accepts either a tibble (as produced by [mxo_win_prob_curve()] with
#' columns `ply`, `player`, `win_prob`) or an `mxo_game_record` from
#' [mxo_self_play()].
#'
#' @param source A tibble or `mxo_game_record`.
#' @param ... Unused. Reserved for future arguments.
#' @return A `ggplot` object.
#' @export
mxo_plot_win_prob <- function(source, ...) {
  rlang::check_dots_empty()
  data <- .mxo_extract_winprob(source)
  if (nrow(data) == 0L) {
    return(
      ggplot2::ggplot() +
        ggplot2::labs(title = "Win-probability curve (no plies)") +
        .mxo_theme()
    )
  }
  ggplot2::ggplot(
    data, ggplot2::aes(x = .data$ply, y = .data$win_prob,
                       colour = factor(.data$player))
  ) +
    ggplot2::geom_line(linewidth = 0.8) +
    ggplot2::geom_point(size = 1.6) +
    ggplot2::scale_colour_manual(
      values = .mxo_player_colours(),
      labels = .mxo_player_labels(),
      name = "player", drop = FALSE
    ) +
    ggplot2::scale_y_continuous(limits = c(0, 1), name = "P(win)") +
    ggplot2::labs(title = "Win-probability over plies", x = "ply") +
    .mxo_theme()
}

.mxo_extract_winprob <- function(source) {
  if (inherits(source, "mxo_game_record")) {
    if (length(source$win_probs) == 0L) {
      return(tibble::tibble(
        ply = integer(0L), player = integer(0L), win_prob = numeric(0L)
      ))
    }
    return(tibble::tibble(
      ply = seq_along(source$win_probs),
      player = rep_len(1L, length(source$win_probs)),
      win_prob = source$win_probs
    ))
  }
  if (is.data.frame(source) &&
      all(c("ply", "player", "win_prob") %in% names(source))) {
    return(tibble::as_tibble(source))
  }
  cli::cli_abort(
    "{.arg source} must be a tibble (ply, player, win_prob) or an {.cls mxo_game_record}.",
    call = rlang::current_env()
  )
}

#' Plot the heuristic-evaluation curve along a game
#'
#' @param record An `mxo_game_record` from [mxo_self_play()].
#' @param ... Unused.
#' @return A `ggplot` object.
#' @export
mxo_plot_eval <- function(record, ...) {
  rlang::check_dots_empty()
  if (!inherits(record, "mxo_game_record")) {
    cli::cli_abort("{.arg record} must be an {.cls mxo_game_record}.",
                   call = rlang::current_env())
  }
  evals <- record$evals
  if (length(evals) == 0L) {
    return(ggplot2::ggplot() +
             ggplot2::labs(title = "Evaluation curve (no plies)") +
             .mxo_theme())
  }
  df <- tibble::tibble(ply = seq_along(evals), eval = evals)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$ply, y = .data$eval)) +
    ggplot2::geom_hline(yintercept = 0, linewidth = 0.4,
                        colour = .mxo_palette$grid) +
    ggplot2::geom_line(linewidth = 0.8, colour = .mxo_palette$accent) +
    ggplot2::geom_point(size = 1.6, colour = .mxo_palette$accent) +
    ggplot2::labs(title = "Heuristic evaluation (X perspective)",
                  x = "ply", y = "eval") +
    .mxo_theme()
}

#' Plot the openings heatmap
#'
#' Consumes the output of [mxo_opening_table()] and renders X's first-move
#' win-rate as a faceted-by-z heatmap.
#'
#' @param opening_table The tibble produced by [mxo_opening_table()].
#' @param n,d_spatial Geometry parameters used to derive cell coordinates.
#' @param ... Unused.
#' @return A `ggplot` object.
#' @export
mxo_plot_opening <- function(opening_table, n = 4L, d_spatial = 3L, ...) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  if (!all(c("idx", "x_win_rate") %in% names(opening_table))) {
    cli::cli_abort(
      "{.arg opening_table} must include {.field idx} and {.field x_win_rate}.",
      call = call
    )
  }
  layout <- .mxo_slice_layout(n, d_spatial)
  layout$x_win_rate <- NA_real_
  m <- match(layout$idx, opening_table$idx)
  layout$x_win_rate[!is.na(m)] <- opening_table$x_win_rate[m[!is.na(m)]]
  ggplot2::ggplot(layout, ggplot2::aes(x = .data$panel_x,
                                       y = .data$panel_y,
                                       fill = .data$x_win_rate)) +
    ggplot2::geom_tile(colour = .mxo_palette$grid, linewidth = 0.2) +
    ggplot2::scale_fill_gradient2(
      low = .mxo_palette$negative,
      mid = "white",
      high = .mxo_palette$positive,
      midpoint = 0.5,
      limits = c(0, 1),
      name = "P(X wins)"
    ) +
    ggplot2::coord_equal() +
    ggplot2::facet_wrap(~ .data$facet, labeller = ggplot2::label_both,
                        nrow = 1L) +
    ggplot2::labs(
      title = "Openings heatmap",
      subtitle = sprintf("X first-move win-rate over the spatial cube (n = %d)",
                         n),
      x = "x", y = "y"
    ) +
    .mxo_theme()
}
