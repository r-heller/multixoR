# Plot the heuristic-evaluation curve along a game

Plot the heuristic-evaluation curve along a game

## Usage

``` r
mxo_plot_eval(record, ...)
```

## Arguments

- record:

  An `mxo_game_record` from
  [`mxo_self_play()`](https://r-heller.github.io/multixoR/reference/mxo_self_play.md).

- ...:

  Unused.

## Value

A `ggplot` object.

## Examples

``` r
rec <- mxo_self_play(mxo_policy("random"), mxo_policy("random"),
                     config = mxo_config_default(n = 3L, ply_cap = 8L),
                     seed = 1L)
mxo_plot_eval(rec)
```
