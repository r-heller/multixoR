# multixoR — Build Orchestrator (00)

> **Role of this file.** You are the orchestrator for building the `multixoR` R
> package: a five-dimensional, multiverse tic-tac-toe engine + analysis suite +
> Shiny app, targeting CRAN. You coordinate five work stacks (A–E), track state,
> and decide what is runnable next. You do **not** implement game logic here —
> each stack has its own prompt file. Your job is sequencing, state tracking, and
> the final integration + submission loop.

---

## 0. Canonical references (read first, every session)

1. **`multixoR_GAME_RULES.md`** — the authoritative game specification. Single
   source of truth. Every stack conforms to it. If a stack needs a rule that is
   ambiguous, the rule is clarified *in the rules doc first*, then implemented.
2. **`CLAUDE_CODE_RPACKAGE_CRAN_CHECK.md`** — the CRAN-readiness audit prompt
   (suite-standard). Stack E and the final loop invoke it.
3. **`CLAUDE_CODE_RPACKAGE_TIDYVERSE_ALIGNMENT.md`** — the tidyverse design audit.
   Run after CRAN-clean, before declaring done.
4. **`CLAUDE_CODE_CODECOV_SETUP.md`** — coverage wiring. Run in Stack E.

Package identity (do not hardcode elsewhere — this is the declaration):
- **Package:** `multixoR`
- **Prefix:** `mxo_`
- **Org/repo:** `r-heller/multixoR`
- **pkgdown:** `https://r-heller.github.io/multixoR/`
- **Author:** Raban Heller `<raban.heller@charite.de>`, ORCID `0000-0001-8006-9742`
- **License:** MIT + file LICENSE
- **S3 throughout; all plot fns return ggplot2/plotly objects; cli + rlang for
  messaging; vapply over sapply; TRUE/FALSE not T/F; no library()/require() in
  package code; no writes outside tempdir(); Rcpp-ready but pure-R for v1.0.**

---

## 1. Dependency graph

```
            ┌─────────────┐
            │  STACK A     │   Core engine & geometry
            │  Core        │   (state, moves, branch, win-check, generic n^d)
            └──────┬───────┘
                   │ (everything depends on A)
            ┌──────▼───────┐
            │  STACK B     │   Evaluation & AI
            │  Eval/AI     │   (negamax, MCTS, win-prob, move rating)
            └──────┬───────┘
          ┌────────┴────────┐
   ┌──────▼──────┐   ┌──────▼──────┐
   │  STACK C    │   │  STACK D    │
   │  Simulation │   │  Viz        │   (parallel once B is done)
   └──────┬──────┘   └──────┬──────┘
          └────────┬────────┘
            ┌───────▼───────┐
            │  STACK E      │   Shiny app + CRAN/tidyverse/codecov + submission
            │  App + Ship   │
            └───────────────┘
```

Edges:
- **A → B** : B needs the state object, legal-move generator, win-check.
- **B → C** : C's self-play needs the AI policies and `mxo_evaluate()`.
- **B → D** : D's overlays (move heatmap, win-prob curve, threatened lines) need B.
- **C ↔ B** : C produces self-play data that **calibrates** B's win-probability
  mapping. This is a feedback edge — see §4 (calibration handshake).
- **C, D → E** : the app embeds viz (D) and exposes simulation/analysis (C).
- **E → all** : final audit loop touches the whole package.

---

## 2. STATE.md — create and maintain

On first run, create `STATE.md` at repo root with this structure. Update it after
every stack milestone. This is how you (across sessions) know what's runnable.

```markdown
# multixoR — Build State

## Stacks
| Stack | Status        | Blocks on | Last updated | Notes |
|-------|---------------|-----------|--------------|-------|
| A Core      | not_started | —         |              |       |
| B Eval/AI   | not_started | A         |              |       |
| C Sim       | not_started | B         |              |       |
| D Viz       | not_started | B         |              |       |
| E App+Ship  | not_started | C, D      |              |       |

Status values: not_started | in_progress | self_clean | integrated | done
- self_clean = the stack's own tests + R CMD check pass in isolation
- integrated = plays correctly with already-integrated stacks
- done       = part of a fully CRAN-clean package

## Calibration handshake (B↔C)
- [ ] C has produced self_play_results.rds (≥ N games)
- [ ] B has fitted the win-prob calibration curve from C's data
- [ ] B's mxo_win_prob() uses the fitted curve (not the placeholder logistic)

## Runnable set (recompute each session)
[list of stacks whose blockers are all `integrated` or `done`]

## Open rule clarifications
[anything that required amending multixoR_GAME_RULES.md, with date]

## Known issues / deferred
[carry-forward list]
```

### Runnable-set rule
A stack is **runnable** iff every stack it blocks on is at status `integrated` or
`done`. At the start of each session: read STATE.md, recompute the runnable set,
work the lowest-letter runnable stack first (A before B before C/D before E),
unless the user directs otherwise. C and D are both runnable once B is
`integrated` — they may proceed in parallel.

---

## 3. Per-stack execution protocol

For each stack, in order:

1. **Read** `multixoR_GAME_RULES.md` + the stack's own prompt file + `STATE.md`.
2. **Implement** per the stack prompt. Commit + push per the git policy in §6b
   (auto-push to `main` after each completed step, authorship under Raban).
3. **Self-clean gate:** the stack's own tests pass; `devtools::document()` clean;
   `devtools::check(args = c("--as-cran","--no-manual"))` has **no new** errors or
   warnings introduced by this stack. Mark `self_clean` in STATE.md.
