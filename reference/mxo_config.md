# Game configuration

Game configuration

## Usage

``` r
mxo_config(game)
```

## Arguments

- game:

  An `mxo_game` object.

## Value

The configuration list (`n`, `d_spatial`, `k`, `ply_cap`,
`max_timelines`).

## Examples

``` r
mxo_config(mxo_new_game())
#> $n
#> [1] 4
#> 
#> $d_spatial
#> [1] 3
#> 
#> $k
#> [1] 3
#> 
#> $ply_cap
#> [1] 60
#> 
#> $max_timelines
#> [1] 32
#> 
```
