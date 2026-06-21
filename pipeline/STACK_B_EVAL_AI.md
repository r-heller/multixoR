# multixoR — Stack B: Evaluation & AI

> **Read first:** `multixoR_GAME_RULES.md`, `00_ORCHESTRATOR.md`, and the Stack A
> deliverables (the `mxo_game` engine). **Blocks on Stack A = integrated.**
> This stack is the analytical core that feeds the app, the simulation, and the
> game analysis. Everything that "rates" a position or move lives here, and there
> is exactly **one** evaluator — no parallel re-implementations downstream.

Identity: `multixoR` / `mxo_`. Pure-R, Rcpp-ready hot loops. S3, cli, rlang,
type-stable, ggplot-free (B returns numbers/objects; D does the plotting).

---

## B.0 Scope & the single-source-of-truth rule

Stack B delivers:
- a **heuristic position evaluator** `mxo_evaluate()`,
- a **negamax + alpha-beta** searcher with depth control and move ordering,
- a **light MCTS** searcher (the rules-chosen method for real-time win-prob),
- a **win-probability** function `mxo_win_prob()` (placeholder logistic in
  pass-1; calibrated from Stack C self-play in pass-2 — see orchestrator §4),
- **move rating** `mxo_rate_moves()` used by D's overlays and by analysis,
- AI move selection `mxo_ai_move()` with difficulty levels.

**Rule:** the app (E), simulation (C), and analysis (D) must all obtain ratings
and probabilities **only** through these functions. Do not duplicate scoring logic
anywhere else.

---

## B.1 Heuristic evaluator (`R/mxo_evaluate.R`)

`mxo_evaluate(game, player = mxo_to_move(game))` → numeric scalar, positive =
good for `player`. Type-stable (always one finite double; terminal wins map to a
large ± sentinel like `±1e6` scaled by remaining plies to prefer faster wins).

Heuristic = weighted count of **open lines** for each player across all five axes,
using the same existence-gated extent enumeration as Stack A's win-check but over
**all** candidate extents in the current multiverse (not just through one cell):

- For every existing length-`k` extent (existence-gated), classify by occupancy:
  - contains both colours → dead (weight 0),
  - empty → neutral (tiny structural weight),
  - `m` marks of one colour and `k-m` empty → that colour's "m-line".
- Score = `Σ w[m] * (my m-lines) − Σ w[m] * (opp m-lines)`, with `w` increasing
  steeply (e.g. `w = c(1, 8, 64)` for m=1,2,3 at k=3; a 3-line is essentially a
  win and should already be caught by win-check).
- **Cross-timeline weighting:** lines whose direction has `dL != 0` are the
  strategically distinctive ones; expose a tunable multiplier `w_timeline`
  (default 1) so Stack C can probe whether cross-timeline wins are over-easy
  (rules §12 concern). Document this knob.

Provide `.mxo_line_features(game)` (internal) returning the raw per-colour
m-line counts split by axis-class (spatial / time / timeline / mixed) — this same
feature vector feeds: the heuristic, the calibration model (C→B pass-2), and D's
"threatened lines" overlay. One feature extractor, many consumers.

Performance: enumerate extents incrementally where possible and cache the line
inventory on the game object's evaluation (do not mutate the game; use a local
cache keyed by a cheap state hash). Keep the inner loop Rcpp-ready.

---

## B.2 Negamax + alpha-beta (`R/mxo_search.R`)

`.mxo_negamax(game, depth, alpha, beta, player)` (internal) → list(`value`,
`best_move`). Standard negamax:
- terminal or `depth == 0` → return `mxo_evaluate`.
- generate legal moves (Stack A), **order** them by a fast pre-score
  (move-ordering via the m-line delta of the placed cell) to make alpha-beta
  effective.
- recurse with negation; prune on `alpha >= beta`.

Guard the branching factor: legal-move counts explode in the multiverse (branch
moves target every empty cell of every past board). Provide a **move-generation
policy** parameter:
- `branch_policy = c("all", "promising", "none")` — `"promising"` restricts
  branch moves to past cells that improve an m-line (drastically cuts the factor);
  `"none"` disables branching for shallow/fast search; `"all"` is exhaustive.
Default `"promising"`. Document the trade-off (completeness vs tractability).

Exported wrapper: `mxo_search(game, depth = 3, branch_policy = "promising")` →
type-stable list(`value`, `move` (a 1-row legal-moves tibble or 0-row if
terminal)).

---

## B.3 Light MCTS (`R/mxo_mcts.R`) — real-time win-prob method

Per the design decision, real-time win probability uses MCTS. Implement a compact
UCT:
- `mxo_mcts(game, iterations = 1000, c_uct = 1.4, rollout = "heuristic",
  branch_policy = "promising", time_budget = NULL)`.
- Tree nodes keyed by state hash; standard select→expand→simulate→backprop.
- **Rollout policy:** `"random"` (uniform legal) or `"heuristic"` (softmax over
  `.mxo_line_features` deltas — much stronger, default). Rollouts must terminate:
  rely on `ply_cap`; cap rollout depth too.
