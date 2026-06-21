# Probability that a player wins from the current position

Maps the engine's evaluation or MCTS visit counts to a `[0, 1]`
probability for `player`. **Pass-1 release:** the heuristic logistic
constants are provisional; they will be refit from Stack C self-play
data in pass-2.

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

## Calibration

The default `method = "heuristic"` uses placeholder logistic constants
(`.mxo_win_prob_constants` in this package). Pass-2 of the build
replaces them with values fit from `inst/extdata/self_play_results.rds`
and pins the result with a regression test. See
`pipeline/00_ORCHESTRATOR.md` §4.

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
mxo_win_prob(g, method = "heuristic")
#> [1] 0.542849
```
