# 5. Strategy, evaluation and AI

[Part
4](https://r-heller.github.io/multixoR/articles/tutorial-4-winning.md)
showed how lines complete. This page is about *judging* a position
before it is won, and letting the package play for you. Every analysis
function here consumes the engine’s state object directly – there is one
engine and one evaluator behind the app, the simulations, and the AI.

## Evaluating a position

[`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
returns a single heuristic score from the side-to-move’s point of view.
It weighs each player’s threatened lines across all axis classes:

``` r

g <- mxo_example_game()
mxo_evaluate(g)
#> [1] -255
```

[`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
maps that score onto a calibrated `[0, 1]` win probability, which is
easier to reason about than a raw heuristic:

``` r

mxo_win_prob(g, method = "heuristic")
#> [1] 0.5423645
```

## Rating every legal move

[`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md)
is the type-stable per-move table the visualisation stack and the Shiny
app consume: it scores and ranks every legal move. On the full `4^3`
cube this is heavy under the pure-R engine, so – as in the package’s own
vignettes – we demonstrate it on a smaller `3^3` position:

``` r

small <- mxo_new_game(n = 3L, k = 3L)
small <- mxo_move(small, "present", 0L, 0L, 0L)
head(mxo_rate_moves(small, method = "heuristic"), 6)
#> # A tibble: 6 × 9
#>   kind    L_src t_src   idx player score win_prob  rank label
#>   <chr>   <int> <int> <int>  <int> <dbl>    <dbl> <int> <chr>
#> 1 present     0     1     1      2   -78    0.543    41 best 
#> 2 present     0     1     2      2   -70    0.543    28 best 
#> 3 present     0     1     3      2   -78    0.543    41 best 
#> 4 present     0     1     4      2   -72    0.543    35 best 
#> 5 present     0     1     5      2   -78    0.543    41 best 
#> 6 present     0     1     6      2   -70    0.543    28 best
```

The `rank` and `label` columns make it easy to surface the best moves –
exactly what the app’s overlays do.

## Searching ahead

[`mxo_search()`](https://r-heller.github.io/multixoR/reference/mxo_search.md)
runs alpha-beta negamax to a fixed depth. The `branch_policy` argument
controls whether the search is allowed to consider branch moves
(`"none"`, `"promising"`, or `"all"`), which matters a great deal
because branching explodes the move count:

``` r

mxo_search(g, depth = 1L, branch_policy = "none")$move
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     1     1    21      2
```

For deeper, anytime search there is
[`mxo_mcts()`](https://r-heller.github.io/multixoR/reference/mxo_mcts.md),
a Monte-Carlo tree search. It is randomised, so we pass a `seed` for
reproducibility and keep the example small and fast (a `3^3` board, a
modest iteration budget, random rollouts):

``` r

mcts <- mxo_mcts(
  mxo_new_game(n = 3L, k = 3L),
  iterations = 40L, rollout = "random", seed = 1L
)
mcts
#> 
#> ── MCTS result ─────────────────────────────────────────────────────────────────
#> ℹ Iterations: 40 (elapsed 10.92s)
#> → present L0 t0 idx0: N=2, Q=1
#> → present L0 t0 idx1: N=2, Q=0
#> → present L0 t0 idx3: N=2, Q=1
#> → present L0 t0 idx6: N=2, Q=0
#> → present L0 t0 idx9: N=2, Q=1
```

## Just give me a move

For casual play you do not need any of the above directly.
[`mxo_ai_move()`](https://r-heller.github.io/multixoR/reference/mxo_ai_move.md)
wraps the search behind three difficulty levels and returns a single
move; pass a `seed` to make it reproducible:

``` r

mxo_ai_move(g, difficulty = "easy", seed = 1L)
#> # A tibble: 1 × 5
#>   kind   L_src t_src   idx player
#>   <chr>  <int> <int> <int>  <int>
#> 1 branch     0     0     5      2
mxo_ai_move(g, difficulty = "medium", seed = 1L)
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     4     2      2
```

## Strategy in a nutshell

- **Count threats, not marks.** A position is strong when you have more
  near-complete lines than your opponent –
  [`mxo_plot_threats()`](https://r-heller.github.io/multixoR/reference/mxo_plot_threats.md)
  and
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  both encode this.
- **Branches are weapons.** A timeline-axis or mixed threat can come
  from a universe your opponent is ignoring. Watch *all* timelines.
- **Respect the placement rule.** Because a win must pass through your
  latest placement, tempo matters: you cannot bank a propagated line for
  later.

Everything on this page is also available interactively – which is the
subject of the final page.

------------------------------------------------------------------------

**Previous:** [4. Winning across space, time and
timelines](https://r-heller.github.io/multixoR/articles/tutorial-4-winning.md)
 \|  **Next:** [6. Playing in the Shiny app
→](https://r-heller.github.io/multixoR/articles/tutorial-6-the-app.md)
