# multixoR — Build State

## Stacks
| Stack       | Status      | Blocks on | Last updated | Notes |
|-------------|-------------|-----------|--------------|-------|
| A Core      | integrated  | —         | 2026-06-21   | 248 test assertions across 6 files; 121 directions confirmed; R CMD check --as-cran clean (0/0/0). |
| B Eval/AI   | not_started | A         |              | Runnable. |
| C Sim       | not_started | B         |              |       |
| D Viz       | not_started | B         |              |       |
| E App+Ship  | not_started | C, D      |              |       |

Status values: `not_started` | `in_progress` | `self_clean` | `integrated` | `done`.

## Calibration handshake (B↔C)
- [ ] C has produced `self_play_results.rds` (≥ N games)
- [ ] B has fitted the win-prob calibration curve from C's data
- [ ] B's `mxo_win_prob()` uses the fitted curve (not the placeholder logistic)

## Runnable set
- **B (Eval/AI)** — only Stack A is required, and A is `integrated`.

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