4. **Integration gate:** load the package with all prior stacks; run the
   cross-stack tests named in the stack prompt; confirm no regressions. Mark
   `integrated`.
5. **Update STATE.md** (status, date, notes, known issues).
6. **Report** a short stack summary (what was built, test counts, any rule
   clarifications, what's now runnable).

Never advance a stack to `integrated` while its blockers are not `integrated`.

---

## 4. The calibration handshake (B ↔ C) — special sequencing

Because win-probability quality depends on self-play data, B ships **twice**:

- **B-pass-1 (before C):** implement evaluation, negamax, MCTS, and move rating.
  `mxo_win_prob()` uses a **placeholder** logistic mapping of the heuristic score
  (documented as provisional). Mark B `integrated` so C and D can proceed.
- **C runs:** produces `inst/extdata/` or `data-raw/` self-play results (small,
  committed-as-rda where size allows; large raw kept in `data-raw/`, gitignored).
- **B-pass-2 (after C):** fit the calibration curve from C's self-play outcomes,
  replace the placeholder in `mxo_win_prob()`, add a regression test pinning the
  fitted curve's behaviour. Update the handshake checklist in STATE.md.

D does not block on B-pass-2; it consumes whatever `mxo_win_prob()` returns.

---

## 5. Final integration & submission loop (after E)

```
REPEAT:
  1. devtools::document()
  2. devtools::test()              # all stacks
  3. Run CLAUDE_CODE_RPACKAGE_CRAN_CHECK.md end-to-end
  4. IF errors>0 OR warnings>0 → fix, GOTO 1
  5. Run CLAUDE_CODE_RPACKAGE_TIDYVERSE_ALIGNMENT.md → fix design debt, GOTO 1
  6. Run CLAUDE_CODE_CODECOV_SETUP.md (wire coverage)
  7. pkgdown::build_site() clean
  8. notes: fix or document each in cran-comments.md
  9. DONE when: 0 errors | 0 warnings | only-acceptable notes, design audit clean,
     pkgdown builds, app launches.
```

Submission readiness is the only definition of done.

---

## 6. Cross-cutting invariants (enforce in every stack)

- Conformance to `multixoR_GAME_RULES.md` §11 invariants checklist.
- Generic geometry: engine parameterised by `(n, d_spatial, k)`; 4/3/3 is the
  configured default, never a hardcoded constant in logic.
- Single source of truth: app, simulation, and analysis all call the **same**
  `mxo_evaluate()` / `mxo_win_prob()` — no parallel re-implementations.
- Rcpp-ready: isolate hot loops (win-check, MCTS rollout, legal-move gen) into
  small pure functions with no R-only sugar in the inner loop, so a future Rcpp
  backend is a drop-in. Do not add Rcpp in v1.0.
- Every exported `mxo_*` function: full roxygen (`@param`, `@return` with type,
  `@examples`), type-stable return, cli error handling with `call`.

---

## 6b. Git policy — auto-push to main, authorship under Raban (multixoR ONLY)

> **Scope note.** This overrides the suite-wide "branch-only, no push without
> approval" rule **for this repository only**. multixoR is a solo project and the
> user has explicitly opted into automatic pushes to `main`. Do not apply this
> auto-push behaviour to any other suite package.

### 6b.1 Commit + push after every completed step
A "completed step" = a stack reaching `integrated` (and the final loop reaching
`done`). After each such milestone:
1. `devtools::document()` + `devtools::test()` must be green and
   `R CMD check --as-cran` must have introduced no new errors/warnings for that
   step (the self-clean/integration gates in §3). **Never push a red state.**
2. Stage the files changed by that step, write a clear commit message, commit, and
   `git push origin main`.
3. Update `STATE.md`, commit it in the same push.
4. If the push fails (e.g. non-fast-forward), `git pull --rebase origin main`,
   re-run the test/check gate, then push again. **Never `--force`.**

Commit message convention (no AI authorship — see 6b.2):
```
Stack A: core engine & geometry (S3 state, moves, branch, win-check)

- generic n^d geometry, 121 canonical directions for default config
- mxo_game S3 + legal moves + present/branch moves + undo/replay
- incremental cross-axis win detection; tests green; R CMD check clean
```

### 6b.2 Authorship — everything under Raban, never Claude Code
Every commit MUST be authored by Raban Heller. Before the first commit, verify
git identity is set (these are the user's to confirm locally; if unset, STOP and
ask the user to set them — do not invent values):
```
git config user.name  "Raban Heller"
git config user.email "raban.heller@charite.de"
```
Hard rules:
- **No** `Co-Authored-By: Claude ...` trailer in any commit message.
- **No** "🤖 Generated with Claude Code" / "Co-authored-by: Claude Code" line.
- **No** AI authorship anywhere in commit metadata, code comments, DESCRIPTION,
  NEWS, or docs. Package `Authors@R` = Raban Heller (aut, cre) only.
- If any scaffolding tool injects an AI co-author or "generated by" trailer,
  strip it before committing.
- Do not include these instructions or the assistant's involvement in commit
  messages.

### 6b.3 One-time repo preconditions (confirm before Stack A's first push)
- `git remote -v` shows the correct `r-heller/multixoR` origin.
- `main` exists and is the default branch.
- `git config user.name`/`user.email` resolve to Raban (6b.2).
If any precondition is unmet, STOP and surface it to the user rather than guessing.

---

## 7. First action

If `STATE.md` does not exist → create it (§2), set Stack A `in_progress`, and
begin Stack A using `STACK_A_CORE.md`. Otherwise read `STATE.md`, recompute the
runnable set, and continue.
