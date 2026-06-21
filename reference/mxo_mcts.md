# Light UCT Monte-Carlo Tree Search

Runs `iterations` MCTS playouts (or stops earlier when `time_budget` is
exceeded) and returns a per-root-move summary.

## Usage

``` r
mxo_mcts(
  game,
  iterations = 1000L,
  c_uct = 1.4,
  rollout = c("heuristic", "random"),
  branch_policy = c("promising", "all", "none"),
  time_budget = NULL,
  rollout_depth = NULL,
  epsilon = 0.7,
  seed = NULL
)
```

## Arguments

- game:

  An `mxo_game` object.

- iterations:

  Integer scalar, maximum MCTS iterations. Default `1000L`.

- c_uct:

  Exploration constant. Default `1.4`.

- rollout:

  One of `"heuristic"` (default, epsilon-greedy over a 1-ply evaluator)
  or `"random"` (uniform legal).

- branch_policy:

  One of `"promising"` (default), `"all"`, `"none"`. See
  [`mxo_search()`](https://r-heller.github.io/multixoR/reference/mxo_search.md)
  for the trade-off.

- time_budget:

  Optional numeric. If supplied, stops once the elapsed wall time
  exceeds this many seconds.

- rollout_depth:

  Maximum rollout depth in plies. Defaults to the game's `ply_cap`.

- epsilon:

  Probability of taking the greedy move during a heuristic rollout.
  Default `0.7`.

- seed:

  Optional integer seed for reproducible runs.

## Value

An object of class `mxo_mcts_result`.

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
set.seed(1)
# Use the fast random rollout so the example terminates in milliseconds;
# heuristic rollouts are stronger but call mxo_evaluate() per step.
res <- mxo_mcts(g, iterations = 30L, branch_policy = "none",
                rollout = "random")
res$move
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     0     0      1
```
