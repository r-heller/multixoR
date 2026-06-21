test_that("evaluator is zero on the empty starting position", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_equal(mxo_evaluate(g, 1L), 0)
  expect_equal(mxo_evaluate(g, 2L), 0)
})

test_that("evaluator is symmetric in player perspective", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  expect_equal(mxo_evaluate(g, 1L), -mxo_evaluate(g, 2L))
})

test_that("a 2-line scores above a 1-line", {
  one_line <- mxo_new_game(n = 3L, k = 3L)
  one_line <- mxo_move(one_line, "present", 0L, 0L, 0L)
  two_line <- one_line
  two_line <- mxo_move(two_line, "present", 0L, 1L, 26L)
  two_line <- mxo_move(two_line, "present", 0L, 2L, 1L)
  expect_gt(mxo_evaluate(two_line, 1L), mxo_evaluate(one_line, 1L))
})

test_that("a terminal win returns the large sentinel", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_gt(mxo_evaluate(g, 1L), 1e5)
  expect_lt(mxo_evaluate(g, 2L), -1e5)
})

test_that("line features classify by axis class", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  feats <- multixoR:::.mxo_line_features(g)
  expect_s3_class(feats, "tbl_df")
  expect_named(feats, c("player", "m", "axis_class", "count"))
  expect_true(all(feats$axis_class %in%
                  c("spatial", "time", "timeline", "mixed")))
})
