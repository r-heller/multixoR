# multixoR — Stack E: Shiny App + Submission

> **Read first:** `multixoR_GAME_RULES.md`, `00_ORCHESTRATOR.md`, and Stacks A–D.
> **Blocks on Stack C AND Stack D = integrated.** This stack builds the interactive
> app and then drives the package to submission-ready via the suite audit prompts.
> The app embeds D's plot objects and B's ratings/probabilities; it implements no
> game logic or scoring of its own.

Identity: `multixoR` / `mxo_` / `r-heller/multixoR`. Shiny + bslib, plotly click
events, Hugo Coder theme, suite purple `#5E2C8E` chrome. No `library()` anywhere
in app files — namespace-qualify everything (CRAN rule).

---

## E.0 Scope

1. The Shiny app under `inst/shiny/multixoR/`.
2. The launcher `mxo_run_app()` in `R/`.
3. Example data helpers for the app/docs.
4. Vignettes, README, pkgdown.
5. The **final submission loop**: CRAN check → tidyverse alignment → codecov →
   pkgdown → done (orchestrator §5).

---

## E.1 Launcher (`R/mxo_run_app.R`)
`mxo_run_app(game = NULL, difficulty = "medium", ...)`:
- exported; full roxygen; `@return` = "Invisible `NULL`. Launches a Shiny app."
- `@examples` wrapped in `\donttest{}` (never runs in CHECK).
- calls `shiny::runApp(system.file("shiny","multixoR", package = "multixoR"))`.
- `plotly` is already in `Imports` (Stack D — core 3D cube view). The remaining
  app-only deps `shiny`, `bslib`, `DT` → `Suggests`, with a `requireNamespace`
  check at the top of `mxo_run_app` that errors via `cli` with install
  instructions if one is missing. (Shiny/bslib/DT are app-only and don't belong in
  `Imports` for a package whose core is the engine; `plotly` stays in `Imports`
  because the viz layer uses it outside the app too.)

---

## E.2 App structure (`inst/shiny/multixoR/`)

```
app.R                      # assembles ui + server; no library() calls
modules/
  mod_board.R              # the multiverse + board view (plotly + slices toggle)
  mod_controls.R           # new game, undo, mode, difficulty, branch action
  mod_status.R             # to-move, ply, timeline count, status, win banner
  mod_analysis.R           # win-prob gauge + curve, move rating table/overlay
  mod_tree.R               # timeline/branch tree inspector
  mod_simulate.R           # (optional) run a small self-play sim + show summary
www/
  custom.css               # Hugo Coder palette + #5E2C8E accents
  logo.png                 # from man/figures/logo.png
```

Rules for all module files:
- `ns <- shiny::NS(id)` for ids; `<<-` only inside reactives/observers.
- every `renderPlotly`/`renderPlot`/`renderDT` wrapped in `tryCatch`/`req`.
- cross-module state via a single `shiny::reactiveValues(game = ...)`.
- no CDN/internet assets; system fonts.

---

## E.3 Interaction design

- **Board view (mod_board):** primary = plotly (per Raban's engine choice for
  click events). A **view toggle** switches each board between Z-slices (ggplot
  via `ggplotly` or a plotly slice layout) and the rotatable 3D cube. A
  **multiverse/focus toggle** switches between the whole lattice and a single
  focused board. Clicking an empty cell triggers a move:
  - present move if the clicked board is a timeline's present,
  - branch move (→ new timeline) if the clicked board is a past board,
  - illegal clicks (occupied / over cap) → a cli-style toast, no state change.
  Use `plotly::event_data("plotly_click")` to capture the cell; map back to
  `(L,t,idx)` via D's coordinate helpers.

- **Overlay control (mod_controls):** off / Top-3 / full heatmap (Raban's
  optional-overlay decision). When on, fetch `mxo_rate_moves(game)` **once** per
  position and pass the tibble into `mxo_plot_board(..., rating=)` — single eval,
  reused by board + table.

- **Real-time analysis (mod_analysis):**
  - a **win-probability gauge** for the player to move (`mxo_win_prob`, MCTS),
  - the **win-prob curve** over the game so far (`mxo_plot_win_prob`),
  - a **move-rating table** (`DT`) with score/win_prob/label, click-to-preview.
  - Because MCTS is the slow path, compute win-prob/ratings **asynchronously**
    (`shiny::ExtendedTask` / `promises`+`future` if a sensible dep, else a
    debounced reactive with a clear "computing…" state and a small default MCTS
    budget). Expose the MCTS budget as a control. Document the latency ceiling
    (rules §9). Cache by state hash to avoid recompute on view toggles.

