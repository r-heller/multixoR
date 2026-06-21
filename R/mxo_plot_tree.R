# Branch/timeline tree as a simple ggplot dendrogram.

#' Plot the branch tree of a multixoR game
#'
#' Nodes are timelines, edges are parent->child branches drawn at the
#' branching time. Layout: x = branch_t (root at x = 0), y = timeline
#' label spread vertically.
#'
#' @param game An `mxo_game` object.
#' @param ... Unused. Reserved for future arguments.
#' @return A `ggplot` object.
#' @export
mxo_plot_tree <- function(game, ...) {
  rlang::check_dots_empty()
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  tl <- mxo_timelines(game)
  if (nrow(tl) == 0L) {
    return(ggplot2::ggplot() +
             ggplot2::labs(title = "Branch tree (no timelines)") +
             .mxo_theme())
  }
  positions <- tibble::tibble(
    L = tl$L,
    x_pos = ifelse(is.na(tl$branch_t), 0L, tl$branch_t),
    y_pos = as.integer(rank(tl$L, ties.method = "first"))
  )
  edges <- tl[!is.na(tl$parent), c("L", "parent", "branch_t"), drop = FALSE]
  if (nrow(edges) > 0L) {
    edges$from_x <- positions$x_pos[match(edges$parent, positions$L)]
    edges$from_y <- positions$y_pos[match(edges$parent, positions$L)]
    edges$to_x <- positions$x_pos[match(edges$L, positions$L)]
    edges$to_y <- positions$y_pos[match(edges$L, positions$L)]
  }
  p <- ggplot2::ggplot()
  if (nrow(edges) > 0L) {
    p <- p + ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = .data$from_x, y = .data$from_y,
                   xend = .data$to_x, yend = .data$to_y),
      colour = .mxo_palette$accent, linewidth = 0.6,
      inherit.aes = FALSE
    )
  }
  p +
    ggplot2::geom_point(
      data = positions,
      ggplot2::aes(x = .data$x_pos, y = .data$y_pos),
      colour = .mxo_palette$x_colour, size = 3.5,
      inherit.aes = FALSE
    ) +
    ggplot2::geom_text(
      data = positions,
      ggplot2::aes(x = .data$x_pos, y = .data$y_pos,
                   label = sprintf("L%d", .data$L)),
      vjust = -1.1, fontface = "bold",
      inherit.aes = FALSE
    ) +
    ggplot2::labs(title = "multixoR branch tree",
                  x = "branch time", y = "timeline order") +
    .mxo_theme()
}
