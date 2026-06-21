# multixoR — Stack C: Simulation & Strategy

> **Read first:** `multixoR_GAME_RULES.md`, `00_ORCHESTRATOR.md`, Stack A & B
> deliverables. **Blocks on Stack B = integrated.** Runs in parallel with Stack D.
> This stack makes the engine play itself at scale: self-play, policy comparison,
> opening/strategy analysis, and — critically — it produces the data that
> **calibrates** Stack B's win-probability (the B↔C handshake, orchestrator §4).

Identity: `multixoR` / `mxo_`. S3, cli, rlang, type-stable, vapply, no plotting
(C returns tibbles/objects; D visualises them).

---

## C.0 Scope

- `mxo_self_play()` — play one game between two policies, return a rich record.
- `mxo_simulate()` — run many self-play games, return tidy aggregated results.
- `mxo_policy()` — a small policy abstraction wrapping Stack B searchers.
- Strategy/opening analysis: first-move win-rates, branch-frequency effects,
  cross-timeline-win prevalence (the rules §12 stress test).
- **Calibration data export** for B-pass-2.

Out of scope: changing rules, changing the evaluator (that's B), plotting (D).

---

## C.1 Policy abstraction (`R/mxo_policy.R`)

`mxo_policy(type = c("random","heuristic","negamax","mcts"), ...)` →
an `mxo_policy` S3 object: a named, parameterised strategy that, given a game,
returns a legal move. Thin wrappers over Stack B:
- `random`: uniform over `mxo_legal_moves` (with optional `branch_policy` to bias
  away from pure branch spam).
- `heuristic`: argmax `mxo_evaluate` over (policy-filtered) moves, depth 1.
- `negamax`: `mxo_search(depth, branch_policy)`.
- `mcts`: `mxo_mcts(iterations | time_budget, branch_policy)`.
Has a `print.mxo_policy`. Carries its params so results are reproducible/labelled.

---

## C.2 Single self-play game (`R/mxo_self_play.R`)

`mxo_self_play(policy_x, policy_o, config = mxo_config_default(), seed = NULL,
record_eval = TRUE)` → an `mxo_game_record` S3 object containing:
- the final `mxo_game`,
- the full `history` tibble,
- if `record_eval`: per-ply `mxo_evaluate` + `mxo_win_prob` (for X) — the raw
  material for win-prob calibration and for D's curves,
- outcome (`x_win`/`o_win`/`draw`), ply count, timeline count, whether the win
  (if any) used a `dL!=0` (cross-timeline) line, win-line axis-class.
Type-stable; seeded reproducibility via `withr::with_seed`.

`as_tibble.mxo_game_record` → one row per ply (tidy), the analysis-friendly view.

---

## C.3 Batch simulation (`R/mxo_simulate.R`)

`mxo_simulate(policy_x, policy_o, n_games = 100, config = ..., seed = NULL,
parallel = FALSE, ...)` → an `mxo_sim_result` S3 object wrapping a **tidy tibble**
(one row per game): `game_id, winner, n_plies, n_timelines, win_axis_class,
cross_timeline_win (lgl), first_move_idx, ...`, plus the per-ply eval/win-prob
records retained (or summarised) for calibration.

- `parallel`: optional via `parallel`/`future` IF already a sensible dependency;
  otherwise serial with a `cli` progress bar. Don't add a heavy parallel dep just
  for this — document the choice. (Suite hygiene: no dependency for one feature.)
- Determinism: a base `seed` spawns per-game sub-seeds so the whole run is
  reproducible.
- `summary.mxo_sim_result` → win-rate by colour, draw-rate, mean plies/timelines,
  **fraction of wins that are cross-timeline** (the key §12 diagnostic), with a
  cli print. Type-stable.

---

## C.4 Strategy & opening analysis (`R/mxo_strategy.R`)

- `mxo_opening_table(n_games_per_cell = 50, opponent = mxo_policy("mcts"), ...)` →
  tibble: for each legal first-move spatial cell, the empirical win-rate when X
  opens there (vs a fixed opponent). This is the openings heatmap D will render.
- `mxo_policy_tournament(policies, n_games = 100, ...)` → a round-robin: tibble of
  pairwise win-rates + an overall ranking (e.g. simple win-rate or Elo-lite).
  Type-stable matrix-as-tibble.
- `mxo_branch_study(...)` → measures how branch frequency (forced via policy
  `branch_policy`/branch-bias) affects outcomes and game length — quantifies
  whether free branching is balanced.
- **§12 stress test (mandatory):** `mxo_timeline_win_rate(...)` reports how often
  games are decided by cross-timeline (`dL!=0`) lines under balanced policies. If
  this is pathologically high (e.g. > ~0.8), **flag it loudly** in the report as
  evidence the timeline-axis win may need a rule amendment (raise `k` along `dL`,
  or exclude pure-`dL` lines) — and write that finding into the "Open rule
  clarifications" section of STATE.md. Do **not** silently change the rules; raise
  it for Raban's decision.

---

## C.5 Calibration data for B-pass-2 (`R/mxo_calibration.R`) — the handshake

`mxo_make_calibration_data(n_games = 1000, policies = ..., seed = ...)` →
a tidy tibble: for many positions sampled across self-play games, record
`(features or heuristic_score, eventual_outcome_for_player_to_move)`.

`mxo_fit_calibration(calib_data, type = c("logistic","isotonic"))` →
a small `mxo_calibrator` object (coefficients or step function) that maps
heuristic score → win probability, plus diagnostics (Brier score, reliability
table). Keep it tiny and serialisable.

**Handshake output:** save the fitted calibrator as **internal package data**
(`usethis::use_data(mxo_calibrator_default, internal = TRUE)`), then signal B to
swap its placeholder logistic for this object (orchestrator §4, B.4 pass-2).
Update STATE.md handshake checkboxes. Add a regression test (in B) pinning the
calibrated outputs.

Raw self-play dumps live in `data-raw/` (gitignored, not shipped); only the small
fitted calibrator and any tiny example results ship in the package (size budget,
rules §9 / CRAN limits).

---

## C.6 Tests (`tests/testthat/`)
`test-policy.R`, `test-self-play.R`, `test-simulate.R`, `test-strategy.R`,
`test-calibration.R`. Cover:
- policies always return legal moves; `mcts`/`negamax` beat `random` over a small
  seeded batch (statistical, with tolerance + `skip_on_cran` if slow).
- self-play record is type-stable; outcome ∈ valid set; per-ply eval present when
  requested; cross-timeline-win flag correct on a constructed forced game.
- simulate: reproducible under seed; tibble shape stable for `n_games = 0` (0-row,
  right columns) and `n_games = 1`; summary fractions in `[0,1]`.
- opening table: covers all first-move cells; win-rates in `[0,1]`.
- calibration: fitter produces a valid mapping; Brier score better than a 0.5
  constant baseline on held-out data; calibrator round-trips through
  serialization.
- keep batch sizes tiny in tests; gate anything slow with `skip_on_cran()`.

---

## C.7 Gates
- Self-clean: Stack C tests pass; `R CMD check --as-cran` no new errors/warnings;
  long examples `\donttest{}`; no large files shipped.
- Integration: produces the calibrator; triggers B-pass-2; STATE.md handshake all
  checked.
- Report: simulation API summary, headline strategy findings (first-move
  win-rates, policy ranking), **the cross-timeline-win prevalence number with an
  explicit balance verdict**, calibration quality (Brier), and confirm the B↔C
  handshake is complete.
