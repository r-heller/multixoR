# Changelog

## multixoR 0.1.0

Initial release.

### Engine

- Generic `n^d` lattice geometry with 121 canonical directions for the
  default 4 / 3 / 3 configuration; `(n, d_spatial, k)` are first-class
  parameters of every engine function.
- `mxo_game` S3 with
  [`mxo_new_game()`](https://r-heller.github.io/multixoR/reference/mxo_new_game.md),
  [`mxo_move()`](https://r-heller.github.io/multixoR/reference/mxo_move.md),
  [`mxo_play()`](https://r-heller.github.io/multixoR/reference/mxo_play.md),
  [`mxo_legal_moves()`](https://r-heller.github.io/multixoR/reference/mxo_legal_moves.md),
  [`mxo_undo()`](https://r-heller.github.io/multixoR/reference/mxo_undo.md),
  [`mxo_replay()`](https://r-heller.github.io/multixoR/reference/mxo_replay.md),
  [`mxo_status()`](https://r-heller.github.io/multixoR/reference/mxo_status.md),
  [`mxo_is_terminal()`](https://r-heller.github.io/multixoR/reference/mxo_is_terminal.md),
  plus type-stable accessors (`mxo_board`, `mxo_timelines`,
  `mxo_history`, `mxo_to_move`, `mxo_config`) and `as_tibble.mxo_game`.
- Placement-anchored win detection across all five axes (spatial, time,
  timeline, mixed); branching never mutates the source timeline.
- Canonical ply notation via
  [`mxo_format_ply()`](https://r-heller.github.io/multixoR/reference/mxo_format_ply.md)
  /
  [`mxo_parse_ply()`](https://r-heller.github.io/multixoR/reference/mxo_parse_ply.md).

### AI and evaluation

- [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  — heuristic weighted m-line score with a cross-timeline multiplier
  (`w_timeline`).
- [`mxo_search()`](https://r-heller.github.io/multixoR/reference/mxo_search.md)
  — negamax + α-β with `branch_policy` (`all` / `promising` / `none`).
- [`mxo_mcts()`](https://r-heller.github.io/multixoR/reference/mxo_mcts.md)
  — light UCT with random / heuristic rollouts, `time_budget`, seedable.
- [`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
  — heuristic logistic via a fitted internal calibrator (see Calibration
  below) or MCTS visit aggregation.
- [`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md)
  — type-stable per-move tibble with rank + blunder/strong/best label.
- [`mxo_ai_move()`](https://r-heller.github.io/multixoR/reference/mxo_ai_move.md)
  — easy / medium / hard difficulty knob.

### Simulation and strategy

- [`mxo_policy()`](https://r-heller.github.io/multixoR/reference/mxo_policy.md)
  thin wrapper around the searchers;
  [`mxo_self_play()`](https://r-heller.github.io/multixoR/reference/mxo_self_play.md),
  [`mxo_simulate()`](https://r-heller.github.io/multixoR/reference/mxo_simulate.md)
  with reproducible per-game sub-seeds.
- [`mxo_opening_table()`](https://r-heller.github.io/multixoR/reference/mxo_opening_table.md),
  [`mxo_policy_tournament()`](https://r-heller.github.io/multixoR/reference/mxo_policy_tournament.md),
  [`mxo_branch_study()`](https://r-heller.github.io/multixoR/reference/mxo_branch_study.md),
  [`mxo_timeline_win_rate()`](https://r-heller.github.io/multixoR/reference/mxo_timeline_win_rate.md)
  (the §12 cross-timeline-win stress test).
- [`mxo_make_calibration_data()`](https://r-heller.github.io/multixoR/reference/mxo_make_calibration_data.md) +
  [`mxo_fit_calibration()`](https://r-heller.github.io/multixoR/reference/mxo_fit_calibration.md)
  produce the default calibrator shipped in `R/sysdata.rda`;
  [`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
  resolves it via `.mxo_active_calibrator()`.

### Visualisation

- [`mxo_plot_board()`](https://r-heller.github.io/multixoR/reference/mxo_plot_board.md)
  — Z-slices (ggplot2) and rotatable cube (plotly) toggles, with `top3`
  and `heatmap` overlays consuming a
  [`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md)
  tibble.
- [`mxo_plot_multiverse()`](https://r-heller.github.io/multixoR/reference/mxo_plot_multiverse.md),
  [`mxo_plot_threats()`](https://r-heller.github.io/multixoR/reference/mxo_plot_threats.md),
  [`mxo_plot_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_plot_win_prob.md),
  [`mxo_plot_eval()`](https://r-heller.github.io/multixoR/reference/mxo_plot_eval.md),
  [`mxo_plot_opening()`](https://r-heller.github.io/multixoR/reference/mxo_plot_opening.md),
  [`mxo_plot_tree()`](https://r-heller.github.io/multixoR/reference/mxo_plot_tree.md).
- [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  methods for `mxo_game`, `mxo_sim_result`, `mxo_game_record`.

### App and docs

- [`mxo_run_app()`](https://r-heller.github.io/multixoR/reference/mxo_run_app.md)
  launches the bundled Shiny app (`shiny`, `bslib`, `DT` in Suggests)
  with the multiverse / board / threats / tree / analysis tabs.
- [`mxo_example_game()`](https://r-heller.github.io/multixoR/reference/mxo_example_game.md)
  deterministic short game with a branch, used by docs / vignettes / the
  app default state.
- Four vignettes: Getting started, Rules and geometry, Analysis,
  Self-play and simulation.
- pkgdown site at <https://r-heller.github.io/multixoR/> themed via the
  CTTIR suite’s `themakR` template.
- GitHub Actions: R-CMD-check matrix (macOS / Windows / Ubuntu ×
  release + devel + oldrel-1), pkgdown deploy, codecov.

### Performance

- Pure-R engine for v1.0. The hot loops in `.mxo_line_features()` and
  `.mxo_check_win_at()` are deliberately Rcpp-ready so a future compiled
  backend is a drop-in.
