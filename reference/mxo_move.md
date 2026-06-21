# Apply a move to a game state

Apply a move to a game state

## Usage

``` r
mxo_move(game, kind, L_src, t_src, idx)
```

## Arguments

- game:

  An `mxo_game` object.

- kind:

  Character scalar, `"present"` or `"branch"`.

- L_src:

  Integer scalar, source timeline label.

- t_src:

  Integer scalar, source time index.

- idx:

  Integer scalar, spatial linear index of the target cell.

## Value

A new `mxo_game` object with the move applied.

## Examples

``` r
g <- mxo_new_game()
g2 <- mxo_move(g, "present", L_src = 0L, t_src = 0L, idx = 0L)
mxo_to_move(g2)
#> [1] 2
```
