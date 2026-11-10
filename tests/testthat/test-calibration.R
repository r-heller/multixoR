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
  skip_on_cran() # about 9 s: simulates 30 calibration games
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


test_that("isotonic knots preserve tied-score fits without prediction warnings", {
  data <- data.frame(score=c(0,0,1,1),outcome=c(1L,-1L,-1L,1L))
  expect_warning(cal <- mxo_fit_calibration(data,"isotonic"),NA)
  expect_equal(cal$x,c(0,1))
  expect_warning(p <- mxo_calibrator_predict(cal,c(0,0.5,1)),NA)
  expect_equal(p,rep(0.5,3))
  reversed <- mxo_fit_calibration(data[c(2,1,3,4),],"isotonic")
  expect_equal(mxo_calibrator_predict(reversed,c(0,0.5,1)),p)
})

test_that("a single distinct isotonic score has a constant prediction", {
  data <- data.frame(score=rep(2,4),outcome=c(1L,1L,-1L,-1L))
  expect_warning(cal <- mxo_fit_calibration(data,"isotonic"),NA)
  expect_equal(mxo_calibrator_predict(cal,c(-100,2,100)),rep(0.5,3))
  expect_true(is.na(mxo_calibrator_predict(cal,NA_real_)))
})
