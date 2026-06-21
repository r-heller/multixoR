# Enumerate the legal moves of a game state

Enumerate the legal moves of a game state

## Usage

``` r
mxo_legal_moves(game)
```

## Arguments

- game:

  An `mxo_game` object.

## Value

A type-stable tibble with columns `kind` (chr), `L_src` (int), `t_src`
(int), `idx` (int), and `player` (int, equal to
[`mxo_to_move()`](https://r-heller.github.io/multixoR/reference/mxo_to_move.md)).
Always has these columns, including when the game is terminal (0 rows).

## Examples

``` r
g <- mxo_new_game()
nrow(mxo_legal_moves(g))
#> [1] 64
```
