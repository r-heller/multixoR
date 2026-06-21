# Render a single multiverse board

Render a single multiverse board

## Usage

``` r
mxo_plot_board(
  game,
  L = 0L,
  t = NULL,
  view = c("slices", "cube"),
  overlay = c("none", "top3", "heatmap"),
  rating = NULL,
  highlight_lines = NULL,
  ...
)
```

## Arguments

- game:

  An `mxo_game`.

- L, t:

  Integer scalars selecting the board.

- view:

  One of `"slices"` (default ggplot2 facetted by z) or `"cube"`
  (interactive plotly 3D scatter).

- overlay:

  One of `"none"`, `"top3"`, `"heatmap"`.

- rating:

  Optional rating tibble from
  [`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md).
  When `NULL` and `overlay != "none"`, the rating is computed on the fly
  with `method = "heuristic"`.

- highlight_lines:

  Optional list of 3-cell win-style lines to draw on top of the board
  (each element a `list(L, t, idx)` triple). Defaults to the win-line if
  the game is terminal.

- ...:

  Unused. Reserved for future arguments.

## Value

A `ggplot` (slices) or `plotly` (cube) object.

## Examples

``` r
g <- mxo_new_game()
g <- mxo_move(g, "present", 0L, 0L, 0L)
p <- mxo_plot_board(g, L = 0L, t = 0L)
inherits(p, "ggplot")
#> [1] TRUE
```