- **Modes (mod_controls):** Human vs Human, Human vs AI (choose colour),
  AI vs AI (step/auto-play). Difficulty maps to B's `mxo_ai_move` levels.

- **Undo / New game:** via `mxo_undo` / `mxo_new_game`. Undo is replay-based and
  always legal.

- **Tree inspector (mod_tree):** `mxo_plot_tree(game)` — see the multiverse's
  branch structure; click a timeline to focus it on the board view.

---

## E.4 Example data & helpers
- `mxo_example_game()` (exported) → a short pre-played game (a handful of plies,
  including one branch and one near-threat) for docs, the app's default state, and
  vignettes. Deterministic (seeded). Small.
- Keep any shipped data tiny (CRAN size limits).

---

## E.5 Vignettes (`vignettes/`)
1. `multixoR.Rmd` — "Getting started": rules in brief, make a game, play moves,
   branch once, detect a win, launch the app. 5-minute end-to-end.
2. `rules-and-geometry.Rmd` — the 5D model, win lines across time/timeline,
   the cross-timeline tactic, with slice/multiverse figures.
3. `analysis.Rmd` — evaluation, win-prob, move rating, reading the overlays.
4. `simulation.Rmd` — self-play, policy tournament, opening table, the
   cross-timeline-win balance finding from Stack C.
All: `eval` guarded where a `Suggests`-only package (plotly) is needed; figures
in-vignette; build < 60s each (small MCTS budgets); use `mxo_example_game()`.

---

## E.6 README & pkgdown
- README with logo, badges (R-CMD-check, pkgdown, CRAN status, codecov,
  downloads, license MIT, lifecycle experimental — via the codecov prompt's badge
  cluster), a quick example, and an app screenshot/GIF.
- `_pkgdown.yml`: `url: https://r-heller.github.io/multixoR/`; reference grouped:
  **Game** (new_game, move, legal_moves, undo, replay, status, accessors),
  **AI & Evaluation** (evaluate, search, mcts, win_prob, rate_moves, ai_move),
  **Simulation** (policy, self_play, simulate, opening_table, tournament,
  calibration), **Visualization** (plot_board, plot_multiverse, plot_threats,
  plot_win_prob, plot_tree, autoplot), **App & Data** (run_app, example_game).
  Hugo Coder / purple-accented theme. Every export appears once.

---

## E.7 The submission loop (orchestrator §5 — run to completion)

```
REPEAT:
  1. devtools::document()
  2. devtools::test()                       # all stacks A–E
  3. Execute CLAUDE_CODE_RPACKAGE_CRAN_CHECK.md fully against multixoR
     (it reads identity from DESCRIPTION; substitute PKGNAME=multixoR, mxo_, etc.)
  4. IF errors>0 OR warnings>0 → fix → GOTO 1
  5. Execute CLAUDE_CODE_RPACKAGE_TIDYVERSE_ALIGNMENT.md → fix design debt → GOTO 1
  6. Execute CLAUDE_CODE_CODECOV_SETUP.md (workflow, codecov.yml, badges, covr)
  7. pkgdown::build_site() must be clean
  8. For each remaining NOTE: fix, or justify in cran-comments.md
  9. DONE when: 0 errors | 0 warnings | only acceptable notes,
     tidyverse audit clean, pkgdown builds, mxo_run_app() launches locally.
```

Also create the CI workflows (R-CMD-check across the OS/R matrix, pkgdown,
test-coverage) per the suite templates; branch names match the repo default.
Commit + push per the orchestrator §6b git policy (auto-push to `main` after the
final loop reaches `done`; authorship under Raban, never Claude Code).

---

## E.8 Tests
- `test-run-app.R`: `mxo_run_app` errors cleanly when a `Suggests` app dep is
  absent (simulate via `with_mocked_bindings`/`requireNamespace` stub); app files
  source without error (`source(..., local=TRUE)`); modules load.
- `test-example.R`: `mxo_example_game()` is type-stable, reproducible, contains a
  branch.
- A smoke test that the app's click→move mapping helper turns a plotly point back
  into a legal `(L,t,idx)` and that an occupied/over-cap click is rejected.
- Shiny logic deeper tests via `shinytest2` are optional and `skip_on_cran()`.

---

## E.9 Final report
Print the orchestrator §5 / CRAN-prompt final report: R CMD check result, test
counts, tarball size, coverage, the app feature list, the cross-timeline-win
balance verdict (carried from Stack C), known performance ceilings (MCTS in pure
R), and confirm submission-readiness. Update STATE.md: all stacks `done`.
