# Maintenance review — 30 October 2026

## Purpose and acceptance criteria

Retain the multiverse tic-tac-toe rules, branching history and plotting/app
interfaces while making bounded search controls effective. Essential criteria
are legal selected moves, reproducible fixed-work searches, meaningful ratings,
controlled invalid-input errors and a checked installable package.

## Evidence and changes

- High: `mxo_ai_move()` ignored `...`, so requested iterations/depth/budgets
  never reached the engine. Named overrides now reach their selected method,
  including `time_budget = NULL`; duplicate/positional overrides fail clearly.
- High: the MCTS clock was checked only between whole rollouts. Checks now run
  through tree traversal and rollout operations. Hard difficulty defaults to a
  cooperative two-second budget. This is not a preemptive timeout: one expensive
  operation can overrun it. Fixed-iteration behavior remains available explicitly.
- Medium: MCTS move ratings performed an expensive heuristic search at each
  rollout ply. The default now uses random rollouts; heuristic rollouts remain
  selectable. No claim of improved playing strength is made.
- Medium: search ratings calculated negamax scores but ranked unrelated heuristic
  probabilities. Search ranks now use negamax scores; unsupported probability
  labels are `NA`. Heuristic/MCTS labels retain their existing meanings.
- Medium: search depths could be truncated to integers; validate before conversion.
- Low: repeated isotonic knots caused interpolation warnings, and constant-score
  fits lacked a defined interpolation path. Store distinct fitted knots and
  return the constant fit where applicable, preserving missing predictions.

- High: the Shiny app displayed human-play modes but had no human-move handler.
  Added legal-move selection with stable move keys, explicit play, a human-X/AI-O
  reply, and step-by-step AI play. Stale selections are refused. The requested
  initial difficulty now reaches the UI; board rendering no longer depends on
  an unavailable infix helper, and startup checks its plotly dependency.

## Validation

The baseline source suite exceeded its 600-second limit. The first repaired full
suite passed in 239.35 seconds, with one isotonic warning subsequently repaired.
The calibration regression suite passed. A complete built-package check with
vignettes/examples/tests passed before the final rating-rank change. The final
search regression suite passed after correcting its history-list fixture.
An actual hard move returned a legal move in 2.137 seconds; two fixed-work seeded
runs matched exactly. The final `R CMD check --no-manual --no-tests` returned Status OK, including
rebuilt vignettes and examples. A fresh installation outside the checkout passed
bounded AI selection, applying its legal move, undo and search-score ranking.
The final check runs the package examples; the full source/packaged tests and
final targeted search/calibration tests were run separately. One intermediate
regression fixture accessed a history list as a data frame; that fixture was
corrected and the final focused suite passed.

## First use

Install the Imports from `DESCRIPTION` and run `R CMD INSTALL .`. In a new R:

```r
library(multixoR)
g <- mxo_new_game(n = 3L, k = 3L)
m <- mxo_ai_move(g, "hard", seed = 1L)
g <- mxo_move(g, m$kind, m$L_src, m$t_src, m$idx)
ggplot2::autoplot(g)
# Optional app dependencies: shiny, bslib, DT, plotly
mxo_run_app()
```

For repeatable experiments, set `time_budget = NULL` and explicit bounded
iterations/depth. Timed searches can perform different work on different CPUs.

## Roadmap and boundaries

This milestone repairs control and interpretation failures without changing the
rules or replacing the engine. Next: profile representative branching positions
and validate calibration on held-out configurations before stronger performance
or probability claims. Compiled search and new game variants remain deferred.
Remote CI, Windows/Linux and CRAN are not verified for this candidate. After
review, push through the existing platform matrix and inspect its exact results;
no submission or deployment has occurred.

Final app verification: seven server assertions cover human play, stale move
refusal, undo, reset, automatic replies and AI stepping. An installed Chromium
journey confirmed initial hard difficulty, human+AI turns, undo/reset, an AI step,
Board and Analysis tabs without page errors. The final app source archive passed `R CMD check --no-manual --no-tests`
with Status OK, including examples and rebuilt vignettes (75.34-second build,
86.4-second check). Source tests and the final app regressions ran separately.
