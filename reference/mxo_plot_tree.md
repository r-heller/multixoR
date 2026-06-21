# Plot the branch tree of a multixoR game

Nodes are timelines, edges are parent-\>child branches drawn at the
branching time. Layout: x = branch_t (root at x = 0), y = timeline label
spread vertically.

## Usage

``` r
mxo_plot_tree(game, ...)
```

## Arguments

- game:

  An `mxo_game` object.

- ...:

  Unused. Reserved for future arguments.

## Value

A `ggplot` object.
