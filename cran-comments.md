# cran-comments

## R CMD check results

* `R CMD check --as-cran` is clean on the maintainer machine (R 4.6.0,
  macOS): 0 errors | 0 warnings | 0 notes.
* The package is also exercised by the GitHub Actions workflows
  `R-CMD-check.yaml` (macOS / Windows / Ubuntu × release + devel +
  oldrel-1) and `pkgdown.yaml`.

## Notes for the CRAN team

* New submission — first time on CRAN. (A "New submission" note is
  expected and acceptable.)
* The package ships a small fitted calibrator as internal package data
  (`R/sysdata.rda`, ~500 bytes). It is produced reproducibly by
  `data-raw/make_calibrator.R`; no external network resource is used.
* Examples that are wall-time-bound (MCTS in pure R) are guarded by
  `\donttest{}` so CHECK does not run them.
* The bundled Shiny app's launcher (`mxo_run_app()`) has all of `shiny`,
  `bslib`, `DT` in `Suggests` and surfaces a `cli` error with install
  instructions if any are missing.

## Downstream dependencies

There are currently no reverse dependencies.
