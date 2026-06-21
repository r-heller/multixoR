# Build a multixoR policy

Returns an `mxo_policy` object: a parameterised strategy that, given a
game, picks one legal move. Thin wrapper over Stack B's searchers.

## Usage

``` r
mxo_policy(type = c("random", "heuristic", "negamax", "mcts"), ...)
```

## Arguments

- type:

  One of `"random"`, `"heuristic"`, `"negamax"`, `"mcts"`.

- ...:

  Named parameters forwarded to the underlying engine (`depth`,
  `branch_policy`, `iterations`, `time_budget`, ...).

## Value

An object of class `mxo_policy` with components `type`, `params`, `fn`
(the move-picker).

## Examples

``` r
p <- mxo_policy("random")
p
#> 
#> ── multixoR policy ─────────────────────────────────────────────────────────────
#> ℹ Type: random
```
