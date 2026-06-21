# Serialize a ply record to canonical notation

Serialize a ply record to canonical notation

## Usage

``` r
mxo_format_ply(record)
```

## Arguments

- record:

  A ply record (a named list with `player`, `kind`, `L_src`, `t_src`,
  `idx`, and, for branch plies, `L_new`).

## Value

A character scalar in the canonical notation.

## Examples

``` r
rec <- list(player = 1L, kind = "present", L_src = 0L,
            t_src = 0L, idx = 21L, L_new = NA_integer_)
mxo_format_ply(rec)
#> [1] "X present @ (0,0) [21]"
```
