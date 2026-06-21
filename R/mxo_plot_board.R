# Single-board renderers: Z-slices (ggplot2) and rotatable cube (plotly).
#
# `mxo_plot_board()` is the entry point. Overlays are computed from a
# `rating` tibble (produced by `mxo_rate_moves()` -- Stack B) so D never
# re-implements scoring.

#' Render a single multiverse board
#'
#' @param game An `mxo_game`.
#' @param L,t Integer scalars selecting the board.
#' @param view One of `"slices"` (default ggplot2 facetted by z) or
#'   `"cube"` (interactive plotly 3D scatter).
#' @param overlay One of `"none"`, `"top3"`, `"heatmap"`.
#' @param rating Optional rating tibble from [mxo_rate_moves()]. When
#'   `NULL` and `overlay != "none"`, the rating is computed on the fly
#'   with `method = "heuristic"`.
#' @param highlight_lines Optional list of 3-cell win-style lines to draw
#'   on top of the board (each element a `list(L, t, idx)` triple).
#'   Defaults to the win-line if the game is terminal.
#' @param ... Unused. Reserved for future arguments.
#' @return A `ggplot` (slices) or `plotly` (cube) object.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' p <- mxo_plot_board(g, L = 0L, t = 0L)
#' inherits(p, "ggplot")
mxo_plot_board <- function(game, L = 0L, t = NULL,
                           view = c("slices", "cube"),
                           overlay = c("none", "top3", "heatmap"),
                           rating = NULL,
                           highlight_lines = NULL,
                           ...) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  view <- match.arg(view)
  overlay <- match.arg(overlay)
  cfg <- game$config
  L <- as.integer(L)
  if (is.null(t)) t <- .mxo_present_t(game, L)
  t <- as.integer(t)
  board <- mxo_board(game, L, t)
  if (is.null(highlight_lines) && mxo_is_terminal(game) &&
      !is.null(game$win_line)) {
    on_this_board <- vapply(game$win_line, function(c)
      identical(as.integer(c$L), L) && identical(as.integer(c$t), t),
      logical(1L))
    if (all(on_this_board)) highlight_lines <- list(game$win_line)
  }
  if (overlay != "none" && is.null(rating)) {
    rating <- mxo_rate_moves(game, method = "heuristic")
  }
  if (view == "slices") {
    .mxo_plot_board_slices(game, L, t, board, overlay, rating, highlight_lines)
  } else {
    .mxo_plot_board_cube(game, L, t, board, overlay, rating, highlight_lines)
  }
}

.mxo_plot_board_slices <- function(game, L, t, board, overlay, rating,
                                   highlight_lines) {
  cfg <- game$config
  layout <- .mxo_slice_layout(cfg$n, cfg$d_spatial)
  layout$player <- as.integer(board[layout$idx + 1L])
  if (overlay != "none" && !is.null(rating) && nrow(rating) > 0L) {
    sub <- rating[rating$L_src == L & rating$t_src == t, , drop = FALSE]
    if (nrow(sub) > 0L) {
      layout$win_prob <- NA_real_
      layout$label <- NA_character_
      m <- match(layout$idx, sub$idx)
      layout$win_prob[!is.na(m)] <- sub$win_prob[m[!is.na(m)]]
      layout$label[!is.na(m)] <- sub$label[m[!is.na(m)]]
      if (overlay == "top3") {
        top3 <- utils::head(order(-sub$win_prob), 3L)
        keep_idx <- sub$idx[top3]
        layout$is_top3 <- layout$idx %in% keep_idx
      } else {
        layout$is_top3 <- FALSE
      }
    } else {
      layout$win_prob <- NA_real_
      layout$label <- NA_character_
      layout$is_top3 <- FALSE
    }
  }
  p <- ggplot2::ggplot(layout, ggplot2::aes(x = .data$panel_x,
                                            y = .data$panel_y))
  if (overlay == "heatmap" && "win_prob" %in% names(layout)) {
    p <- p + ggplot2::geom_tile(
      data = layout[!is.na(layout$win_prob) & layout$player == 0L, ],
      ggplot2::aes(fill = .data$win_prob),
      width = 0.95, height = 0.95
    ) + ggplot2::scale_fill_gradient2(
      low = .mxo_palette$negative,
      mid = "white",
      high = .mxo_palette$positive,
      midpoint = 0.5,
      limits = c(0, 1),
      name = "P(win)"
    )
  }
  p <- p +
    ggplot2::geom_tile(
      data = layout[layout$player == 0L, ],
      fill = "transparent",
      colour = .mxo_palette$grid, width = 0.95, height = 0.95
    ) +
    ggplot2::geom_text(
      data = layout[layout$player != 0L, ],
      ggplot2::aes(label = .mxo_player_labels()[as.character(.data$player)],
                   colour = factor(.data$player)),
      size = 6L, fontface = "bold"
    ) +
    ggplot2::scale_colour_manual(
      values = .mxo_player_colours(),
      labels = .mxo_player_labels(),
      drop = FALSE, name = "player"
    )
  if (overlay == "top3" && "is_top3" %in% names(layout)) {
    p <- p + ggplot2::geom_point(
      data = layout[layout$is_top3 & layout$player == 0L, ],
      colour = .mxo_palette$accent, size = 4L, shape = 21L,
      stroke = 1.5
    )
  }
  if (!is.null(highlight_lines)) {
    seg <- .mxo_lines_to_seg(highlight_lines, L, t, cfg)
    if (!is.null(seg) && nrow(seg) > 0L) {
      p <- p + ggplot2::geom_segment(
        data = seg,
        ggplot2::aes(x = .data$x0, y = .data$y0,
                     xend = .data$x1, yend = .data$y1),
        colour = .mxo_palette$highlight, linewidth = 1.2,
        inherit.aes = FALSE
      )
    }
  }
  p +
    ggplot2::coord_equal() +
    ggplot2::facet_wrap(~ .data$facet, labeller = ggplot2::label_both,
                        nrow = 1L) +
    ggplot2::labs(
      title = sprintf("multixoR board L%d, t%d", L, t),
      subtitle = sprintf("status: %s; to move: %s", game$status,
                         if (mxo_to_move(game) == 1L) "X" else "O"),
      x = "x", y = "y"
    ) +
    .mxo_theme()
}

