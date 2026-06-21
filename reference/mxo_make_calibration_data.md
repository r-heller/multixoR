# Extract calibration data from self-play

For every ply in a batch of self-play games this records the heuristic
evaluation from the perspective of the position's player-to-move, plus
the eventual outcome for that player (`+1` win, `-1` loss, `0` draw).
The resulting tibble feeds
[`mxo_fit_calibration()`](https://r-heller.github.io/multixoR/reference/mxo_fit_calibration.md).

## Usage

``` r
mxo_make_calibration_data(
  n_games = 100L,
  policy_x = mxo_policy("random"),
  policy_o = mxo_policy("random"),
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- n_games:

  Integer scalar, number of self-play games to run.

- policy_x, policy_o:

  `mxo_policy` objects. Default: two random policies.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `score` (dbl, mover-perspective evaluation) and
`outcome` (int, in `{-1, 0, 1}` for mover-loss / draw / mover-win).
