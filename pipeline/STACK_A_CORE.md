# multixoR — Stack A: Core Engine & Geometry

> **Read first:** `multixoR_GAME_RULES.md` (authoritative) and `00_ORCHESTRATOR.md`.
> This stack is the foundation; every other stack depends on it. Build it to be
> correct, generic, type-stable, and Rcpp-ready. No AI, no plotting, no Shiny here.

Package identity: `multixoR` / prefix `mxo_` / `r-heller/multixoR`. All identity
from DESCRIPTION at runtime; the values here are the declaration to write into
DESCRIPTION.

---

## A.0 Scope

Stack A delivers the playable rules engine:
- the generic 5D lattice geometry (`n^d_spatial` + time + timeline),
- the `mxo_game` S3 state object (constructor / validator / helper),
- legal-move generation (present + branch),
- move application (present move, branch move) with immutable history,
- win detection across all five axes,
- undo/replay,
- printing and basic accessors.

Out of scope for A: evaluation, AI, simulation, visualization, Shiny. Those are
B–E.

---

## A.1 Geometry module (`R/mxo_geometry.R`) — generic, the hard part

Implement geometry parameterised by `n` (spatial side, default 4), `d_spatial`
(default 3), and `k` (run length, default 3). Time and timeline are two always-
present extra axes. Per the rules doc §5.

### A.1.1 Cell addressing
- Spatial linear index: `idx = sum_{a=0}^{d_spatial-1} coord[a] * n^a`, range
  `0 .. n^d_spatial - 1`. For defaults: `idx = x + 4*y + 16*z`, 0..63.
- Full address is `(L, t, idx)` where `idx` decodes to spatial coords.
- Provide `.mxo_idx_to_coord(idx, n, d_spatial)` and
  `.mxo_coord_to_idx(coord, n, d_spatial)` (internal, vectorised, vapply-based).

### A.1.2 Direction enumeration
- Total axes for line directions = `d_spatial + 2` (spatial + time + timeline).
- A direction is a vector in `{-1,0,+1}^(d_spatial+2)`, not all zero,
  canonicalised so the **first non-zero component is positive** (rules §5.1).
- Number of canonical directions = `(3^(d_spatial+2) - 1) / 2`. For defaults
  (5 axes): `121`. **Write a test asserting exactly 121** for the default config,
  and the general formula for a couple of other `(n,d_spatial)` settings.
- Order the components as `(dL, dt, d_spatial_0, ..., d_spatial_{d-1})` so the
  timeline and time axes are explicit and first.

### A.1.3 Win-line semantics (CRITICAL — read rules §5.2)
A length-`k` line from start cell `c=(L,t,idx)` in direction `d` is the set
`{c, c+d, ..., c+(k-1)d}` where stepping means:
- spatial components: move within the board (must stay in `0..n-1` per axis),
- `dt`: same `idx`, time `t±1`, **same timeline**,
- `dL`: same `idx`, same `t`, timeline label `L±1` (integer-label adjacency).

A line is a **winning line** iff **all k cells exist on real boards** AND are
occupied by the **same** player. **Board existence is mandatory**: if any cell of
the extent lands on a `(L,t)` board not present in the multiverse, that extent is
simply not a candidate (not a loss, not a win — absent). Implement
`.mxo_extent_exists(multiverse, cells)` and use it as a gate before colour-check.

> Do **not** precompute a fixed global line list the way static 4^d TTT does — the
> set of valid lines changes as boards are created/branched. Instead, win-check is
> **incremental and local**: after a placement at cell `c`, only lines passing
> through `c` can newly complete. Enumerate the `O(directions * k)` candidate
> extents through `c`, gate by existence, then check colour. This is both correct
> for the dynamic multiverse and the Rcpp-ready hot path.

---

## A.2 State object (`R/mxo_game.R`) — S3 constructor/validator/helper

Follow the Advanced-R tri-function pattern (rules §7 is informative; this is the
normative contract).

### A.2.1 Low-level constructor (internal)
```
new_mxo_game(boards, timelines, to_move, history, status, config)
```
- `config`: list(`n`, `d_spatial`, `k`, `ply_cap`, `max_timelines`).
- `boards`: keyed store `(L,t) -> integer vector length n^d_spatial`
  (0 empty, 1 X, 2 O). Use a named-list or environment keyed by a string
  `"L:t"`. Choose a structure with O(1) lookup; document the key format.
