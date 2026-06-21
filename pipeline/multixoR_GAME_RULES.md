# multixoR — Game Rules Specification (v1.0)

> **Status:** Authoritative. This document is the single source of truth for the
> game mechanics of `multixoR`. Every code-generation prompt (Stacks A–E) and
> every implementation decision MUST conform to this specification. Where an
> implementation detail is ambiguous, this document — not the implementer's
> intuition — is the tiebreaker. If a rule here turns out to be unimplementable
> or contradictory, the rule is amended *here first*, then the code follows.

---

## 0. One-paragraph summary

`multixoR` is a five-dimensional, multiverse variant of tic-tac-toe. Two
players, **X** and **O** (either may be a human or an AI), place marks on a
**4×4×4 spatial cube**. Beyond the three spatial axes, play extends across a
**time axis** (successive board states) and a **timeline axis** (parallel,
branching universes). A player wins by completing a straight line of **3 marks
of their own colour** along *any* axis or diagonal — including lines that run
through time and across timelines. A player may place a mark into an empty cell
of a *past* board state; doing so spawns a **new branching timeline** from that
point, leaving the original timeline untouched. Branching is unrestricted (no
activation limits).

---

## 1. The five dimensions

| # | Axis name | Symbol | Range | Nature |
|---|-----------|--------|-------|--------|
| 1 | spatial-x | `x` | 0–3 | static, fixed-size |
| 2 | spatial-y | `y` | 0–3 | static, fixed-size |
| 3 | spatial-z | `z` | 0–3 | static, fixed-size |
| 4 | time | `t` | 0–∞ | grows as the game proceeds |
| 5 | timeline | `L` | 0–∞ | grows as branches are created |

- The **spatial cube** is the set of cells `(x, y, z)` with each coordinate in
  `{0,1,2,3}` → **64 cells per board**.
- A **board** is the full spatial cube state at one `(L, t)` coordinate: which of
  the 64 cells are empty / X / O.
- The **multiverse** is the collection of all boards across all `(L, t)`.
- `t` and `L` are *unbounded in principle* but bounded in practice by game length
  and branching (see §9 Performance & Limits).

### 1.1 Canonical cell address

A single mark's full address is the 5-tuple:

```
(L, t, x, y, z)
```

- `L` — which timeline
- `t` — which time step within that timeline
- `(x, y, z)` — which spatial cell on that board

The linear spatial index within a board is:

```
idx = x + 4*y + 16*z          # 0..63
```

---

## 2. Players, marks, turn order

- Two players: **X** (first to move) and **O**.
- Either player may be controlled by a human or by the engine AI. The rules are
  identical regardless of controller.
- Marks are permanent within their board: **once placed, a mark is never moved,
  removed, or overwritten**. (This is the core TTT invariant and the reason
  branch mechanic (A) was chosen over piece-movement.)
- Players alternate: X, O, X, O, … One *ply* = one player's single placement
  (whether in the present or into the past).

---

## 3. The board and the initial state

- At game start the multiverse contains exactly **one timeline `L0`** with a
  single board at `t = 0`, fully empty (all 64 cells empty).
- "The present" of a timeline is its board at the highest `t` reached in that
  timeline.

---

## 4. Moves

There are exactly **two kinds of move**. Both are *placements* — a mark is added
to an empty cell. Nothing is ever moved or removed.

### 4.1 Present move (non-branching)

The player places their mark into an **empty cell of the present board** of an
existing, active timeline.

- This advances that timeline. **Operationally** (clarification, v1.0):
  1. The mark is written into the empty cell of the current present board
     `(L, present_t)`. That board is now historical and frozen — it carries
     the new mark.
  2. A **new board** is created at `(L, present_t + 1)` as a **copy** of the
     just-updated `(L, present_t)` board (no additional mark).
  3. `present_t[L]` becomes `present_t + 1`.
