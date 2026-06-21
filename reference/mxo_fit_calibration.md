# Fit a calibrator from calibration data

Maps the heuristic evaluation score to a `[0, 1]` win probability for
the player-to-move. Logistic and isotonic fits are supported; both
produce compact, serialisable `mxo_calibrator` objects.

## Usage

``` r
mxo_fit_calibration(data, type = c("logistic", "isotonic"))
```

## Arguments

- data:

  A tibble of the form produced by
  [`mxo_make_calibration_data()`](https://r-heller.github.io/multixoR/reference/mxo_make_calibration_data.md).

- type:

  One of `"logistic"` (default) or `"isotonic"`.

## Value

An object of class `mxo_calibrator`.