- `timelines`: per-`L` metadata: `parent` (L or NA for L0), `branch_t`
  (t at which it split, NA for L0), `present_t` (max t in this L).
- `to_move`: 1L (X) or 2L (O).
- `history`: ordered list of ply records (see A.3.3).
- `status`: one of `"in_progress"`, `"x_win"`, `"o_win"`, `"draw"`; plus, when
  terminal, `win_line` (the cells) and `winner`.
- `class = "mxo_game"`. `stopifnot` only — no user-facing messages here.

### A.2.2 Validator (internal, exported only if users build states manually)
`validate_mxo_game(x)` checks the rules-doc §11 invariants that are statically
checkable: unique increasing L labels; no occupied cell mismatch on replay;
to_move parity vs history length; boards within size; etc. Use `cli::cli_abort`
with `call`.

### A.2.3 User helper (exported)
```
mxo_new_game(n = 4, d_spatial = 3, k = 3, ply_cap = 60, max_timelines = 32)
```
Returns a fresh `mxo_game` with one empty board at `(L0,t0)`. Validate config
(positive ints, `k <= n`, etc.) with informative cli errors. This is the primary
entry point.

---

## A.3 Moves (`R/mxo_move.R`)

### A.3.1 Legal moves (exported)
`mxo_legal_moves(game)` → a **type-stable tibble**, always with these columns
even when 0 rows:
- `kind` (chr: `"present"` | `"branch"`),
- `L_src` (int), `t_src` (int), `idx` (int),
- `player` (int, = to_move).

