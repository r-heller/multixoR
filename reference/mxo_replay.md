# Rebuild a game by replaying a history log

Proves full replayability from `history` alone (rules §11).

## Usage

``` r
mxo_replay(history, config)
```

## Arguments

- history:

  A list of ply records, in order, of the form produced by
  [`mxo_move()`](https://r-heller.github.io/multixoR/reference/mxo_move.md).

- config:

  A configuration list
  (`list(n, d_spatial, k, ply_cap, max_timelines)`).

## Value

A new `mxo_game` object equivalent to the original.

## Examples

``` r
g <- mxo_new_game()
g <- mxo_move(g, "present", 0L, 0L, 0L)
identical(mxo_replay(g$history, g$config)$boards, g$boards)
#> [1] TRUE
```
