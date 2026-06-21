# multixoR — Stack D: Analysis & Visualization

> **Read first:** `multixoR_GAME_RULES.md`, `00_ORCHESTRATOR.md`, Stack A & B
> deliverables. **Blocks on Stack B = integrated.** Runs in parallel with Stack C.
> This stack makes the invisible 5D geometry visible. Every plot function returns
> a ggplot2 (or plotly) object — never renders as a side effect (suite rule).
> D consumes B's ratings/probabilities; it never re-implements scoring.

Identity: `multixoR` / `mxo_`. S3, cli, rlang, type-stable. ggplot2 + plotly.
Theming: Hugo Coder palette, suite purple `#5E2C8E` for chrome accents.

---

## D.0 Scope

- Render a single board two ways (toggle): **Z-slices** (planes side by side) and
  **rotatable 3D cube** (plotly).
- Render the **multiverse grid**: boards laid out by timeline (rows) × time
  (columns), with branch connectors.
- **Analysis overlays** (optional, modes: off / top-3 / full heatmap): move-rating
  heatmap, threatened-lines highlight, win-probability time-series.
- **Branch/timeline tree** (dendrogram of which timeline branched from which).
- An `autoplot.mxo_game` method dispatching to these.

Out of scope: Shiny wiring (that's E — E embeds these objects), evaluation logic
(B), simulation (C).

---

## D.1 Board geometry → plot coordinates (`R/mxo_viz_coords.R`)

Internal helpers turning `(L,t,idx)` into 2D/3D plot positions:
- `.mxo_slice_layout(n, d_spatial)` — for the default 4³, map each cell to a
  Z-slice panel: 4 panels (z=0..3), each a 4×4 (x,y) grid. Generic enough that
  `d_spatial != 3` degrades gracefully (document the limitation: rich slice view
  is defined for `d_spatial == 3`; for other dims, fall back to a flat
  index-grid).
- `.mxo_cube_coords(idx, n)` — (x,y,z) for the 3D plotly cube.
- `.mxo_grid_origin(L, t, ...)` — top-left offset of each board within the
  multiverse grid (timeline down, time right).
All return tidy tibbles; vapply-based; no plotting here.

---

## D.2 Single-board renderers (`R/mxo_plot_board.R`)

`mxo_plot_board(game, L, t, view = c("slices","cube"), overlay = c("none",
"top3","heatmap"), rating = NULL, highlight_lines = NULL, ...)`:

- **`view = "slices"`** → a **ggplot2** object: faceted 4×4 grids (one facet per
  z), X/O glyphs, empty cells subtle. Returns the ggplot (no print).
- **`view = "cube"`** → a **plotly** object: 3D scatter/mesh at cube coords, X and
  O as distinct markers, hover shows `(L,t,x,y,z)`. Returns the plotly.
- **`overlay`** (only meaningful for empty/candidate cells):
  - `"none"`: plain board.
  - `"top3"`: mark the 3 best legal moves into this board (from `rating`).
  - `"heatmap"`: colour every legal target cell by `score`/`win_prob` (a
    diverging scale; document the continuous-scale interpolation choice).
  - `rating` is a `mxo_rate_moves()` tibble (from B) **passed in** — D does not
    compute it. If `rating = NULL` and an overlay is requested, D may call
    `mxo_rate_moves()` once and say so, but the canonical path is injection.
- **`highlight_lines`**: a set of extents (e.g. threatened or winning lines) to
  draw as connecting segments/tubes. For winning lines on a terminal game, default
  to highlighting the win line.

Colour: Hugo Coder blue `#1565C0` for X-ish, a contrasting hue for O; purple
`#5E2C8E` reserved for chrome/highlights. Use a colourblind-safe pairing; set
`labs()` title/subtitle (timeline, time, status).

---

## D.3 Threatened-lines overlay (`R/mxo_plot_threats.R`)

`mxo_plot_threats(game, player = mxo_to_move(game), min_marks = 2, ...)` →
ggplot/plotly highlighting all existence-gated extents where `player` has
`min_marks` and the rest empty — **including cross-timeline (`dL!=0`) lines**,
which are otherwise impossible to see. This is the package's signature analytic
view (rules §12). Use B's `.mxo_line_features`/extent inventory — do not
re-enumerate independently if B exposes it; otherwise enumerate via A's geometry.
Annotate each threat with its axis-class (spatial/time/timeline/mixed).

---

## D.4 Multiverse grid (`R/mxo_plot_multiverse.R`)

`mxo_plot_multiverse(game, mode = c("overview","focus"), focus = NULL,
overlay = "none", rating = NULL, ...)` → a **ggplot2** object:
- **overview**: every board as a compact mini-tile (occupied cells as dots,
  X/O coloured), arranged timeline(row) × time(col); branch points drawn as
  connectors from `(parent_L, branch_t)` to the child board.
- **focus**: zoom to one board rendered via `mxo_plot_board` (slices), with the
  rest as context thumbnails.
- The branch connectors must make the multiverse legible — this is the 5D-chess
  "lattice of boards" look.

---

## D.5 Win-probability & evaluation curves (`R/mxo_plot_eval.R`)

`mxo_plot_win_prob(record_or_history, ...)` → ggplot line chart of win-prob over
plies (consumes B's `mxo_win_prob_curve` or a `mxo_game_record` from C). Mark
swings/blunders (large win-prob drops) per the `label` from `mxo_rate_moves`.
`mxo_plot_eval(record, ...)` → companion heuristic-score curve.

`mxo_plot_opening(opening_table, ...)` → heatmap of first-move win-rates over the
spatial cube (consumes C's `mxo_opening_table`), rendered as Z-slices.

All return ggplot objects; type-stable; `labs()` always set; theme via a shared
`.mxo_theme()` helper (theme_minimal base + Hugo Coder accents).

---

## D.6 Branch/timeline tree (`R/mxo_plot_tree.R`)

`mxo_plot_tree(game, ...)` → ggplot dendrogram of timelines: nodes = timelines,
edges = parent→child at `branch_t`, x-position ~ branch time, colour by which
player created the branch. Helps users reason about the multiverse structure.
Use `ggraph`/`tidygraph` only if you judge the dependency worth it; otherwise a
hand-rolled segment layout in ggplot (prefer the lighter option — suite hygiene).

---

## D.7 autoplot + dispatch (`R/mxo_autoplot.R`)

```
#' @importFrom ggplot2 autoplot
#' @export
autoplot.mxo_game(object, type = c("multiverse","board","threats","tree"), ...)
```
Switch to the right renderer. Document that `type = "board"` needs `L`,`t`.
Also `autoplot.mxo_sim_result` (→ outcome summaries) and
`autoplot.mxo_game_record` (→ win-prob curve) for ergonomic exploration.

---

## D.8 Tests (`tests/testthat/`)
`test-viz-coords.R`, `test-plot-board.R`, `test-plot-multiverse.R`,
`test-plot-eval.R`, `test-plot-tree.R`, `test-autoplot.R`. Cover:
- every plot fn returns the declared class (`ggplot` or `plotly`), not NULL, and
  does not print as a side effect (`expect_s3_class`; check no device opened).
- coordinate helpers: idx→(x,y,z) round-trip; slice layout covers all 64 cells;
  grid origins unique per `(L,t)`.
- overlays: `top3` marks exactly 3 cells (or fewer if <3 legal); `heatmap`
  colours all legal targets; passing a `rating` tibble is honoured (injection
  path) and no scoring is recomputed when provided (assert via a stub/spy or by
  checking it accepts an arbitrary consistent tibble).
- threats: a constructed cross-timeline 2-line is detected and flagged
  `axis_class == "timeline"`.
- autoplot dispatch returns correct types per `type`.
- robustness: empty game (only L0,t0 empty) renders without error; terminal game
  highlights the win line.
- Use `vdiffr` **only** if already acceptable; otherwise structural assertions on
  plot data (`ggplot2::ggplot_build(p)$data`) rather than pixel snapshots
  (portability — avoid the floating-point snapshot issues noted in suite
  learnings).

---

## D.9 Dependencies
Add to `Imports`: `ggplot2`, `plotly`, `scales` (if used). **`plotly` is a core
dependency** (not Suggests) — the rotatable 3D cube is a first-class view, so no
`requireNamespace` guards are needed around the cube path; call `plotly::` freely.
`ggraph`/`tidygraph` only if used for the tree (else omit, prefer a hand-rolled
ggplot segment layout — suite hygiene).

---

## D.10 Gates
- Self-clean: Stack D tests pass; `R CMD check --as-cran` no new errors/warnings;
  plot examples fast or `\donttest{}`; no plotly example runs in CHECK
  (`\donttest{}` / `interactive()`).
- Integration: renders real games produced by A/B/C without error; overlays
  consume B's `mxo_rate_moves` output unchanged.
- STATE.md: D → `integrated`.
- Report: renderers delivered, slices/cube toggle status, overlay modes, the
  threatened-lines cross-timeline view confirmation, and confirm E is unblocked
  once C is also integrated.