Present moves: every empty cell of every active timeline's present board.
Branch moves: every empty cell of every **past** board (any `(L,t)` that is not
its timeline's present), subject to `max_timelines` not yet exceeded. Respect
rules §4.

### A.3.2 Apply a move (exported)
`mxo_move(game, kind, L_src, t_src, idx)` → new `mxo_game`.
- **present:** copy the present board of `L_src`, place mark, `present_t += 1`,
  record history, flip `to_move`, run incremental win-check at the placed cell.
- **branch:** require target cell empty in `(L_src,t_src)` (else cli_abort,
  "cannot overwrite history"); require `t_src < present_t(L_src)` (it must be
  past); require timeline count `< max_timelines` (else cli_abort). Create
  `L_new`, seed it at `t_src` with the source board + new mark, set its metadata
  (`parent=L_src`, `branch_t=t_src`, `present_t=t_src`), record history, flip
  `to_move`, incremental win-check.
- After any move: if a win line completed → set status `x_win`/`o_win` + winline.
  Else if `length(history) >= ply_cap` → status `draw`. Else `in_progress`.
- **Immutability:** never mutate an existing board in `boards`; always write new
  keys. The source timeline of a branch is untouched (assert in tests).

Provide a convenience: `mxo_play(game, ...)` that accepts a single row of
`mxo_legal_moves()` output, for ergonomic piping.

### A.3.3 History & undo (exported)
- Each ply record: `list(player, kind, L_src, t_src, idx, L_new = NA|int, t_new)`.
- `mxo_undo(game, steps = 1)` → reconstructs state by replaying history minus the
  last `steps` plies from a fresh game. (Replay-based undo guarantees correctness
  and exercises determinism.) Type-stable: always returns an `mxo_game`.
- `mxo_replay(history, config)` (exported) rebuilds a game from a history log —
  proves full replayability (rules §11).

---

## A.4 Win detection (`R/mxo_win.R`)

- `.mxo_check_win_at(game, L, t, idx, player)` (internal hot path): enumerate
  candidate extents through the cell (A.1.3), gate by existence, colour-check,
  return the winning cells or NULL. Must be allocation-light and free of R-only
  sugar in the inner loop (Rcpp-ready).
- `mxo_status(game)` (exported) → list(`status`, `winner`, `win_line`). Type-
  stable.
- `mxo_is_terminal(game)` (exported) → logical scalar.

---

## A.5 Print / format / accessors (`R/mxo_print.R`)

- `print.mxo_game(x, ...)` via cli: show config, #timelines, #boards, to_move,
  status, ply count; a compact multiverse sketch (timelines × time grid with
  occupancy counts). `rlang::check_dots_empty()`. Return `invisible(x)`.
- `format.mxo_game` kept in sync.
- `summary.mxo_game(object, ...)` → an `mxo_game_summary` S3 object with counts
  (marks per player, lines-one-away per player, branch count) and its own print.
- Accessors (exported, type-stable): `mxo_board(game, L, t)` (integer vector),
  `mxo_timelines(game)` (tibble), `mxo_to_move(game)` (int), `mxo_config(game)`
  (list), `mxo_history(game)` (tibble).
- Predicate/coercion: `is_mxo_game(x)`; `as_tibble.mxo_game` → one row per
  occupied cell with `(L,t,x,y,z,player)` (long form, the analysis-friendly view).

---

## A.6 Notation (`R/mxo_notation.R`)
Implement the rules §8 serialization both ways:
- `mxo_format_ply(record)` → string (the `X branch @ (0,0) [42] -> L1` form).
- `mxo_parse_ply(string)` → record. Round-trip tested.

---

## A.7 Tests (`tests/testthat/`) — this stack must be heavily tested

Mirror files: `test-geometry.R`, `test-game.R`, `test-move.R`, `test-win.R`,
`test-print.R`, `test-notation.R`. Cover at minimum:

- **Geometry:** 121 directions for default; general formula for 2 other configs;
  idx↔coord round-trip; canonicalisation (no direction and its negation both
  present).
- **Win — spatial:** a 3-in-a-row within one board along x, y, z, face-diagonal,
  space-diagonal all detected; `k`-sensitivity (k=3 needs exactly 3).
- **Win — time axis:** same idx, X on `(L0,t0),(L0,t1),(L0,t2)` → win along `dt`
  (construct via present moves).
- **Win — timeline axis:** X aligned at same `(t,idx)` on `L0,L1,L2` → win along
  `dL`. **This is the cross-timeline tactic from rules §12 — test it explicitly.**
- **Win — mixed diagonal:** at least one extent combining `dL` and a spatial step.
- **Existence gating:** an extent that would win but passes through a non-existent
  board is NOT a win.
- **Branch invariants:** branching never mutates the source timeline (snapshot the
  source board before/after); branching into an occupied past cell errors;
  branching a present (non-past) board errors; exceeding `max_timelines` errors.
- **Immutability:** no board key is ever rewritten (track keys before/after).
- **Caps:** reaching `ply_cap` ⇒ `draw`.
- **Undo/replay:** `mxo_undo` then re-apply reproduces state; `mxo_replay` from
  history equals the original game (deep-equal on boards + status).
- **Type stability:** `mxo_legal_moves` on a terminal game → 0-row tibble with the
  correct columns; accessors return declared types on empty inputs.
- **Errors:** snapshot tests (`expect_snapshot(..., error = TRUE)`) for the main
  illegal-move messages.

Add `tests/testthat/helper.R` with builders: `small_game()` (e.g. n=3,k=3 to keep
fixtures tiny) and helpers to force specific positions deterministically.

---

## A.8 DESCRIPTION / infra for this stack
- Create/populate `DESCRIPTION` with identity (§A.0), `Imports: tibble, rlang,
  cli, vctrs (if needed), stats, utils`; `Suggests: testthat (>=3.0.0), withr,
  knitr, rmarkdown, covr`. No Bioconductor deps. No `LazyData` unless `data/`
  exists.
- `R/multixoR-package.R` with `"_PACKAGE"` and `#' @importFrom rlang .data %||%`.
- `Config/testthat/edition: 3`.
- `devtools::document()` clean; `devtools::check(args=c("--as-cran","--no-manual"))`
  introduces no errors/warnings.

---

## A.9 Self-clean gate (definition of done for Stack A)
- All Stack A tests pass.
- `R CMD check --as-cran`: 0 new errors, 0 new warnings (a "New submission" note
  is fine at this stage).
- Update `STATE.md`: Stack A → `self_clean`, then `integrated` (A has no blockers).
- Report: functions delivered, test counts, the 121-direction confirmation, any
  rule clarifications that required touching `multixoR_GAME_RULES.md`, and confirm
  B/C/D are now unblocked (B runnable).
