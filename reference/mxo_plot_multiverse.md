# Plot the entire multiverse

Arranges every board into a timeline x time grid with branch connectors
from parent to child timelines.

## Usage

``` r
mxo_plot_multiverse(game, mode = c("overview", "focus"), focus = NULL, ...)
```

## Arguments

- game:

  An `mxo_game` object.

- mode:

  One of `"overview"` (default) or `"focus"`.

- focus:

  Optional list with components `L` and `t` selecting a board to expand
  under `mode = "focus"`.

- ...:

  Unused. Reserved for future arguments.

## Value

A `ggplot` object.

## Examples

``` r
g <- mxo_new_game()
g <- mxo_move(g, "present", 0L, 0L, 0L)
p <- mxo_plot_multiverse(g)
inherits(p, "ggplot")
#> [1] TRUE
```
