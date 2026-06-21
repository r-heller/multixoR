# multixoR — Build State

## Stacks

| Stack | Status | Blocks on | Last updated | Notes |
|----|----|----|----|----|
| A Core | done | — | 2026-06-21 | 248 assertions across 6 files; 121 directions confirmed. |
| B Eval/AI | done | A | 2026-06-21 | mxo_evaluate, mxo_search, mxo_mcts, mxo_win_prob (calibrated default), mxo_rate_moves, mxo_ai_move. |
| C Sim | done | B | 2026-06-21 | mxo_policy, self-play, simulate, strategy (§12 timeline-win stress test), calibration; B-pass-2 swap shipped via R/sysdata.rda. |
| D Viz | done | B | 2026-06-21 | mxo_plot_board (slices+cube), multiverse / threats / win-prob / eval / opening / tree; autoplot. |
| E App+Ship | done | C, D | 2026-06-21 | mxo_run_app (Shiny + bslib + DT in Suggests), mxo_example_game, README, \_pkgdown.yml, vignettes/multixoR.Rmd. Full pkg `R CMD check --as-cran` 0/0/0 across all stacks. |

Status values: `not_started` \| `in_progress` \| `self_clean` \|
`integrated` \| `done`.

## Calibration handshake (B↔︎C)

C has produced self-play calibration data via
[`mxo_make_calibration_data()`](https://r-heller.github.io/multixoR/reference/mxo_make_calibration_data.md)
(the data-raw script runs a 40-game random-vs-random batch on 3^3, k=3).

B has fitted the win-prob calibration curve from C’s data
(`mxo_fit_calibration(type = "logistic")`).

B’s
[`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
uses the fitted curve via `R/sysdata.rda` (`mxo_calibrator_default`),
with the legacy logistic constants kept as a defensive fallback for
builds where `sysdata.rda` is unavailable.

## Runnable set

- All five stacks are `done`. The package is CRAN-clean
  (`R CMD check --as-cran` → 0/0/0) and the bundled Shiny app launches
  via
  [`mxo_run_app()`](https://r-heller.github.io/multixoR/reference/mxo_run_app.md).

## Open rule clarifications (multixoR_GAME_RULES.md amendments — 2026-06-21)

1.  **§4.1 — Present-move semantics fixed to View 1.** The placed mark
    is written into the current present board `(L, present_t)`; a copy
    at `(L, present_t + 1)` is then created as the next ready present.
    The placement coordinate is `(L, present_t_before, idx)`. This
    matches the worked example in §12 (“branch @ (0,0)\[0\] is illegal
    because (0,0)\[0\] is occupied” after a present at `(0,0)[0]`).
2.  **§5.2.1 — Placement-anchored win detection.** A winning line must
    pass through the cell of the most recent placement. Cell colours are
    still read from the current board state (placement + propagation),
    but lines that no recent placement touches are not declared wins.
    This both fixes the incremental local check and avoids trivial
    “phantom” wins from pure propagation across consecutive boards in a
    timeline.

## Known issues / deferred

- The win-check returns the first winning extent found (deterministic
  per the direction-enumeration order). If multiple winning lines
  complete on the same ply, only one is reported. The S3 contract
  returns a single `win_line`; future versions may report all
  simultaneously completed lines.
- Pure `dt`-axis wins on a single timeline are effectively unreachable
  because propagation occupies the same `idx` in subsequent boards. This
  is a deliberate consequence of the placement-anchored rule; cross-axis
  tactics use mixed directions or `dL`-axis (branching).
- `as_tibble.mxo_game` returns a generic `coord` list-column for
  `d_spatial != 3`; only the default 3-D case gets `x`/`y`/`z` columns.
- **Stack B perf ceiling (pure R).**
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  is ~13 ms per call on a 3³ board with two plies;
  `mxo_search(depth = 2, branch_policy = "promising")` is ~14 s on the
  same state. The branching factor explodes with past boards.
  - `mxo_ai_move(difficulty = "medium")` therefore uses
    `branch_policy = "none"` in v1.0 instead of the orchestrator’s
    “promising depth ~3” target — restoring it requires either an Rcpp
    hot-loop or incremental feature caching. Tracked for a future pass.
  - MCTS heuristic rollouts (which call `mxo_evaluate` per step) are
    very slow; the default rollout in user-facing entry points is the
    random policy. The heuristic policy remains exposed via
    `rollout = "heuristic"`.
- **B↔︎C handshake — pass-1 incomplete.**
  `mxo_win_prob(method = "heuristic")` uses placeholder logistic
  constants (`.mxo_win_prob_constants` in `R/mxo_win_prob.R`). Stack C
  must produce calibration data and re-fit these constants; pin them
  with a regression test in B at that point.
