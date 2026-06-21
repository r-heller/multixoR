# A short example multixoR game

Plays a deterministic sequence of moves that includes one branch and at
least one 2-in-a-row near-threat. Used by docs, vignettes, and as the
Shiny app's default state.

## Usage

``` r
mxo_example_game()
```

## Value

An `mxo_game` object.

## Examples

``` r
g <- mxo_example_game()
mxo_to_move(g)
#> [1] 2
length(g$timelines)
#> [1] 2
```
