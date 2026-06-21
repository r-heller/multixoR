# Undo plies by replaying from a fresh game

Replay-based undo guarantees correctness and exercises history
determinism.

## Usage

``` r
mxo_undo(game, steps = 1L)
```

## Arguments

- game:

  An `mxo_game` object.

- steps:

  Integer scalar, number of plies to undo. Default 1.

## Value

A new `mxo_game` object with the last `steps` plies removed.

## Examples

``` r
g <- mxo_new_game()
g <- mxo_move(g, "present", 0L, 0L, 0L)
identical(mxo_undo(g)$history, list())
#> [1] TRUE
```
