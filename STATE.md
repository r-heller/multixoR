# multixoR — Build State

## Stacks
| Stack       | Status      | Blocks on | Last updated | Notes |
|-------------|-------------|-----------|--------------|-------|
| A Core      | integrated  | —         | 2026-06-21   | 248 assertions across 6 files; 121 directions confirmed; R CMD check --as-cran clean. |
| B Eval/AI   | integrated  | A         | 2026-06-21   | Pass-1 — mxo_evaluate (vectorised line features), mxo_search (negamax+α-β), mxo_mcts (UCT), mxo_win_prob (placeholder logistic), mxo_rate_moves, mxo_ai_move. 5 new test files. R CMD check clean. |
| C Sim       | integrated  | B         | 2026-06-21   | mxo_policy, self-play, batch simulate, opening/tournament/branch/timeline-win-rate, calibration + B-pass-2 swap (fitted default in R/sysdata.rda). 5 new test files; R CMD check clean. |
| D Viz       | not_started | B         |              | Runnable. ggplot2/plotly/scales added to Imports. |
| E App+Ship  | not_started | C, D      |              |       |

Status values: `not_started` | `in_progress` | `self_clean` | `integrated` | `done`.

## Calibration handshake (B↔C)
- [x] C has produced self-play calibration data via `mxo_make_calibration_data()`
      (the data-raw script runs a 40-game random-vs-random batch on 3^3, k=3).
- [x] B has fitted the win-prob calibration curve from C's data
      (`mxo_fit_calibration(type = "logistic")`).
- [x] B's `mxo_win_prob()` uses the fitted curve via `R/sysdata.rda`
      (`mxo_calibrator_default`), with the legacy logistic constants kept as
      a defensive fallback for builds where `sysdata.rda` is unavailable.

## Runnable set
- **D (Viz)** — B is `integrated`. (C is also `integrated`; D was the other
  parallel branch and is the remaining pre-E stack.)

## Open rule clarifications (multixoR_GAME_RULES.md amendments — 2026-06-21)
1. **§4.1 — Present-move semantics fixed to View 1.** The placed mark is
   written into the current present board `(L, present_t)`; a copy at
   `(L, present_t + 1)` is then created as the next ready present. The
   placement coordinate is `(L, present_t_before, idx)`. This matches the
   worked example in §12 ("branch @ (0,0)[0] is illegal because (0,0)[0]
   is occupied" after a present at `(0,0)[0]`).
2. **§5.2.1 — Placement-anchored win detection.** A winning line must pass
   through the cell of the most recent placement. Cell colours are still
   read from the current board state (placement + propagation), but lines
   that no recent placement touches are not declared wins. This both fixes
   the incremental local check and avoids trivial "phantom" wins from pure
   propagation across consecutive boards in a timeline.

## Known issues / deferred
- The win-check returns the first winning extent found (deterministic per
  the direction-enumeration order). If multiple winning lines complete on
  the same ply, only one is reported. The S3 contract returns a single
  `win_line`; future versions may report all simultaneously completed
  lines.
- Pure `dt`-axis wins on a single timeline are effectively unreachable
  because propagation occupies the same `idx` in subsequent boards. This
  is a deliberate consequence of the placement-anchored rule; cross-axis
  tactics use mixed directions or `dL`-axis (branching).
- `as_tibble.mxo_game` returns a generic `coord` list-column for
  `d_spatial != 3`; only the default 3-D case gets `x`/`y`/`z` columns.
- **Stack B perf ceiling (pure R).** `mxo_evaluate()` is ~13 ms per call on a
  3³ board with two plies; `mxo_search(depth = 2, branch_policy =
  "promising")` is ~14 s on the same state. The branching factor explodes
  with past boards.
  - `mxo_ai_move(difficulty = "medium")` therefore uses
    `branch_policy = "none"` in v1.0 instead of the orchestrator's
    "promising depth ~3" target — restoring it requires either an Rcpp
    hot-loop or incremental feature caching. Tracked for a future pass.
  - MCTS heuristic rollouts (which call `mxo_evaluate` per step) are very
    slow; the default rollout in user-facing entry points is the random
    policy. The heuristic policy remains exposed via `rollout = "heuristic"`.
- **B↔C handshake — pass-1 incomplete.** `mxo_win_prob(method = "heuristic")`
  uses placeholder logistic constants (`.mxo_win_prob_constants` in
  `R/mxo_win_prob.R`). Stack C must produce calibration data and re-fit
  these constants; pin them with a regression test in B at that point.
