# Start a new multixoR game

Creates a fresh game state with one empty board at `(L0, t0)`. The
geometry is parameterised by `(n, d_spatial, k)`; the default 4 / 3 / 3
corresponds to the canonical configuration described in the game
specification.

## Usage

``` r
mxo_new_game(
  n = 4L,
  d_spatial = 3L,
  k = 3L,
  ply_cap = 60L,
  max_timelines = 32L
)
```

## Arguments

- n:

  Integer scalar, spatial side length. Default 4.

- d_spatial:

  Integer scalar, number of spatial dimensions. Default 3.

- k:

  Integer scalar, run length required to win. Default 3. Must satisfy
  `k <= n`.

- ply_cap:

  Integer scalar, total plies allowed before the game is declared a
  draw. Default 60.

- max_timelines:

  Integer scalar, maximum number of timelines the multiverse may host.
  Default 32.

## Value

An object of class `mxo_game` with one empty board at `(L0, t0)` and X
to move.

## Examples

``` r
g <- mxo_new_game()
g
#> 
#> ── multixoR game ───────────────────────────────────────────────────────────────
#> ℹ Config: n=4, d_spatial=3, k=3, ply_cap=60, max_timelines=32
#> ℹ Multiverse: 1 timeline, 1 board
#> ℹ Plies played: 0; to move: X
#> ℹ Status: in_progress
#> 
#> Multiverse sketch (timelines x time; '.' = no board, '#' = occupied count)
#> L\t 0
#> L0 0
mxo_to_move(g)
#> [1] 1
```
