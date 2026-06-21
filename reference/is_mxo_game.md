# Test whether an object is an `mxo_game`

Test whether an object is an `mxo_game`

## Usage

``` r
is_mxo_game(x)
```

## Arguments

- x:

  An object.

## Value

Logical scalar.

## Examples

``` r
is_mxo_game(mxo_new_game())
#> [1] TRUE
is_mxo_game(list())
#> [1] FALSE
```
