# Extra coverage for R/mxo_move.R: argument validation, present-move edge
# cases, mxo_play dispatch branches, and mxo_undo / mxo_replay errors.

test_that("mxo_move validates game, kind, and index arguments", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_move(list(), "present", 0L, 0L, 0L), "must be an")
  expect_error(mxo_move(g, "sideways", 0L, 0L, 0L), "either")
  expect_error(mxo_move(g, "present", 0L, 0L, 999L), "out of range")
  expect_error(mxo_move(g, "present", 5L, 0L, 0L), "does not exist")
})

test_that(".mxo_check_pos_int_zero rejects malformed move coordinates", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_move(g, "present", c(0L, 1L), 0L, 0L), "must be a scalar")
  expect_error(mxo_move(g, "present", 0L, 0L, NA_integer_), "non-negative integer")
  expect_error(mxo_move(g, "present", 0L, 0L, 1.5), "non-negative integer")
  expect_error(mxo_move(g, "present", 0L, 0L, -1L), "non-negative integer")
  expect_error(mxo_move(g, "present", 0L, 0L, "x"), "non-negative integer")
})

test_that("a present move to the wrong t errors", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_error(mxo_move(g, "present", 0L, 0L, 1L), "must target the present")
})

test_that("a present move onto an occupied present cell errors", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_error(mxo_move(g, "present", 0L, 1L, 0L), "already occupied")
})

test_that("mxo_play rejects a multi-row tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  two <- mxo_legal_moves(g)[1:2, ]
  expect_error(mxo_play(g, two), "exactly one row")
})

test_that("mxo_play rejects a list missing required fields", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_play(g, list(kind = "present")), "missing field")
})

test_that("mxo_play rejects an atomic, non-list move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_play(g, 42L), "one-row tibble or a named list")
})

test_that("mxo_undo validates its game and step count", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_error(mxo_undo(list()), "must be an")
  expect_error(mxo_undo(g, 5L), "exceeds")
})

test_that("mxo_undo with steps = 0 returns the game unchanged", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_identical(mxo_undo(g, 0L), g)
})

test_that("mxo_replay rejects a non-list history", {
  expect_error(mxo_replay("nope", mxo_config_default()),
               "must be a list of ply records")
})

test_that("mxo_legal_moves rejects a non-game", {
  expect_error(mxo_legal_moves(list()), "must be an")
})
