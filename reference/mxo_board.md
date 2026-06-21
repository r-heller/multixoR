# Access a single board from the multiverse

Access a single board from the multiverse

## Usage

``` r
mxo_board(game, L, t)
```

## Arguments

- game:

  An `mxo_game` object.

- L:

  Integer scalar, timeline label.

- t:

  Integer scalar, time index.

## Value

An integer vector of length `n^d_spatial` with values in `{0L, 1L, 2L}`
(0 empty, 1 X, 2 O).

## Examples

``` r
mxo_board(mxo_new_game(), 0L, 0L)
#>  [1] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
#> [39] 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
```
