# multixoR 0.1.0

Initial release.

## Engine

* Generic `n^d` lattice geometry with 121 canonical directions for the
  default 4 / 3 / 3 configuration; `(n, d_spatial, k)` are first-class
  parameters of every engine function.
* `mxo_game` S3 with `mxo_new_game()`, `mxo_move()`, `mxo_play()`,
  `mxo_legal_moves()`, `mxo_undo()`, `mxo_replay()`, `mxo_status()`,
  `mxo_is_terminal()`, plus type-stable accessors
  (`mxo_board`, `mxo_timelines`, `mxo_history`, `mxo_to_move`,
  `mxo_config`) and `as_tibble.mxo_game`.
* Placement-anchored win detection across all five axes (spatial,
  time, timeline, mixed); branching never mutates the source timeline.
* Canonical ply notation via `mxo_format_ply()` / `mxo_parse_ply()`.

## AI and evaluation

* `mxo_evaluate()` — heuristic weighted m-line score with a
  cross-timeline multiplier (`w_timeline`).
* `mxo_search()` — negamax + α-β with `branch_policy` (`all` /
  `promising` / `none`).
* `mxo_mcts()` — light UCT with random / heuristic rollouts,
  `time_budget`, seedable.
* `mxo_win_prob()` — heuristic logistic via a fitted internal
  calibrator (see Calibration below) or MCTS visit aggregation.
* `mxo_rate_moves()` — type-stable per-move tibble with rank +
  blunder/strong/best label.
* `mxo_ai_move()` — easy / medium / hard difficulty knob.

## Simulation and strategy

* `mxo_policy()` thin wrapper around the searchers; `mxo_self_play()`,
  `mxo_simulate()` with reproducible per-game sub-seeds.
* `mxo_opening_table()`, `mxo_policy_tournament()`,
  `mxo_branch_study()`, `mxo_timeline_win_rate()` (the §12
  cross-timeline-win stress test).
* `mxo_make_calibration_data()` + `mxo_fit_calibration()` produce the
  default calibrator shipped in `R/sysdata.rda`; `mxo_win_prob()`
  resolves it via `.mxo_active_calibrator()`.

## Visualisation

* `mxo_plot_board()` — Z-slices (ggplot2) and rotatable cube (plotly)
  toggles, with `top3` and `heatmap` overlays consuming a
  `mxo_rate_moves()` tibble.
* `mxo_plot_multiverse()`, `mxo_plot_threats()`, `mxo_plot_win_prob()`,
  `mxo_plot_eval()`, `mxo_plot_opening()`, `mxo_plot_tree()`.
* `autoplot()` methods for `mxo_game`, `mxo_sim_result`,
  `mxo_game_record`.

## App and docs

* `mxo_run_app()` launches the bundled Shiny app (`shiny`, `bslib`,
  `DT` in Suggests) with the multiverse / board / threats / tree /
  analysis tabs.
* `mxo_example_game()` deterministic short game with a branch, used by
  docs / vignettes / the app default state.
* Four vignettes: Getting started, Rules and geometry, Analysis,
  Self-play and simulation.
* pkgdown site at https://r-heller.github.io/multixoR/ themed via the
  CTTIR suite's `themakR` template.
* GitHub Actions: R-CMD-check matrix (macOS / Windows / Ubuntu ×
  release + devel + oldrel-1), pkgdown deploy, codecov.

## Performance

* Pure-R engine for v1.0. The hot loops in `.mxo_line_features()` and
  `.mxo_check_win_at()` are deliberately Rcpp-ready so a future
  compiled backend is a drop-in.
