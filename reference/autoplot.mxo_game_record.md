# Auto-render a self-play record

Returns the win-probability curve of the record via
[`mxo_plot_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_plot_win_prob.md).

## Usage

``` r
# S3 method for class 'mxo_game_record'
autoplot(object, ...)
```

## Arguments

- object:

  An `mxo_game_record`.

- ...:

  Unused.

## Value

A `ggplot` object.