# Translate a list of 3-cell lines (each cell with L, t, idx) into a tibble
# of (x0,y0,x1,y1,facet) segments suitable for ggplot2::geom_segment on the
# board (L, t).
.mxo_lines_to_seg <- function(lines, L, t, cfg) {
  rows <- list()
  for (line in lines) {
    cells <- Filter(function(c) c$L == L && c$t == t, line)
    if (length(cells) < 2L) next
    coords <- lapply(cells, function(c)
      .mxo_idx_to_coord(c$idx, cfg$n, cfg$d_spatial))
    for (i in seq_len(length(coords) - 1L)) {
      a <- coords[[i]]
      b <- coords[[i + 1L]]
      if (cfg$d_spatial >= 3L && a[[3L]] != b[[3L]]) next
      rows[[length(rows) + 1L]] <- list(
        x0 = a[[1L]], y0 = a[[2L]], x1 = b[[1L]], y1 = b[[2L]],
        facet = factor(a[[3L]], levels = seq.int(0L, cfg$n - 1L))
      )
    }
  }
  if (length(rows) == 0L) return(NULL)
  out <- do.call(rbind, lapply(rows, as.data.frame))
  tibble::as_tibble(out)
}

.mxo_plot_board_cube <- function(game, L, t, board, overlay, rating,
                                 highlight_lines) {
  cfg <- game$config
  layout <- .mxo_slice_layout(cfg$n, cfg$d_spatial)
  layout$player <- as.integer(board[layout$idx + 1L])
  layout$colour <- vapply(as.character(layout$player), function(p)
    .mxo_player_colours()[[p]], character(1L))
  occupied <- layout[layout$player != 0L, , drop = FALSE]
  empty <- layout[layout$player == 0L, , drop = FALSE]
  p <- plotly::plot_ly()
  p <- plotly::add_markers(
    p, data = empty,
    x = ~x, y = ~y, z = ~z,
    marker = list(size = 4L, color = .mxo_palette$empty, opacity = 0.4),
    name = "empty"
  )
  if (nrow(occupied) > 0L) {
    p <- plotly::add_markers(
      p, data = occupied,
      x = ~x, y = ~y, z = ~z,
      marker = list(size = 8L,
                    color = ~colour,
                    opacity = 1),
      text = ~ paste0(.mxo_player_labels()[as.character(player)],
                      " @ (", x, ",", y, ",", z, ")"),
      name = "marks"
    )
  }
  plotly::layout(
    p,
    title = sprintf("multixoR board L%d, t%d (status: %s)",
                    L, t, game$status),
    scene = list(
      xaxis = list(title = "x"),
      yaxis = list(title = "y"),
      zaxis = list(title = "z")
    )
  )
}
