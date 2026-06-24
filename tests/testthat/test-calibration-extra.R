# Extra coverage for R/mxo_calibration.R: the flat-0.5 fallback, the isotonic
# predictor branch, the reliability table, and the print method.

test_that("fit_calibration errors when score/outcome columns are absent", {
  expect_error(mxo_fit_calibration(tibble::tibble(a = 1, b = 2)),
               "must have columns")
})

test_that("too few decisive plies yields a warned flat-0.5 calibrator", {
  data <- tibble::tibble(score = c(1, 2), outcome = c(0L, 0L))
  expect_warning(cal <- mxo_fit_calibration(data, type = "logistic"),
                 "too few decisive")
  expect_s3_class(cal, "mxo_calibrator")
  expect_equal(mxo_calibrator_predict(cal, c(-100, 0, 100)),
               rep(0.5, 3L))
})

test_that("isotonic predictor clamps and interpolates", {
  cal <- structure(
    list(type = "isotonic", x = c(-2, 0, 2), y = c(0, 0.5, 1)),
    class = "mxo_calibrator"
  )
  p <- mxo_calibrator_predict(cal, c(-10, 0, 10))
  expect_equal(p, c(0, 0.5, 1))
})

test_that("mxo_calibrator_predict rejects a non-calibrator", {
  expect_error(mxo_calibrator_predict(list(), 0), "must be an")
})

test_that("the calibrator print method runs for both fitted and flat fits", {
  withr::local_options(cli.num_colors = 1L)
  flat <- structure(
    list(type = "logistic", a = 0, b = 0, n = 0L,
         brier = NA_real_, baseline_brier = NA_real_,
         reliability = multixoR:::.mxo_empty_reliability()),
    class = "mxo_calibrator"
  )
  expect_invisible(print(flat))

  data <- mxo_make_calibration_data(
    n_games = 12L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L), seed = 1L)
  fitted <- suppressWarnings(mxo_fit_calibration(data, type = "logistic"))
  expect_invisible(print(fitted))
})

test_that(".mxo_reliability_table bins probabilities and counts", {
  tab <- multixoR:::.mxo_reliability_table(
    p = c(0.05, 0.15, 0.95), y = c(0L, 1L, 1L), bins = 10L)
  expect_s3_class(tab, "tbl_df")
  expect_equal(nrow(tab), 10L)
  expect_equal(sum(tab$n), 3L)
})
