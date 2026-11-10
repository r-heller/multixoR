# Branch-frequency study

Compare outcomes under different branch policies to quantify whether
free branching is balanced.

## Usage

``` r
mxo_branch_study(
  policy_factory,
  n_games = 30L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- policy_factory:

  A function `function(branch_policy) mxo_policy(...)` that returns a
  policy configured with the given `branch_policy`.

- n_games:

  Integer scalar, games per branch policy.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with one row per branch policy: `branch_policy`, `x_win_rate`,
`o_win_rate`, `draw_rate`, `mean_plies`, `mean_timelines`,
`cross_timeline_fraction`.

## Examples

``` r
factory <- function(branch_policy) {
  mxo_policy("random", branch_policy = branch_policy)
}
mxo_branch_study(factory, n_games = 2L,
                 config = mxo_config_default(n = 3L, ply_cap = 6L),
                 seed = 1L)
#> # A tibble: 3 × 7
#>   branch_policy x_win_rate o_win_rate draw_rate mean_plies mean_timelines
#>   <chr>              <dbl>      <dbl>     <dbl>      <dbl>          <dbl>
#> 1 all                    0          0         1          6            3.5
#> 2 promising              0          0         1          6            4  
#> 3 none                   0          0         1          6            1  
#> # ℹ 1 more variable: cross_timeline_fraction <dbl>
```
