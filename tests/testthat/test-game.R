test_that("mxo_new_game returns a valid in-progress game with one empty board", {
  g <- mxo_new_game()
  expect_s3_class(g, "mxo_game")
  expect_true(is_mxo_game(g))
  expect_equal(mxo_to_move(g), 1L)
  expect_equal(g$status, "in_progress")
  expect_length(g$boards, 1L)
  expect_named(g$boards, "0:0")
  expect_equal(sum(g$boards[["0:0"]]), 0L)
  expect_length(g$boards[["0:0"]], 64L)
  expect_equal(mxo_config(g)$n, 4L)
})

test_that("mxo_new_game rejects nonsensical configs", {
  expect_error(mxo_new_game(n = 0L), "positive integer")
  expect_error(mxo_new_game(n = 4L, k = 5L), "cannot exceed")
  expect_error(mxo_new_game(d_spatial = -1L), "positive integer")
  expect_error(mxo_new_game(max_timelines = 0L), "positive integer|at least 1")
})

test_that("validator rejects mismatched cell domain", {
  g <- mxo_new_game()
  bad <- g
  bad$boards[["0:0"]][1L] <- 9L
  expect_error(validate_mxo_game(bad), "values outside")
})

test_that("validator rejects parity mismatch", {
  g <- mxo_new_game()
  bad <- g
  bad$to_move <- 2L
  expect_error(validate_mxo_game(bad), "Parity mismatch")
})

test_that("validator rejects non-contiguous timeline labels", {
  g <- mxo_new_game()
  bad <- g
  bad$timelines[["5"]] <- bad$timelines[["0"]]
  expect_error(validate_mxo_game(bad), "contiguous")
})

test_that("is_mxo_game distinguishes the class", {
  expect_true(is_mxo_game(mxo_new_game()))
  expect_false(is_mxo_game(list()))
  expect_false(is_mxo_game(NULL))
})
