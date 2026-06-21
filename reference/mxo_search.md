# Negamax with alpha-beta pruning

Searches `depth` plies deep under a configurable branch-move policy and
returns the best move found along with its negamax value.

## Usage

``` r
mxo_search(
  game,
  depth = 3L,
  branch_policy = c("promising", "all", "none"),
  w = NULL,
  w_timeline = 1,
  terminal_score = 1e+06
)
```

## Arguments

- game:

  An `mxo_game` object.

- depth:

  Integer scalar, search depth in plies. Default `3L`.

- branch_policy:

  One of `"promising"` (default), `"all"`, or `"none"`.

- w:

  Optional weight vector of length `k` (see
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)).

- w_timeline:

  Numeric multiplier for cross-timeline lines. Default `1`.

- terminal_score:

  Magnitude of terminal sentinel. Default `1e6`.

## Value

A type-stable list with components:

- `value` (dbl): the negamax value from the mover's perspective.

- `move` (tibble): the best move (one row in legal-moves form) or a
  zero-row tibble when the game is terminal.

## Examples

``` r
g <- mxo_new_game(n = 3L, k = 3L)
res <- mxo_search(g, depth = 1L, branch_policy = "none")
res$value
#> [1] 26
```
