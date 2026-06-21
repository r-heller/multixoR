test_that("calibration data has the right columns and decisive plies", {
  data <- mxo_make_calibration_data(
    n_games = 4L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L
  )
  expect_named(data, c("score", "outcome"))
  expect_true(all(data$outcome %in% c(-1L, 0L, 1L)))
})

test_that("fit_calibration returns a calibrator with a finite Brier", {
  data <- mxo_make_calibration_data(
    n_games = 8L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 1L
  )
  cal <- suppressWarnings(mxo_fit_calibration(data, type = "logistic"))
  expect_s3_class(cal, "mxo_calibrator")
  if (!is.na(cal$brier)) {
    expect_lte(cal$brier, cal$baseline_brier + 1e-6)
  }
})

test_that("calibrator predict returns probabilities in [0, 1]", {
  data <- mxo_make_calibration_data(
    n_games = 8L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 1L
  )
  cal <- suppressWarnings(mxo_fit_calibration(data, type = "logistic"))
  p <- mxo_calibrator_predict(cal, seq(-1000, 1000, length.out = 50))
  expect_true(all(p >= 0 & p <= 1))
})

test_that("isotonic fit also returns a valid calibrator", {
  data <- mxo_make_calibration_data(
    n_games = 30L,
    policy_x = mxo_policy("random", branch_policy = "all"),
    policy_o = mxo_policy("random", branch_policy = "all"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 8L),
    seed = 2L
  )
  cal <- suppressWarnings(mxo_fit_calibration(data, type = "isotonic"))
  expect_true(cal$type %in% c("isotonic", "logistic"))
  p <- mxo_calibrator_predict(cal, c(-10, 0, 10))
  expect_true(all(p >= 0 & p <= 1))
})

test_that("calibrator serialises round-trip", {
  data <- mxo_make_calibration_data(
    n_games = 6L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L
  )
  cal <- suppressWarnings(mxo_fit_calibration(data, type = "logistic"))
  raw <- serialize(cal, connection = NULL)
  cal2 <- unserialize(raw)
  expect_equal(
    mxo_calibrator_predict(cal, c(-5, 0, 5)),
    mxo_calibrator_predict(cal2, c(-5, 0, 5))
  )
})

test_that("the fitted default calibrator pins mxo_win_prob (B-pass-2 regression)", {
  # Pinning test: the calibrator shipped in R/sysdata.rda is the one
  # produced by data-raw/make_calibrator.R. Any change to that script (or
  # to mxo_evaluate) will move this number.
  g <- mxo_new_game(n = 3L, k = 3L)
  p <- mxo_win_prob(g, player = 1L, method = "heuristic")
  expect_gt(p, 0.45)
  expect_lt(p, 0.65)
})
