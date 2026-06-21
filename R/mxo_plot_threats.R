# Threatened-lines view. Enumerates every existence-gated length-k extent
# with at least `min_marks` marks of `player` and the rest empty (m-line in
# Stack B's vocabulary) and tags each by axis class. This is the signature
# analytic view because it shows cross-timeline (`dL != 0`) lines that the
# board renderers alone cannot make visible.

#' Plot the threatened lines of a position
#'
#' For each axis class (spatial / time / timeline / mixed), counts the
#' existence-gated extents where `player` has at least `min_marks` marks
#' and the rest are empty, and renders them as a labelled bar chart.
#'
#' @param game An `mxo_game` object.
#' @param player Integer scalar, `1L` (X) or `2L` (O). Defaults to the
#'   player to move.
#' @param min_marks Integer scalar; minimum `m` to count (default `2L`).
#' @param ... Unused. Reserved for future arguments.
#' @return A `ggplot` object showing m-line counts per axis class.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' p <- mxo_plot_threats(g, player = 1L)
#' inherits(p, "ggplot")
mxo_plot_threats <- function(game, player = mxo_to_move(game),
                             min_marks = 2L, ...) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  player <- as.integer(player)
  min_marks <- as.integer(min_marks)
  feats <- .mxo_line_features(game)
  data <- feats[feats$player == player & feats$m >= min_marks, , drop = FALSE]
  if (nrow(data) == 0L) {
    data <- tibble::tibble(
      player = player, m = min_marks,
      axis_class = factor(character(0L),
                          levels = c("spatial", "time", "timeline", "mixed")),
      count = integer(0L)
    )
  } else {
    data$axis_class <- factor(data$axis_class,
                              levels = c("spatial", "time", "timeline", "mixed"))
  }
  ggplot2::ggplot(
    data, ggplot2::aes(x = .data$axis_class, y = .data$count,
                       fill = factor(.data$m))
  ) +
    ggplot2::geom_col(position = "stack") +
    ggplot2::scale_fill_brewer(palette = "Purples", name = "marks") +
    ggplot2::labs(
      title = sprintf(
        "Threatened lines (m >= %d) -- %s",
        min_marks, if (player == 1L) "X" else "O"),
      subtitle = sprintf("status: %s", game$status),
      x = "axis class", y = "lines"
    ) +
    .mxo_theme()
}
