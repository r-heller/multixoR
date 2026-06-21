# autoplot dispatch for ergonomic exploration.

#' Auto-render a multixoR game
#'
#' Dispatches to the renderer named by `type`.
#'
#' @param object An `mxo_game` object.
#' @param type One of `"multiverse"` (default), `"board"`, `"threats"`,
#'   `"tree"`.
#' @param ... Additional arguments forwarded to the selected renderer.
#'   For `type = "board"`, supply `L` and `t`.
#' @return A `ggplot` (or `plotly` for `type = "board", view = "cube"`).
#' @export
#' @method autoplot mxo_game
autoplot.mxo_game <- function(object,
                              type = c("multiverse", "board",
                                       "threats", "tree"),
                              ...) {
  type <- match.arg(type)
  switch(
    type,
    multiverse = mxo_plot_multiverse(object, ...),
    board      = mxo_plot_board(object, ...),
    threats    = mxo_plot_threats(object, ...),
    tree       = mxo_plot_tree(object, ...)
  )
}

#' Auto-render a simulation result
#'
#' Renders the per-outcome counts of an `mxo_sim_result` as a bar chart.
#'
#' @param object An `mxo_sim_result`.
#' @param ... Unused.
#' @return A `ggplot` object.
#' @export
#' @method autoplot mxo_sim_result
autoplot.mxo_sim_result <- function(object, ...) {
  rlang::check_dots_empty()
  g <- object$games
  if (nrow(g) == 0L) {
    return(ggplot2::ggplot() +
             ggplot2::labs(title = "Simulation result (0 games)") +
             .mxo_theme())
  }
  df <- as.data.frame(table(outcome = g$outcome))
  ggplot2::ggplot(df, ggplot2::aes(x = .data$outcome, y = .data$Freq,
                                   fill = .data$outcome)) +
    ggplot2::geom_col() +
    ggplot2::scale_fill_brewer(palette = "Set2", guide = "none") +
    ggplot2::labs(title = "Simulation outcomes",
                  x = "outcome", y = "games") +
    .mxo_theme()
}

#' Auto-render a self-play record
#'
#' Returns the win-probability curve of the record via [mxo_plot_win_prob()].
#'
#' @param object An `mxo_game_record`.
#' @param ... Unused.
#' @return A `ggplot` object.
#' @export
#' @method autoplot mxo_game_record
autoplot.mxo_game_record <- function(object, ...) {
  rlang::check_dots_empty()
  mxo_plot_win_prob(object)
}
