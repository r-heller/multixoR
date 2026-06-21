# Apply a calibrator to a numeric score

Apply a calibrator to a numeric score

## Usage

``` r
mxo_calibrator_predict(calibrator, score)
```

## Arguments

- calibrator:

  An `mxo_calibrator`.

- score:

  Numeric vector of heuristic scores.

## Value

Numeric vector of probabilities in `[0, 1]`.
