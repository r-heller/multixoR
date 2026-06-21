# Opening-cell win-rate table

For each empty cell of the spatial start board, plays X's first move
there against a fixed opponent policy and aggregates the X win-rate.

## Usage

``` r
mxo_opening_table(
  opponent = mxo_policy("random"),
  n_games_per_cell = 30L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- opponent:

  An `mxo_policy` for the O player. Defaults to a random policy.

- n_games_per_cell:

  Integer scalar, games to play per opening cell.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `idx` (int), `x_win_rate`, `o_win_rate`,
`draw_rate`, `n_games`.
