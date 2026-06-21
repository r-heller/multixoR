# Rate the legal moves of a position

For each legal move, evaluate the resulting position from the mover's
perspective, attach a `win_prob`, derive a chess-engine-style label
(`"best"` / `"strong"` / `"ok"` / `"weak"` / `"blunder"`) from the
probability drop vs the best move, and rank the rows.

## Usage

``` r
mxo_rate_moves(
  game,
  method = c("heuristic", "search", "mcts"),
  depth = 2L,
  mcts_iter = 200L,
  branch_policy = c("promising", "all", "none"),
  ...
)
```

## Arguments

- game:

  An `mxo_game` object.

- method:

  One of `"search"` (negamax depth lookup), `"mcts"`, or `"heuristic"`.
  Default `"heuristic"` for speed; `"search"` and `"mcts"` are slower
  but stronger.

- depth:

  Search depth when `method = "search"`. Default `2L`.

- mcts_iter:

  Iterations when `method = "mcts"`. Default `200L`.

- branch_policy:

  Branch-policy passed through to search/MCTS. Default `"promising"`.

- ...:

  Additional arguments forwarded to the chosen method.

## Value

A type-stable tibble with columns `kind`, `L_src`, `t_src`, `idx`,
`player`, `score`, `win_prob`, `rank`, `label`.

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
head(mxo_rate_moves(g))
#> # A tibble: 6 × 9
#>   kind    L_src t_src   idx player score win_prob  rank label
#>   <chr>   <int> <int> <int>  <int> <dbl>    <dbl> <int> <chr>
#> 1 present     0     0     0      1    14    0.543     2 best 
#> 2 present     0     0     1      1     8    0.543    16 best 
#> 3 present     0     0     2      1    14    0.543     2 best 
#> 4 present     0     0     3      1     8    0.543    16 best 
#> 5 present     0     0     4      1    10    0.543    10 best 
#> 6 present     0     0     5      1     8    0.543    16 best 
```
