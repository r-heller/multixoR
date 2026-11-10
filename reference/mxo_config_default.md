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

## Examples

``` r
mxo_config_default(n = 3L, ply_cap = 8L)
#> $n
#> [1] 3
#> 
#> $d_spatial
#> [1] 3
#> 
#> $k
#> [1] 3
#> 
#> $ply_cap
#> [1] 8
#> 
#> $max_timelines
#> [1] 32
#> 
```
