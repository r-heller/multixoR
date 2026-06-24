# Extra coverage for R/mxo_game.R: scalar/positive-int coercion branches and
# the remaining validator invariants not hit by test-game.R.

test_that(".mxo_check_pos_int rejects every malformed scalar shape", {
  expect_error(mxo_new_game(n = c(1L, 2L)), "must be a scalar")
  expect_error(mxo_new_game(n = NA_integer_), "positive integer")
  expect_error(mxo_new_game(n = TRUE), "positive integer")
  expect_error(mxo_new_game(n = "4"), "positive integer")
  expect_error(mxo_new_game(n = 2.5), "positive integer")
  expect_error(mxo_new_game(n = -1L), "positive integer")
})

test_that("validate_mxo_game rejects a non-mxo_game object", {
  expect_error(validate_mxo_game(list()), "must be an")
})

test_that("validate_mxo_game reports a missing config field", {
  g <- mxo_new_game()
  bad <- g
  bad$config$k <- NULL
  expect_error(validate_mxo_game(bad), "missing field")
})

test_that("validate_mxo_game rejects a board of the wrong length", {
  g <- mxo_new_game()
  bad <- g
  bad$boards[["0:0"]] <- integer(3L)
  expect_error(validate_mxo_game(bad), "integer vector of length")
})

test_that("validate_mxo_game rejects non-integer timeline labels", {
  g <- mxo_new_game()
  bad <- g
  names(bad$timelines) <- "root"
  expect_error(validate_mxo_game(bad), "integer-valued names")
})

test_that(".mxo_next_timeline returns 0 on an empty timeline set", {
  g <- mxo_new_game()
  empty <- g
  empty$timelines <- list()
  expect_equal(multixoR:::.mxo_next_timeline(empty), 0L)
})
