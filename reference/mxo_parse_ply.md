# Parse a ply notation string into a record

Inverse of
[`mxo_format_ply()`](https://r-heller.github.io/multixoR/reference/mxo_format_ply.md).
Branch plies populate `L_new`; present plies set it to `NA_integer_`.

## Usage

``` r
mxo_parse_ply(string)
```

## Arguments

- string:

  A character scalar.

## Value

A list with components `player`, `kind`, `L_src`, `t_src`, `idx`, and
`L_new` (NA for present plies).

## Examples

``` r
mxo_parse_ply("X present @ (0,0) [21]")
#> $player
#> [1] 1
#> 
#> $kind
#> [1] "present"
#> 
#> $L_src
#> [1] 0
#> 
#> $t_src
#> [1] 0
#> 
#> $idx
#> [1] 21
#> 
#> $L_new
#> [1] NA
#> 
mxo_parse_ply("X branch  @ (0,0) [42] -> L1")
#> $player
#> [1] 1
#> 
#> $kind
#> [1] "branch"
#> 
#> $L_src
#> [1] 0
#> 
#> $t_src
#> [1] 0
#> 
#> $idx
#> [1] 42
#> 
#> $L_new
#> [1] 1
#> 
```
