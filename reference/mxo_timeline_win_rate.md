# Cross-timeline win-rate stress test

Reports the fraction of decisive games (non-draws) whose winning line
includes a `dL != 0` step (axis class `"timeline"` or `"mixed"`). The
rules §12 stress-test number — a value far above the spatial baseline
suggests the timeline axis may be over-easy and warrants a rule review.

## Usage

``` r
mxo_timeline_win_rate(
  policy_x,
  policy_o,
  n_games = 30L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- policy_x, policy_o:

  `mxo_policy` objects.

- n_games:

  Integer scalar, total games to play.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `n_games`, `n_wins`, `cross_timeline_wins`,
`cross_timeline_fraction`, plus a counts-by-axis-class breakdown.

## Examples

``` r
mxo_timeline_win_rate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 4L,
                      config = mxo_config_default(n = 3L, ply_cap = 8L),
                      seed = 1L)
#> # A tibble: 1 × 8
#>   n_games n_wins cross_timeline_wins cross_timeline_fraction spatial  time
#>     <int>  <int>               <int>                   <dbl>   <int> <int>
#> 1       4      0                   0                      NA       0     0
#> # ℹ 2 more variables: timeline <int>, mixed <int>
```