- **Branching control:** reuse `branch_policy` to keep the multiverse from
  exploding inside rollouts.
- Returns an S3 `mxo_mcts_result`: per-root-move visit counts, mean values, and
  the derived best move; plus `n_iter`, `elapsed`. Type-stable; has a print
  method.
- `time_budget` (seconds) optional: stop when exceeded (for app responsiveness).

MCTS is the slow path in pure R — keep the rollout inner loop Rcpp-ready and
document the performance ceiling (orchestrator §6, rules §9).

---

## B.4 Win probability (`R/mxo_win_prob.R`)

`mxo_win_prob(game, player = mxo_to_move(game), method = c("mcts","heuristic"),
...)` → numeric in `[0,1]`, the probability that `player` eventually wins from the
current position under the configured policy. Type-stable scalar.

- `method = "mcts"`: run `mxo_mcts`, return the root win-rate for `player`
  (with a small Laplace smoothing; handle draws by splitting or excluding per a
  documented convention).
- `method = "heuristic"`: map `mxo_evaluate` through a logistic
  `1 / (1 + exp(-(a*score + b)))`.
  - **Pass-1 (before Stack C):** `a`, `b` are **placeholder** constants, clearly
    documented as provisional. Add `@section Calibration:` noting they will be
    refit.
  - **Pass-2 (after Stack C):** load the fitted `(a,b)` (or a small isotonic/GAM
    calibrator) produced from C's self-play outcomes; ship it as internal data
    (`R/sysdata.rda` via `usethis::use_data(internal = TRUE)`); add a regression
    test pinning calibrated outputs on fixed positions. Update STATE.md handshake.

Provide `mxo_win_prob_curve(game_history, ...)` → type-stable tibble
(`ply`, `player`, `win_prob`) for D's time-series plot and for analysis.

---

## B.5 Move rating (`R/mxo_rate.R`)

`mxo_rate_moves(game, method = c("search","mcts","heuristic"), ...)` →
**type-stable tibble** (always these columns, 0 rows if terminal):
`kind, L_src, t_src, idx, player, score, win_prob, rank, label`.
- `score`: evaluation of the resulting position from the mover's perspective.
- `win_prob`: `mxo_win_prob` of the resulting position.
- `rank`: 1 = best.
- `label`: a cli-free categorical (`"best"`, `"strong"`, `"ok"`, `"weak"`,
  `"blunder"`) derived from win-prob drop vs the best move (chess-engine style).
This is the exact object D's heatmap/Top-3 overlay consumes — design its columns
for that consumer.

`mxo_ai_move(game, difficulty = c("easy","medium","hard"), ...)` → a 1-row
legal-moves tibble. Difficulty maps to search depth / MCTS iterations:
- easy: win-or-block only (depth 1 + immediate-threat check),
- medium: negamax depth ~3 `"promising"`,
- hard: MCTS with a larger budget.
Document the mapping; keep it deterministic given a seed (`withr::with_seed`).

---

## B.6 Tests (`tests/testthat/`)

`test-evaluate.R`, `test-search.R`, `test-mcts.R`, `test-win-prob.R`,
`test-rate.R`. Cover:
- evaluator: symmetric (eval for X = −eval for O on a colour-swapped position);
  recognises an immediate win as ±large; a 2-line scores above a 1-line.
- negamax: finds a forced win-in-1 and win-in-2 on constructed positions; alpha-
  beta returns the same value as a plain minimax on a tiny config (n=3, shallow).
- move ordering: best move's pre-score ranks it early (sanity, not strict).
- MCTS: more iterations ⇒ monotonic-ish improvement toward the known-best move on
  a constructed position (allow stochastic tolerance, seed it); result object is
  type-stable; respects `time_budget`.
- win_prob: in `[0,1]`; a winning terminal → ~1, losing → ~0; placeholder→
  calibrated swap doesn't break the API (pass-2 regression test).
- rate_moves: type-stable columns; terminal game → 0-row; `rank` consistent with
  `score`; `label` thresholds behave.
- single-source-of-truth: a test asserting `mxo_rate_moves`'s win_prob equals
  `mxo_win_prob` on the resulting position (no divergent logic).
- determinism: seeded `mxo_ai_move` reproducible.

Keep MCTS tests fast (small iterations, n=3 fixtures) and `skip_on_cran()` any
test > 10s.

---

## B.7 Gates
- Self-clean: Stack B tests pass; `R CMD check --as-cran` no new errors/warnings;
  examples wrapped in `\donttest{}` where > 5s (MCTS examples especially).
- Integration: loads cleanly atop A; cross-stack test that an `mxo_ai_move` is
  always legal per `mxo_legal_moves`.
- STATE.md: B → `integrated` (pass-1). Leave the B↔C calibration handshake items
  unchecked until pass-2.
- Report: functions delivered, the placeholder-vs-calibrated status of
  `mxo_win_prob`, performance notes (MCTS ceiling), and confirm C and D are now
  runnable in parallel.
