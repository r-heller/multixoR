# Coerce an mxo_game_record to a tidy per-ply tibble

Coerce an mxo_game_record to a tidy per-ply tibble

## Usage

``` r
as_tibble.mxo_game_record(x, ...)
```

## Arguments

- x:

  A self-play `mxo_game_record`.

- ...:

  Unused.

## Value

A tibble with one row per ply.

## Examples

``` r
rec <- mxo_self_play(mxo_policy("random"), mxo_policy("random"),
                     config = mxo_config_default(n = 3L, ply_cap = 8L),
                     seed = 1L)
as_tibble.mxo_game_record(rec)
#> # A tibble: 8 × 9
#>     ply player kind    L_src t_src   idx L_new  eval win_prob
#>   <int>  <int> <chr>   <int> <int> <int> <int> <dbl>    <dbl>
#> 1     1      1 present     0     0    24    NA    14    0.543
#> 2     2      2 present     0     1     3    NA    78    0.543
#> 3     3      1 branch      0     0    13     1   104    0.543
#> 4     4      2 present     0     2     0    NA    52    0.543
#> 5     5      1 present     1     0     9    NA    98    0.543
#> 6     6      2 present     1     1    20    NA   369    0.544
#> 7     7      1 present     0     3    15    NA   324    0.543
#> 8     8      2 branch      1     1    21     2     0    0.5  
```
