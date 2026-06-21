# Branch-frequency study

Compare outcomes under different branch policies to quantify whether
free branching is balanced.

## Usage

``` r
mxo_branch_study(
  policy_factory,
  n_games = 30L,
  config = mxo_config_default(),
  seed = NULL
)
```

## Arguments

- policy_factory:

  A function `function(branch_policy) mxo_policy(...)` that returns a
  policy configured with the given `branch_policy`.

- n_games:

  Integer scalar, games per branch policy.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

## Value

A tibble with one row per branch policy: `branch_policy`, `x_win_rate`,
`o_win_rate`, `draw_rate`, `mean_plies`, `mean_timelines`,
`cross_timeline_fraction`.
