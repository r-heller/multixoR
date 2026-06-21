# Play a single self-play game between two policies

Records per-ply diagnostics (when `record_eval` is `TRUE`) so the result
feeds the calibration model and D's win-prob curve directly.

## Usage

``` r
mxo_self_play(
  policy_x,
  policy_o,
  config = mxo_config_default(),
  seed = NULL,
  record_eval = TRUE
)
```

## Arguments

- policy_x, policy_o:

  Two `mxo_policy` objects (use
  [`mxo_policy()`](https://r-heller.github.io/multixoR/reference/mxo_policy.md)).

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer seed for deterministic policy stochasticity.

- record_eval:

  Logical. If `TRUE` (default), record `mxo_evaluate` and `mxo_win_prob`
  for each ply (X's perspective).

## Value

An object of class `mxo_game_record`.

## Examples

``` r
set.seed(1)
rec <- mxo_self_play(mxo_policy("random"), mxo_policy("random"),
                     config = mxo_config_default(n = 3L, ply_cap = 8L),
                     seed = 1L, record_eval = FALSE)
rec$outcome
#> [1] "draw"
```
