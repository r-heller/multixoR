# Print a multixoR game

Print a multixoR game

## Usage

``` r
# S3 method for class 'mxo_game'
print(x, ...)

# S3 method for class 'mxo_game'
format(x, ...)
```

## Arguments

- x:

  An `mxo_game` object.

- ...:

  Unused. Reserved for future arguments.

## Value

Invisibly returns `x`.

For `format`, a character vector representation.

## Examples

``` r
print(mxo_new_game())
#> 
#> ── multixoR game ───────────────────────────────────────────────────────────────
#> ℹ Config: n=4, d_spatial=3, k=3, ply_cap=60, max_timelines=32
#> ℹ Multiverse: 1 timeline, 1 board
#> ℹ Plies played: 0; to move: X
#> ℹ Status: in_progress
#> 
#> Multiverse sketch (timelines x time; '.' = no board, '#' = occupied count)
#> L\t 0
#> L0 0
```
