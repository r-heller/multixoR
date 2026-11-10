# Round-robin tournament between policies

Round-robin tournament between policies

## Usage

``` r
mxo_policy_tournament(
  policies,
  n_games = 10L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- policies:

  Named list of `mxo_policy` objects.

- n_games:

  Integer scalar, games per ordered pair.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `x_policy`, `o_policy`, `x_win_rate`,
`o_win_rate`, `draw_rate`, `n_games`, plus an attribute `ranking` (a
tibble of overall win-rates ordered descending).

## Examples

``` r
policies <- list(
  branching = mxo_policy("random"),
  flat = mxo_policy("random", branch_policy = "none")
)
res <- mxo_policy_tournament(policies, n_games = 2L,
                             config = mxo_config_default(n = 3L, ply_cap = 8L),
                             seed = 1L)
res
#> # A tibble: 2 × 6
#>   x_policy  o_policy  x_win_rate o_win_rate draw_rate n_games
#>   <chr>     <chr>          <dbl>      <dbl>     <dbl>   <int>
#> 1 flat      branching        0          0           1       2
#> 2 branching flat             0.5        0.5         0       2
attr(res, "ranking")
#> # A tibble: 2 × 2
#>   policy    win_rate
#>   <chr>        <dbl>
#> 1 branching     0.25
#> 2 flat          0.25
```
