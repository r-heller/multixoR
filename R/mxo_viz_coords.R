# Coordinate helpers and theming for the visualization stack.
#
# Internal helpers turning (L, t, idx) into 2D / 3D plot positions and a
# shared theme/palette so every renderer in Stack D has a consistent look.

# Hugo Coder accent palette used across the package.
.mxo_palette <- list(
  bg          = "white",
  fg          = "#1a1a1a",
  grid        = "#d8d8d8",
  x_colour    = "#1565C0",
  o_colour    = "#C62828",
  empty       = "#bdbdbd",
  accent      = "#5E2C8E",
  positive    = "#2E7D32",
  negative    = "#C62828",
  highlight   = "#FFB300"
)

# Discrete colour mapping for players (integer 0L empty, 1L X, 2L O).
.mxo_player_colours <- function() {
  c("0" = .mxo_palette$empty,
    "1" = .mxo_palette$x_colour,
    "2" = .mxo_palette$o_colour)
}

# Discrete labels for players.
.mxo_player_labels <- function() {
  c("0" = ".", "1" = "X", "2" = "O")
}

# Internal shared theme: theme_minimal + Hugo Coder chrome.
.mxo_theme <- function(base_size = 11L) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold",
                                         colour = .mxo_palette$accent),
      plot.subtitle = ggplot2::element_text(colour = .mxo_palette$fg),
      strip.text = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank(),
      panel.grid.major = ggplot2::element_line(colour = .mxo_palette$grid,
                                               linewidth = 0.2)
    )
}

# Z-slice layout for d_spatial == 3: returns a tibble with cell (x, y, z)
# coords and a (panel_x, panel_y) within each Z facet. Generic in n.
.mxo_slice_layout <- function(n, d_spatial) {
  call <- rlang::current_env()
  if (d_spatial != 3L) {
    cli::cli_warn(
      "Z-slice layout is defined for {.code d_spatial == 3}; using flat layout.",
      call = call
    )
  }
  board_size <- as.integer(n ^ d_spatial)
  idx <- 0:(board_size - 1L)
  coords <- vapply(idx, function(i) .mxo_idx_to_coord(i, n, d_spatial),
                   integer(d_spatial))
  if (d_spatial == 3L) {
    tibble::tibble(
      idx = idx,
      x = as.integer(coords[1L, ]),
      y = as.integer(coords[2L, ]),
      z = as.integer(coords[3L, ]),
      panel_x = as.integer(coords[1L, ]),
      panel_y = as.integer(coords[2L, ]),
      facet = factor(coords[3L, ], levels = seq.int(0L, n - 1L))
    )
  } else {
    side <- ceiling(sqrt(board_size))
    tibble::tibble(
      idx = idx,
      panel_x = (idx %% side),
      panel_y = (idx %/% side),
      facet = factor(0L, levels = 0L)
    )
  }
}

# Cube (x, y, z) coordinates for plotly views (d_spatial == 3).
.mxo_cube_coords <- function(idx, n) {
  coord <- .mxo_idx_to_coord(as.integer(idx), n, 3L)
  list(x = coord[[1L]], y = coord[[2L]], z = coord[[3L]])
}

# Multiverse-grid origin (top-left) of board (L, t) in the overview plot.
.mxo_grid_origin <- function(L, t, board_width = 1, board_height = 1,
                             gap = 0.4) {
  list(
    x = as.numeric(t) * (board_width + gap),
    y = -as.numeric(L) * (board_height + gap)
  )
}
