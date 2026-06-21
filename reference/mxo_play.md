# Play a move described by one row of `mxo_legal_moves()`

Convenience wrapper for piping a chosen row of
[`mxo_legal_moves()`](https://r-heller.github.io/multixoR/reference/mxo_legal_moves.md)
back into
[`mxo_move()`](https://r-heller.github.io/multixoR/reference/mxo_move.md).

## Usage

``` r
mxo_play(game, move)
```

## Arguments

- game:

  An `mxo_game` object.

- move:

  A single-row tibble or a `list` with named entries `kind`, `L_src`,
  `t_src`, and `idx`.

## Value

A new `mxo_game` object.

## Examples

``` r
g <- mxo_new_game()
mv <- mxo_legal_moves(g)[1L, ]
mxo_play(g, mv)
#> 
#> ── multixoR game ───────────────────────────────────────────────────────────────
#> ℹ Config: n=4, d_spatial=3, k=3, ply_cap=60, max_timelines=32
#> ℹ Multiverse: 1 timeline, 2 boards
#> ℹ Plies played: 1; to move: O
#> ℹ Status: in_progress
#> 
#> Multiverse sketch (timelines x time; '.' = no board, '#' = occupied count)
#> L\t 0 1
#> L0 1 1
```
