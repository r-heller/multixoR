# Plot the openings heatmap

Consumes the output of
[`mxo_opening_table()`](https://r-heller.github.io/multixoR/reference/mxo_opening_table.md)
and renders X's first-move win-rate as a faceted-by-z heatmap.

## Usage

``` r
mxo_plot_opening(opening_table, n = 4L, d_spatial = 3L, ...)
```

## Arguments

- opening_table:

  The tibble produced by
  [`mxo_opening_table()`](https://r-heller.github.io/multixoR/reference/mxo_opening_table.md).

- n, d_spatial:

  Geometry parameters used to derive cell coordinates.

- ...:

  Unused.

## Value

A `ggplot` object.
