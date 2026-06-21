# History as a tibble

History as a tibble

## Usage

``` r
mxo_history(game)
```

## Arguments

- game:

  An `mxo_game` object.

## Value

A tibble with one row per ply, columns `ply` (int), `player` (int),
`kind` (chr), `L_src` (int), `t_src` (int), `idx` (int), `L_new` (int,
NA when not a branch), and `t_new` (int).

## Examples

``` r
mxo_history(mxo_new_game())
#> # A tibble: 0 × 8
#> # ℹ 8 variables: ply <int>, player <int>, kind <chr>, L_src <int>, t_src <int>,
#> #   idx <int>, L_new <int>, t_new <int>
```
