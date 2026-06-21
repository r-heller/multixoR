# Round-robin tournament between policies

Round-robin tournament between policies

## Usage

``` r
mxo_policy_tournament(
  policies,
  n_games = 10L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- policies:

  Named list of `mxo_policy` objects.

- n_games:

  Integer scalar, games per ordered pair.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with columns `x_policy`, `o_policy`, `x_win_rate`,
`o_win_rate`, `draw_rate`, `n_games`, plus an attribute `ranking` (a
tibble of overall win-rates ordered descending).
