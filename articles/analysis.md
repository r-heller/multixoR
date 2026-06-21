# Position analysis: evaluation, search, win probability

## One evaluator, many consumers

The single source of truth for “how good is this position?” is
[`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md).
It counts existence-gated `m`-lines (length-`k` extents with `m` marks
of one colour and the rest empty) per axis class and sums a weighted
contribution from each side’s perspective.

``` r

g <- mxo_example_game()
mxo_evaluate(g)                    # X perspective by default
#> [1] -255
mxo_evaluate(g, player = 2L)       # O perspective is the negation
#> [1] -255
```

The raw feature vector — same input the heuristic and the calibrator
share — is available as an internal helper:

``` r

head(multixoR:::.mxo_line_features(g), 8L)
#> # A tibble: 8 × 4
#>   player     m axis_class count
#>    <int> <int> <chr>      <int>
#> 1      1     1 spatial       64
#> 2      2     1 spatial       54
#> 3      1     2 spatial        5
#> 4      2     2 spatial        0
#> 5      1     3 spatial        0
#> 6      2     3 spatial        0
#> 7      1     1 time           2
#> 8      2     1 time           0
```

## Searcher and MCTS

[`mxo_search()`](https://r-heller.github.io/multixoR/reference/mxo_search.md)
implements negamax + α-β with a configurable `branch_policy` (`all` /
`promising` / `none`). The branching factor of the multiverse is large,
so `none` is the practical default for fast local lookahead.

``` r

small <- mxo_new_game(n = 3L, k = 3L)
small <- mxo_move(small, "present", 0L, 0L, 0L)
res <- mxo_search(small, depth = 1L, branch_policy = "none")
res$move
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     1    13      2
```

[`mxo_mcts()`](https://r-heller.github.io/multixoR/reference/mxo_mcts.md)
is the real-time path: a light UCT with random or heuristic rollouts.
It’s seedable for reproducibility.

``` r

set.seed(1L)
mc <- mxo_mcts(small, iterations = 30L,
               rollout = "random", branch_policy = "none")
mc$move
#> # A tibble: 1 × 5
#>   kind    L_src t_src   idx player
#>   <chr>   <int> <int> <int>  <int>
#> 1 present     0     1     2      2
```

## Win probability, calibrated

[`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
maps either the evaluator score (via the package’s internal calibrator,
see `data-raw/make_calibrator.R`) or the MCTS visit distribution to a
`[0, 1]` win probability for a chosen player.

``` r

mxo_win_prob(small, player = 1L, method = "heuristic")
#> [1] 0.5428756
```

## Move rating

[`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md)
is the type-stable per-move tibble the visualisation stack and the Shiny
app consume. The `label` column applies chess-engine-style thresholds on
the win-prob drop vs the best move.

``` r

head(mxo_rate_moves(small, method = "heuristic"), 6L)
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

[`mxo_ai_move()`](https://r-heller.github.io/multixoR/reference/mxo_ai_move.md)
is the convenience wrapper for the app’s AI player; the `difficulty`
knob maps to search depth and MCTS iteration counts.

``` r

mxo_ai_move(small, difficulty = "easy", seed = 1L)
#> # A tibble: 1 × 5
#>   kind   L_src t_src   idx player
#>   <chr>  <int> <int> <int>  <int>
#> 1 branch     0     0    13      2
```
