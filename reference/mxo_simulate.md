# Batch self-play simulation

Runs `n_games` self-play games between the two policies with
reproducible per-game sub-seeds.

## Usage

``` r
mxo_simulate(
  policy_x,
  policy_o,
  n_games = 100L,
  config = mxo_config_default(),
  seed = NULL,
  record_eval = TRUE,
  progress = TRUE
)
```

## Arguments

- policy_x, policy_o:

  `mxo_policy` objects.

- n_games:

  Integer scalar, number of games to play.

- config:

  A config list (see
  [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)).

- seed:

  Optional integer base seed.

- record_eval:

  Logical, passed through to
  [`mxo_self_play()`](https://r-heller.github.io/multixoR/reference/mxo_self_play.md).

- progress:

  Logical. If `TRUE` (default), display a cli progress bar.

## Value

An object of class `mxo_sim_result` with components `games`
(one-row-per-game tibble), `records` (list of `mxo_game_record`s),
`policy_x`, `policy_o`, `config`, `seed`.

## Examples

``` r
set.seed(1)
sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                    n_games = 3L,
                    config = mxo_config_default(n = 3L, ply_cap = 6L),
                    seed = 1L, record_eval = FALSE, progress = FALSE)
sim$games
#> # A tibble: 3 × 10
#>   game_id       seed winner outcome n_plies n_timelines win_axis_class
#>     <int>      <int>  <int> <chr>     <int>       <int> <chr>         
#> 1       1 1140350788     NA draw          6           4 NA            
#> 2       2  312928385     NA draw          6           3 NA            
#> 3       3  866248189     NA draw          6           4 NA            
#> # ℹ 3 more variables: cross_timeline_win <lgl>, first_move_kind <chr>,
#> #   first_move_idx <int>
```
