## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'R. Heller <raban.heller@uni-ulm.de>'
  New submission

  This is the first submission of multixoR to CRAN.

## Test environments

* local: macOS (aarch64), R 4.6.1, `R CMD check --as-cran` on the
  `multixoR_0.2.1.tar.gz` source archive, including PDF and HTML manuals
  (TinyTeX / TeX Live 2026 and HTML Tidy 5.8.0).
* Local test suite: 797 assertions passed; 20 tests deliberately skipped in
  CRAN mode. Focused player-validation checks also verified unchanged
  fixed-work MCTS, heuristic and evaluator results for valid players.
* Configured GitHub Actions matrix (r-lib/actions v2; hosted results for this
  candidate are pending):
  * macos-latest (R release)
  * windows-latest (R release)
  * ubuntu-latest (R devel, R release, R oldrel-1)

## Notes for the reviewer

* The package ships a small fitted calibrator as internal package data
  (`R/sysdata.rda`, about 500 bytes). It is produced reproducibly by
  `data-raw/make_calibrator.R`; no external network resource is used.
* The AI (heuristic search and Monte Carlo tree search) is pure R. Examples
  use small search budgets and finish in about a second each; the slowest
  tests are skipped on CRAN.
* The bundled Shiny app's launcher (`mxo_run_app()`) needs 'shiny', 'bslib'
  and 'DT' from Suggests and raises an informative error if any is missing;
  its example runs only in interactive sessions.

## Downstream dependencies

There are currently no reverse dependencies.

## This is a new submission.
