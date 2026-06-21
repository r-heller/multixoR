# Win-probability curve along a game history

Replays the history one ply at a time and returns the win probability
for each player after every ply.

## Usage

``` r
mxo_win_prob_curve(game, method = c("heuristic", "mcts"), ...)
```

## Arguments

- game:

  An `mxo_game` object whose `history` will be replayed.

- method:

  Win-probability method, forwarded to
  [`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md).
  Default `"heuristic"` for speed.

- ...:

  Additional arguments forwarded to
  [`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md).

## Value

A type-stable tibble with columns `ply` (int), `player` (int),
`win_prob` (dbl).

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
g <- mxo_move(g, "present", 0L, 0L, 0L)
g <- mxo_move(g, "present", 0L, 1L, 26L)
mxo_win_prob_curve(g)
#> # A tibble: 4 × 3
#>     ply player win_prob
#>   <int>  <int>    <dbl>
#> 1     1      1    0.543
#> 2     1      2    0.543
#> 3     2      1    0.543
#> 4     2      2    0.543
```
