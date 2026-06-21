# Default config list (used by self-play / simulate)

Default config list (used by self-play / simulate)

## Usage

``` r
mxo_config_default(
  n = 4L,
  d_spatial = 3L,
  k = 3L,
  ply_cap = 60L,
  max_timelines = 32L
)
```

## Arguments

- n, d_spatial, k, ply_cap, max_timelines:

  Game-config parameters, see
  [`mxo_new_game()`](https://r-heller.github.io/multixoR/reference/mxo_new_game.md).

## Value

A configuration list.
