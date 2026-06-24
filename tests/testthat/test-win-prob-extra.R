# Extra coverage for R/mxo_win_prob.R and R/mxo_win.R helpers.

test_that("mxo_win_prob validates its game argument", {
  expect_error(mxo_win_prob(list()), "must be an")
})

test_that("terminal draw maps to 0.5 win probability", {
  g <- mxo_new_game(n = 4L, ply_cap = 4L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 3L)
  g <- mxo_move(g, "branch",  0L, 0L, 5L)
  g <- mxo_move(g, "branch",  0L, 0L, 7L)
  expect_equal(g$status, "draw")
  expect_equal(mxo_win_prob(g, player = 1L, method = "heuristic"), 0.5)
})

test_that("mcts win-prob aggregates root values into [0, 1]", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  p1 <- mxo_win_prob(g, player = 1L, method = "mcts", iterations = 25L,
                     rollout = "random", branch_policy = "none", seed = 3L)
  p2 <- mxo_win_prob(g, player = 2L, method = "mcts", iterations = 25L,
                     rollout = "random", branch_policy = "none", seed = 3L)
  expect_gte(p1, 0); expect_lte(p1, 1)
  expect_equal(p1 + p2, 1, tolerance = 1e-8)
})

test_that("win_prob_curve on an empty history is a 0-row typed tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  curve <- mxo_win_prob_curve(g)
  expect_equal(nrow(curve), 0L)
  expect_named(curve, c("ply", "player", "win_prob"))
})

test_that("mxo_win_prob_curve validates its game argument", {
  expect_error(mxo_win_prob_curve(list()), "must be an")
})

test_that("the active calibrator predicts a finite probability", {
  cal <- multixoR:::.mxo_active_calibrator()
  expect_s3_class(cal, "mxo_calibrator")
  p <- multixoR:::.mxo_predict_calibrator(cal, 0)
  expect_gte(p, 0); expect_lte(p, 1)
})
