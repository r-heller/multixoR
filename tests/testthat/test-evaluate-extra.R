# Extra coverage for R/mxo_evaluate.R: argument validation, the draw-terminal
# branch, custom weights, and the timeline weight multiplier.

test_that("mxo_evaluate validates game and player", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_evaluate(list()), "must be an")
  expect_error(mxo_evaluate(g, player = c(1L, 2L)), "must be")
})

test_that("mxo_evaluate rejects a weight vector of the wrong length", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_evaluate(g, player = 1L, w = c(1, 2)), "must have length")
})

test_that("a draw position evaluates to exactly zero", {
  g <- mxo_new_game(n = 4L, ply_cap = 4L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 3L)
  g <- mxo_move(g, "branch",  0L, 0L, 5L)
  g <- mxo_move(g, "branch",  0L, 0L, 7L)
  expect_equal(g$status, "draw")
  expect_equal(mxo_evaluate(g, player = 1L), 0)
})

test_that("custom weights change the score and w_timeline scales it", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  base <- mxo_evaluate(g, player = 1L)
  custom <- mxo_evaluate(g, player = 1L, w = c(1, 2, 3))
  expect_false(isTRUE(all.equal(base, custom)))
  amped <- mxo_evaluate(g, player = 1L, w_timeline = 5)
  expect_true(is.numeric(amped))
})

test_that(".mxo_axis_class labels each direction family", {
  expect_equal(multixoR:::.mxo_axis_class(c(0L, 0L, 1L, 0L, 0L)), "spatial")
  expect_equal(multixoR:::.mxo_axis_class(c(0L, 1L, 0L, 0L, 0L)), "time")
  expect_equal(multixoR:::.mxo_axis_class(c(1L, 0L, 0L, 0L, 0L)), "timeline")
  expect_equal(multixoR:::.mxo_axis_class(c(1L, 1L, 1L, 0L, 0L)), "mixed")
})
