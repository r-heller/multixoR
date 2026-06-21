# Summarise a batch self-play result

Returns the key strategic diagnostics (win-rate by colour, draw-rate,
mean plies/timelines, and the fraction of wins decided by a cross-
timeline line — the §12 stress-test number).

## Usage

``` r
# S3 method for class 'mxo_sim_result'
summary(object, ...)

# S3 method for class 'mxo_sim_summary'
print(x, ...)
```

## Arguments

- object:

  An `mxo_sim_result`.

- ...:

  Unused.

- x:

  An `mxo_sim_summary`.

## Value

An `mxo_sim_summary` object.

Invisibly returns `x`.
