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

## Examples

``` r
cd <- mxo_make_calibration_data(
  n_games = 3L, config = mxo_config_default(n = 3L, ply_cap = 12L),
  seed = 1L
)
mxo_fit_calibration(cd)
#> 
#> ── mxo_calibrator ──────────────────────────────────────────────────────────────
#> ℹ Type: logistic
#> ℹ a = 7e-06, b = 0.222999
#> ℹ n decisive plies: 10
#> ℹ Brier: 0.2226 (baseline 0.25)
mxo_fit_calibration(cd, type = "isotonic")
#> 
#> ── mxo_calibrator ──────────────────────────────────────────────────────────────
#> ℹ Type: isotonic
#> ℹ n decisive plies: 10
#> ℹ Brier: 0.2222 (baseline 0.25)
```
