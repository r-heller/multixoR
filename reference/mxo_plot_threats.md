# Plot the threatened lines of a position

For each axis class (spatial / time / timeline / mixed), counts the
existence-gated extents where `player` has at least `min_marks` marks
and the rest are empty, and renders them as a labelled bar chart.

## Usage

``` r
mxo_plot_threats(game, player = mxo_to_move(game), min_marks = 2L, ...)
```

## Arguments

- game:

  An `mxo_game` object.

- player:

  Integer scalar, `1L` (X) or `2L` (O). Defaults to the player to move.

- min_marks:

  Integer scalar; minimum `m` to count (default `2L`).

- ...:

  Unused. Reserved for future arguments.

## Value

A `ggplot` object showing m-line counts per axis class.

## Examples

``` r
g <- mxo_new_game()
g <- mxo_move(g, "present", 0L, 0L, 0L)
p <- mxo_plot_threats(g, player = 1L)
inherits(p, "ggplot")
#> [1] TRUE
```
