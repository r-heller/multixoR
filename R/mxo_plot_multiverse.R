# Multiverse overview: every board as a mini-tile, arranged timeline (row) x
# time (column), with branch connectors from (parent_L, branch_t) to the
# child board.

#' Plot the entire multiverse
#'
#' Arranges every board into a timeline x time grid with branch connectors
#' from parent to child timelines.
#'
#' @param game An `mxo_game` object.
#' @param mode One of `"overview"` (default) or `"focus"`.
#' @param focus Optional list with components `L` and `t` selecting a board
#'   to expand under `mode = "focus"`.
#' @param ... Unused. Reserved for future arguments.
#' @return A `ggplot` object.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' p <- mxo_plot_multiverse(g)
#' inherits(p, "ggplot")
mxo_plot_multiverse <- function(game, mode = c("overview", "focus"),
                                focus = NULL, ...) {
  rlang::check_dots_empty()
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  mode <- match.arg(mode)
  if (mode == "focus") {
    if (is.null(focus)) {
      cli::cli_abort(
        "{.code mode = \"focus\"} requires {.arg focus = list(L, t)}.",
        call = call
      )
    }
    return(mxo_plot_board(game, L = focus$L, t = focus$t))
  }
  cfg <- game$config
  tl <- mxo_timelines(game)
  board_keys <- names(game$boards)
  parsed <- strsplit(board_keys, ":", fixed = TRUE)
  Ls <- vapply(parsed, function(p) as.integer(p[[1L]]), integer(1L))
  ts <- vapply(parsed, function(p) as.integer(p[[2L]]), integer(1L))
  board_size <- as.integer(cfg$n ^ cfg$d_spatial)
  rows <- list()
  for (i in seq_along(board_keys)) {
    L_b <- Ls[i]; t_b <- ts[i]
    board <- game$boards[[board_keys[i]]]
    occ_i <- which(board != 0L) - 1L
    if (length(occ_i) > 0L) {
      coords <- vapply(occ_i, function(j)
        .mxo_idx_to_coord(j, cfg$n, cfg$d_spatial), integer(cfg$d_spatial))
      origin <- .mxo_grid_origin(L_b, t_b)
      rows[[length(rows) + 1L]] <- tibble::tibble(
        L = L_b, t = t_b,
        x = origin$x + as.numeric(coords[1L, ]) / (cfg$n - 1L + 1e-6) - 0.5,
        y = origin$y - as.numeric(coords[2L, ]) / (cfg$n - 1L + 1e-6) + 0.5,
        player = as.integer(board[occ_i + 1L])
      )
    }
  }
  marks <- if (length(rows) == 0L) {
    tibble::tibble(L = integer(0L), t = integer(0L),
                   x = numeric(0L), y = numeric(0L), player = integer(0L))
  } else {
    do.call(rbind, lapply(rows, as.data.frame))
  }
  origin_df <- tibble::tibble(
    L = Ls, t = ts,
    cx = vapply(seq_along(Ls), function(i)
      .mxo_grid_origin(Ls[[i]], ts[[i]])$x, numeric(1L)),
    cy = vapply(seq_along(Ls), function(i)
      .mxo_grid_origin(Ls[[i]], ts[[i]])$y, numeric(1L))
  )
  branch_edges <- tl[!is.na(tl$parent), c("L", "parent", "branch_t"),
                     drop = FALSE]
  if (nrow(branch_edges) > 0L) {
    branch_edges$from_x <- vapply(seq_len(nrow(branch_edges)), function(i)
      .mxo_grid_origin(branch_edges$parent[i], branch_edges$branch_t[i])$x,
      numeric(1L))
    branch_edges$from_y <- vapply(seq_len(nrow(branch_edges)), function(i)
      .mxo_grid_origin(branch_edges$parent[i], branch_edges$branch_t[i])$y,
      numeric(1L))
    branch_edges$to_x <- vapply(seq_len(nrow(branch_edges)), function(i)
      .mxo_grid_origin(branch_edges$L[i], branch_edges$branch_t[i])$x,
      numeric(1L))
    branch_edges$to_y <- vapply(seq_len(nrow(branch_edges)), function(i)
      .mxo_grid_origin(branch_edges$L[i], branch_edges$branch_t[i])$y,
      numeric(1L))
  }
  p <- ggplot2::ggplot() +
    ggplot2::geom_tile(
      data = origin_df,
      ggplot2::aes(x = .data$cx, y = .data$cy),
      fill = "transparent", colour = .mxo_palette$grid,
      width = 0.9, height = 0.9, inherit.aes = FALSE
    )
  if (nrow(branch_edges) > 0L) {
    p <- p + ggplot2::geom_segment(
      data = branch_edges,
      ggplot2::aes(x = .data$from_x, y = .data$from_y,
                   xend = .data$to_x, yend = .data$to_y),
      colour = .mxo_palette$accent, linewidth = 0.5,
      arrow = grid::arrow(length = grid::unit(0.06, "in")),
      inherit.aes = FALSE
    )
  }
  if (nrow(marks) > 0L) {
    p <- p + ggplot2::geom_point(
      data = marks,
      ggplot2::aes(x = .data$x, y = .data$y,
                   colour = factor(.data$player)),
      size = 1.6, inherit.aes = FALSE
    ) +
      ggplot2::scale_colour_manual(
        values = .mxo_player_colours(),
        labels = .mxo_player_labels(),
        name = "player", drop = FALSE
      )
  }
  p +
    ggplot2::coord_equal() +
    ggplot2::labs(
      title = sprintf("multixoR multiverse"),
      subtitle = sprintf("timelines: %d, boards: %d",
                         length(game$timelines), length(game$boards)),
      x = "time", y = "timeline"
    ) +
    .mxo_theme()
}
