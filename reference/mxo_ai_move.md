# Choose a move using a packaged difficulty knob

Choose a move using a packaged difficulty knob

## Usage

``` r
mxo_ai_move(game, difficulty = c("easy", "medium", "hard"), seed = NULL, ...)
```

## Arguments

- game:

  An `mxo_game` object.

- difficulty:

  One of `"easy"`, `"medium"`, or `"hard"`. The mapping is:

  - `"easy"` – one-ply heuristic; takes immediate wins or blocks
    immediate opponent wins, otherwise picks the best heuristic move.

  - `"medium"` – negamax depth 2 with `branch_policy = "promising"`.

  - `"hard"` – MCTS with 400 iterations, heuristic rollouts.

- seed:

  Optional integer seed for deterministic stochastic difficulty levels.

- ...:

  Additional arguments forwarded to the chosen engine.

## Value

A one-row legal-moves tibble (or a zero-row tibble at terminal states).

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
mxo_ai_move(g, difficulty = "easy", seed = 1L)
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     0    13      1
```
