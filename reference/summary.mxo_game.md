# Summarise a multixoR game

Summarise a multixoR game

## Usage

``` r
# S3 method for class 'mxo_game'
summary(object, ...)

# S3 method for class 'mxo_game_summary'
print(x, ...)
```

## Arguments

- object:

  An `mxo_game` object.

- ...:

  Unused. Reserved for future arguments.

- x:

  An `mxo_game_summary` object.

## Value

An object of class `mxo_game_summary` with counts per player and branch
information.

Invisibly returns `x`.

## Examples

``` r
summary(mxo_new_game())
#> 
#> ── mxo_game summary ────────────────────────────────────────────────────────────
#> ℹ Status: in_progress
#> ℹ Plies: 0 (0 branch ply/plies)
#> ℹ Timelines: 1; boards: 1
#> ℹ Marks: X=0, O=0; to move: X
```