- The mark therefore appears at the placement coordinate `(L, t, idx)` where
  `t = present_t` at the moment of the play. The next ply on this timeline
  lands on the new `(L, t+1)` board.

> Implementation note: history immutability (§11) constrains *occupied → other*
> transitions only. An empty cell becoming occupied (the placement event) is a
> first transition and is allowed; thereafter the cell is frozen.

### 4.2 Past move (branching) — Mechanic (A)

The player selects a **past board** — any board at a `(L, t)` that is *not* the
present of timeline `L` — and places their mark into an **empty cell** of that
past board.

This spawns a **new timeline**:

1. Let the chosen past coordinate be `(L_src, t_src)`.
2. A new timeline `L_new` is created (next free integer label).
3. `L_new` is seeded with a board at `t_src` equal to the `(L_src, t_src)` board
   **plus** the newly placed mark.
4. The original timeline `L_src` is **completely unchanged** — its board at
   `t_src` and all later boards remain exactly as they were. "You cannot alter
   what already happened there."
5. `L_new` becomes an active, playable timeline whose present is its `t_src`
   board.

**Constraints on a past move:**

- The target cell MUST be **empty** in the chosen past board. Placing into an
  occupied cell is illegal (it would constitute overwriting history). This is the
  rule that operationalises "do not change the past."
- A past move may target any timeline, including ones created earlier in the
  game, at any `t` that is strictly historical for that timeline. A timeline's
  own present is reached via a *present* move (§4.1), not a past move.

### 4.3 Move legality (summary)

A move is legal iff:
- the target cell is empty, **and**
- the target board exists, **and**
- it is the moving player's turn, **and**
- the game is not already over (§6).

There is **no** activation/branch-count limit (free branching, per design
decision). A player may branch as often as they like, subject only to the above.

### 4.4 "The present" and multi-board turns

> **Design decision — SIMPLIFIED relative to 5D chess.** In 5D chess a player
> must move on *every* active present board to advance the global "now". For
> `multixoR` v1.0 we adopt the **single-placement ply**: a ply is exactly one
> placement on exactly one board (present or past). This keeps turn order simple
> and the game tractable. The "advance every board" rule is explicitly **out of
> scope for v1.0** and recorded as a possible future variant in §10.

---

## 5. Winning lines — geometry across all five axes

A **win** is a straight line of **k = 3** consecutive cells, all occupied by the
**same player's** marks, along any admissible direction in the 5D lattice.

### 5.1 Direction vectors

A direction is a 5-vector `d = (dL, dt, dx, dy, dz)` with each component in
`{-1, 0, +1}`, not all zero. To avoid double-counting a line and its reverse, we
canonicalise: the **first non-zero component must be positive**.

The number of canonical directions in 5D is `(3^5 − 1) / 2 = 121`.

A line of length 3 starting at cell `c = (L, t, x, y, z)` in direction `d` is:

```
c,  c + d,  c + 2d
```

all three cells must:
- **exist** (their board `(L, t')` must exist in the multiverse and the spatial
  coords must be within 0–3), **and**
- be occupied by the **same** player.

### 5.2 What "consecutive across timelines/time" means

- **Spatial step** (`dx`,`dy`,`dz`): ordinary neighbour within a board.
- **Time step** (`dt = ±1`): the spatially-identical cell on the board one time
  step earlier/later *in the same timeline*.
- **Timeline step** (`dL = ±1`): the spatially- and temporally-identical cell on
  the **adjacent timeline**. Adjacency of timelines is defined by **integer label
  order** (`L0`, `L1`, `L2`, …). A line may therefore run `L0→L1→L2` at fixed
  `(t,x,y,z)`, or diagonally combine timeline movement with time/space movement.

> **Important subtlety — board existence is required.** Because timelines branch
> at different `t` values and have different lengths, the cell `c + d` may fall on
> a `(L, t)` board that **does not exist**. If any of the three cells lies on a
> non-existent board, the line is simply not a winning line (it is not "false" —
> it is *not present*). Win detection enumerates only over cells whose full
> 3-cell extent lands on existing boards.

