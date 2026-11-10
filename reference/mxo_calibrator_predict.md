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

## Examples

``` r
cd <- tibble::tibble(score = c(-30, -10, -5, 0, 5, 10, 30, 40),
                     outcome = c(-1L, -1L, 1L, 0L, -1L, 1L, 1L, 1L))
cal <- mxo_fit_calibration(cd)
mxo_calibrator_predict(cal, c(-20, 0, 20))
#> [1] 0.08253012 0.50226700 0.91883277
```
