# Heuristic evaluation of a multixoR position

Returns a numeric scalar; positive values favour `player`. Terminal
states map to a large signed sentinel scaled to prefer faster wins.

## Usage

``` r
mxo_evaluate(
  game,
  player = mxo_to_move(game),
  w = NULL,
  w_timeline = 1,
  terminal_score = 1e+06
)
```

## Arguments

- game:

  An `mxo_game` object.

- player:

  Integer scalar, the perspective player (`1L` for X, `2L` for O).
  Defaults to the player to move.

- w:

  Numeric vector of length `k` giving the per-m-line weights. The
  default is exponential: `1, 8, 64, ...`.

- w_timeline:

  Numeric multiplier applied to m-lines whose direction traverses the
  timeline axis (axis class `"timeline"` or `"mixed"`). Default `1`.
  Larger values amplify cross-timeline tactics.

- terminal_score:

  Magnitude of the terminal sentinel. Default `1e6`.

## Value

A numeric scalar.

## Examples

``` r
g <- mxo_new_game()
mxo_evaluate(g)
#> [1] 0
```