> **Design note on timeline adjacency.** Using integer-label order for `dL`
> adjacency is a deliberate simplification. A richer alternative ("adjacency =
> parent/child branch relationship") is recorded in §10 as a future variant. v1.0
> uses label order: `L_i` is adjacent to `L_{i±1}`.

### 5.2.1 Placement-anchored win detection (clarification, v1.0)

To resolve the implementation ambiguity surrounding propagation, v1.0 fixes the
following operational rule:

> **A winning line must pass through the cell of the most recent placement
> event.** Equivalently, after every ply the engine examines only those length-`k`
> extents that include the placement coordinate. Lines that arise *purely* via
> board copy (§4.1) without the most recent placement lying on them are not
> considered wins.

Within an extent so anchored, the existing colour check applies: all `k` cells
must exist on real boards and carry the moving player's mark under their current
board state (where a cell's value is either a placement on that board or a value
inherited via §4.1's copy semantics from the prior present).

Rationale: this preserves spatial wins on accumulating boards, makes
timeline-axis wins (`dL ≠ 0`) — which require explicit branches — the canonical
cross-axis tactic, and prevents trivial "phantom" wins from being declared
between propagation-only lines that no recent placement actually completed.

### 5.3 Generic n^d note

Although v1.0 fixes the spatial cube at 4³ and k = 3, the geometry engine MUST be
implemented **generically** for arbitrary spatial side length `n`, spatial
dimensionality `d_spatial`, and run length `k`, with time and timeline as two
additional always-present axes. The 4³/k=3 case is the *configured default*, not
a hardcoded assumption. (This satisfies the "generic n^d" design decision.)

Concretely, the win-line direction generator and the win checker take
`(n, d_spatial, k)` as parameters; the rest of the engine passes the configured
defaults.

---

## 6. End of game

The game ends when **any** of the following holds:

1. **Win:** a player completes a length-3 line (§5). That player wins
   immediately. If a single placement simultaneously completes lines for the
   mover, the mover wins (you can only complete your own lines on your own ply).
2. **Draw / exhaustion:** no legal move exists for the player to move. Because
   branching into the past is almost always available (past boards usually retain
   empty cells), true exhaustion is rare; v1.0 additionally supports an optional
   **ply cap** (§9) after which the game is declared a draw if unwon.

> Note: unlike classic TTT, "the board fills up" is not a natural terminal
> condition here, because new boards are constantly created. The ply cap is the
> practical terminal guard.

---

## 7. Game state object (informative — see Stack A for the normative S3 contract)

The canonical game state must capture the entire multiverse:

- `config`: `n` (=4), `d_spatial` (=3), `k` (=3), `ply_cap`, etc.
- `boards`: an indexable collection keyed by `(L, t)` → 64-cell vector
  (`0` empty, `1` X, `2` O).
- `timelines`: per-timeline metadata: parent timeline, branch `t`, current
  present `t`.
- `to_move`: `1` (X) or `2` (O).
- `history`: an ordered log of plies, each recording the full move (kind,
  source coord, target cell, resulting timeline) — sufficient to **replay** and
  to **undo**.
- `status`: `in_progress` | `x_win` | `o_win` | `draw`, plus the winning line(s)
  if terminal.

The normative S3 class, constructor/validator/helper tri(`new_*`,
`validate_*`, `mxo_new_game`), and accessors are defined in **Stack A**. This
section only fixes the *informational content* the state must hold.

---

## 8. Notation (for tests, vignettes, logs)

A ply is written:

```
<player> <kind> @ (L,t) [idx]            present move
<player> branch @ (L_src,t_src) [idx] -> L_new   past move
```

Examples:
```
X present @ (0,0) [21]
O present @ (0,1) [37]
X branch  @ (0,0) [42] -> L1
```

`idx` is the linear spatial index (§1.1). This notation is the canonical
serialization for snapshot tests and PGN-like game records.

---

## 9. Performance & limits (normative guards, informative budgets)

- **Ply cap (normative):** default `ply_cap = 60`. Configurable. On reaching the
  cap with no winner, status becomes `draw`. This guarantees termination.
- **Timeline cap (normative):** default `max_timelines = 32`. Attempting to branch
  beyond the cap is an illegal move (informative error via `cli`). Prevents
  unbounded multiverse blow-up.
- **MCTS / simulation budgets (informative):** real-time evaluation in the Shiny
  app uses MCTS with a configurable iteration/time budget. The pure-R engine is a
  known performance bottleneck for deep search over a branching multiverse; the
  engine core is to be written **Rcpp-ready** (hot functions isolated, no reliance
  on R-only constructs in the inner loop) so a future Rcpp backend can replace
  them 1:1. Rcpp itself is **out of scope** for the initial release, consistent
  with suite policy. This limit is documented, not worked around.

---

## 10. Explicitly out of scope for v1.0 (future variants)

Recorded so they are not silently assumed *in* scope:

1. **Multi-board turns** ("advance every active present board each turn", the true
   5D-chess present mechanic). v1.0 uses single-placement plies (§4.4).
2. **Branch activation limits** (the 5D-chess rule that caps how many timelines
   may be active relative to the opponent's branches). v1.0 uses free branching.
3. **Parent/child timeline adjacency** for `dL` (v1.0 uses integer-label order,
   §5.2).
4. **Piece-movement mechanic (B)** — transporting an existing mark through
   time/timeline. Rejected for v1.0 as non-TTT-native.
5. **Variable k or n at play time via the UI** — the engine is generic (§5.3) but
   the app exposes only the 4³/k=3 default in v1.0.
6. **Rcpp/compiled backend** — engine is Rcpp-*ready* but ships pure-R in v1.0.

---

## 11. Invariants the implementation MUST uphold (checklist for validators & tests)

- [ ] No cell is ever changed from occupied → other value (history is immutable).
- [ ] A past move never mutates the source timeline; it only creates a new one.
- [ ] A past move targets only empty cells of existing past boards.
- [ ] Branch labels are unique, monotonically increasing integers.
- [ ] Win detection only considers 3-cell extents whose every cell lies on an
      existing board.
- [ ] Win lines are single-colour and length exactly k (=3).
- [ ] Direction enumeration is canonical (first non-zero component positive); no
      line is counted twice.
- [ ] Turn order strictly alternates X, O, …; the mover can only complete their
      own colour's line.
- [ ] Reaching `ply_cap` ⇒ `draw`; exceeding `max_timelines` ⇒ illegal branch.
- [ ] The full game is replayable from `history` alone (deterministic).
- [ ] Geometry engine accepts `(n, d_spatial, k)` and is not hardcoded to 4/3/3.

---

## 12. Worked micro-example (sanity anchor for tests)

Tiny illustrative sequence (spatial detail abbreviated; assume cells chosen so a
timeline-axis line can form):

```
1. X present @ (0,0) [0]      # X at L0,t0, cell (0,0,0)
2. O present @ (0,1) [5]      # O somewhere
3. X branch  @ (0,0) [0?]     # ILLEGAL: cell 0 occupied in (0,0) -> rejected
3. X branch  @ (0,0) [1] -> L1  # X adds a 2nd mark into the PAST board (0,0); spawns L1
4. O present @ (1,0) [5]      # O plays in the new timeline L1's present
...
```

A timeline-axis win for X (`dL=+1`, others 0) would require X marks at the *same*
`(t,x,y,z)` on `L0`, `L1`, `L2`. Because a branch copies the source board (which
already contains X's mark at that cell), careless branching can hand the opponent
or the brancher aligned cells across timelines — this cross-timeline tactic is the
strategic heart of the game and MUST be exercised by tests in Stack A and probed
by the analysis tooling in Stacks C/D.

---

*End of specification v1.0.*
