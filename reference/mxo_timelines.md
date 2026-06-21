# Timeline metadata as a tibble

Timeline metadata as a tibble

## Usage

``` r
mxo_timelines(game)
```

## Arguments

- game:

  An `mxo_game` object.

## Value

A tibble with one row per timeline and columns `L` (int), `parent` (int,
NA for the root), `branch_t` (int, NA for the root), and `present_t`
(int).

## Examples

``` r
mxo_timelines(mxo_new_game())
#> # A tibble: 1 × 4
#>       L parent branch_t present_t
#>   <int>  <int>    <int>     <int>
#> 1     0     NA       NA         0
```
