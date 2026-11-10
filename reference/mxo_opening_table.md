# Opening-cell win-rate table

For each empty cell of the spatial start board, plays X's first move
there against a fixed opponent policy and aggregates the X win-rate.

## Usage

``` r
mxo_opening_table(
  opponent = mxo_policy("random"),
  n_games_per_cell = 30L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- opponent:

  An `mxo_policy` for the O player. Defaults to a random policy.

- n_games_per_cell:

  Integer scalar, games to play per opening cell.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `idx` (int), `x_win_rate`, `o_win_rate`,
`draw_rate`, `n_games`.

## Examples

``` r
# A tiny two-dimensional board keeps the example fast.
mxo_opening_table(n_games_per_cell = 1L,
                  config = mxo_config_default(n = 3L, d_spatial = 2L,
                                              ply_cap = 4L),
                  seed = 1L)
#> # A tibble: 9 × 5
#>     idx x_win_rate o_win_rate draw_rate n_games
#>   <int>      <dbl>      <dbl>     <dbl>   <int>
#> 1     0          0          0         1       1
#> 2     1          0          0         1       1
#> 3     2          0          0         1       1
#> 4     3          0          0         1       1
#> 5     4          0          0         1       1
#> 6     5          0          0         1       1
#> 7     6          0          0         1       1
#> 8     7          0          0         1       1
#> 9     8          0          0         1       1
```
