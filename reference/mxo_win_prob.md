# Win estimate for a player from the current position

Maps the engine's evaluation or MCTS root values to a `[0, 1]` estimate
for `player`. The interpretation depends on the selected method.

## Usage

``` r
mxo_win_prob(
  game,
  player = mxo_to_move(game),
  method = c("mcts", "heuristic"),
  ...
)
```

## Arguments

- game:

  An `mxo_game` object.

- player:

  Integer scalar, `1L` (X) or `2L` (O). Defaults to the player to move.
  Integer-valued numeric scalars are accepted; missing, fractional and
  other values are rejected, including for terminal games.

- method:

  One of `"mcts"` or `"heuristic"`. Default `"mcts"`.

- ...:

  Additional arguments forwarded to
  [`mxo_mcts()`](https://r-heller.github.io/multixoR/reference/mxo_mcts.md)
  when `method = "mcts"` or to
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  when `method = "heuristic"`.

## Value

A numeric scalar in `[0, 1]`.

## Methods and calibration

The default `method = "mcts"` converts visit-weighted rollout values to
an expected score, counting a draw as half a win, and applies smoothing
towards `0.5`. Unfinished rollouts use a bounded heuristic evaluation.
This is not the probability of a decisive win alone.

`method = "heuristic"` uses the fitted logistic calibrator shipped in
`R/sysdata.rda`. Its build recipe, `data-raw/make_calibrator.R`, uses a
small batch of random-policy self-play on a `3^3` board. Calibration
fits exclude draws, so this estimate concerns wins among decisive
outcomes in that training setting. It is not validated across all board
configurations or against human players. Legacy logistic constants are
used only if the internal fitted calibrator is absent.

Both methods return `1` for a terminal win, `0` for a terminal loss and
`0.5` for a terminal draw, without running a search or calibration fit.

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
mxo_win_prob(g, method = "heuristic")
#> [1] 0.542849
```
