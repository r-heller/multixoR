# Plot a win-probability curve

Accepts either a tibble (as produced by
[`mxo_win_prob_curve()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob_curve.md)
with columns `ply`, `player`, `win_prob`) or an `mxo_game_record` from
[`mxo_self_play()`](https://r-heller.github.io/multixoR/reference/mxo_self_play.md).

## Usage

``` r
mxo_plot_win_prob(source, ...)
```

## Arguments

- source:

  A tibble or `mxo_game_record`.

- ...:

  Unused. Reserved for future arguments.

## Value

A `ggplot` object.
