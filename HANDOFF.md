# multixoR — Build Handoff

> Snapshot for resuming work in a future session. Read this first, then
> `STATE.md` for the stack-by-stack ledger and
> `pipeline/00_ORCHESTRATOR.md` for the original build orchestrator.

Last touched: 2026-06-21.

## Where we are

All five stacks (A–E) are committed and pushed to `origin/main`. The
package builds, all tests pass, `R CMD check --as-cran` is essentially
clean with one final tweak applied this session (see below). The pkgdown
site, codecov upload, and the R-CMD-check matrix all run as GitHub
Actions on every push.

### Repo state at handoff

    Local branch:    main
    Remote:          git@github.com:r-heller/multixoR.git
    Last push:       9433721 (STATE.md update)
    Working changes: ONE staged-but-not-committed fix to .Rbuildignore
                     (drops duplicate entries, adds ^codecov\.yml$,
                     stops .Rbuildignore-ing README.md so it ships
                     with the tarball)

### CI / pages status

- GitHub Actions: `pkgdown.yaml`, `R-CMD-check.yaml`,
  `test-coverage.yaml` all wired up and green on prior commits.
- GitHub Pages: the `gh-pages` branch is populated by pkgdown but the
  Pages **source dropdown** is not pointed at it — see the immediate
  next step below.

## Immediate next steps (in order)

1.  **Activate Pages source.** Open
    <https://github.com/r-heller/multixoR/settings/pages> and set *Build
    and deployment → Source = Deploy from a branch → `gh-pages` /
    `(root)`* and save. The site at
    <https://r-heller.github.io/multixoR/> will come up within a few
    minutes. The build is already there; only the serve switch is off.

2.  **Commit the `.Rbuildignore` cleanup that’s staged in the working
    tree.** During the last R CMD check we found:

    - a NOTE — *Non-standard file/directory found at top level:
      `codecov.yml`* — fixed by adding `^codecov\.yml$` to
      `.Rbuildignore`.
    - a WARNING — *Directory `inst/doc` does not exist; package
      vignettes without corresponding single PDF/HTML* — this only fires
      when check is run with `--no-build-vignettes`. With vignettes
      building (the normal path) it does not appear.

    The fix is already in `.Rbuildignore` on disk; just commit + push
    and re-run a vignette-building `R CMD check --as-cran`. Expected:
    0/0/0.

    ``` bash
    git add .Rbuildignore && \
    git commit -m "rbuildignore: ship codecov.yml outside the tarball; drop duplicates" && \
    git push origin main
    ```

3.  **Verify 0/0/0 locally** (vignette-building version takes ~10–15 min
    on this machine):

    ``` bash
    Rscript -e 'devtools::check(args = c("--as-cran","--no-manual"), quiet = TRUE)'
    ```

4.  **Inspect the pkgdown site once Pages is live.** Check that

    - the themakR template renders (purple navbar, hex logo);
    - the four vignettes (Getting started / Rules and geometry /
      Analysis / Simulation) appear under *Articles*;
    - the reference is split into Game / AI / Simulation / Visualisation
      / App & Data.

## Open items carried forward in STATE.md

- **Pure-R performance ceiling.**
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  is ~13 ms on small boards;
  `mxo_search(depth = 2, branch_policy = "promising")` is ~14 s on a
  partially-played 3³. The hot loops in
  `R/mxo_evaluate.R::.mxo_line_features` and the win checker are
  Rcpp-ready (no R-only sugar in the inner loop). A future Rcpp pass
  would unlock `mxo_ai_move(difficulty = "medium")` returning to the
  orchestrator’s *promising depth ~3* target instead of the current
  `branch_policy = "none"` deferral.

- **MCTS heuristic rollouts** call
  [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  per step and are too slow for default settings; user-facing defaults
  use random rollouts. The heuristic path is still exposed via
  `rollout = "heuristic"`.

## What I would tackle next if resuming

1.  Confirm Pages is serving (one click, then refresh URL).
2.  Run the final vignette-building `R CMD check --as-cran` and pin the
    0/0/0 result with a screenshot in `cran-comments.md` or `STATE.md`.
3.  **Optional polish before any CRAN submission:**
    - add a `NEWS.md` (1 line: “\* Initial release.”);
    - verify `urlchecker::url_check()` returns 0 once the Pages site is
      live (currently 3 URLs to the future site 404 because Pages is
      off);
    - decide whether to upload to a CRAN-style staging server
      (win-builder, R-hub) for one extra round of cross-platform
      verification.
4.  **Optional Rcpp pass** (would substantially improve the test-loop
    ergonomics, the MCTS strength, and the medium-difficulty AI). The
    inner loop to port lives in `R/mxo_evaluate.R::.mxo_line_features`
    and `R/mxo_win.R::.mxo_check_win_at` — both are deliberately
    structured for 1:1 translation.

## File / module map

| Area | Files |
|----|----|
| Core engine | `R/mxo_{geometry,game,move,win,print,notation}.R` |
| AI / evaluation | `R/mxo_{evaluate,search,mcts,win_prob,rate}.R` |
| Simulation / strategy / calibration | `R/mxo_{policy,self_play,simulate,strategy,calibration}.R` |
| Visualisation | `R/mxo_{viz_coords,plot_board,plot_threats,plot_multiverse,plot_eval,plot_tree,autoplot}.R` |
| App + helpers | `R/mxo_{run_app,example_game}.R`, `inst/shiny/multixoR/{app.R,modules/*,www/*}` |
| Docs | `vignettes/{multixoR,rules-and-geometry,analysis,simulation}.Rmd`, `_pkgdown.yml`, `README.md` |
| Build artefacts | `R/sysdata.rda` (fitted calibrator), `man/figures/logo.png`, `pkgdown/favicon/*`, `data-raw/{make_calibrator,make_logo,logo_source.svg}` |
| CI | `.github/workflows/{R-CMD-check,pkgdown,test-coverage}.yaml`, `codecov.yml`, `cran-comments.md`, `inst/WORDLIST` |

## How the orchestrator’s audit prompts mapped

The orchestrator’s §5 final loop references three suite-standard prompts
that are not in this repo (`CRAN_CHECK.md`, `TIDYVERSE_ALIGNMENT.md`,
`CODECOV_SETUP.md`). I interpreted their intent rather than executing
the prompt texts:

| Prompt | What I did | Status |
|----|----|----|
| CRAN check | `R CMD check --as-cran`, spelling, URL check, `cran-comments.md`, `inst/WORDLIST` | clean except the one `.Rbuildignore` tweak above |
| Tidyverse alignment | `vapply` over `sapply`, no `T`/`F`, no [`library()`](https://rdrr.io/r/base/library.html)/[`require()`](https://rdrr.io/r/base/library.html) in `R/`, no cross-package `:::`, lintr line-length splits | clean |
| Codecov setup | `.github/workflows/test-coverage.yaml`, `codecov.yml`, README badge | shipped |

## Resume prompt

When you come back, the simplest catch-up is: 1. read this file; 2.
apply the immediate next steps above; 3. fall back to `STATE.md` and the
per-stack `pipeline/STACK_*.md` files for deeper context.
