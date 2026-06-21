# Coerce a game to a tidy tibble of occupied cells

One row per occupied cell with full `(L, t, x, y, z, player)` columns
(for the default 3-D config; for other spatial dimensions a `coord`
list-column is used).

## Usage

``` r
as_tibble.mxo_game(x, ...)
```

## Arguments

- x:

  An `mxo_game` object.

- ...:

  Unused. Reserved for future arguments.

## Value

A tibble with one row per occupied cell.

## Examples

``` r
as_tibble.mxo_game(mxo_new_game())
#> # A tibble: 0 × 7
#> # ℹ 7 variables: L <int>, t <int>, x <int>, y <int>, z <int>, idx <int>,
#> #   player <int>
```
