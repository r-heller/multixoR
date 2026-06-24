# Extra coverage for R/mxo_print.R: accessor type-guards, the non-3D
# as_tibble branch, the empty-occupancy branch, and the summary print method.

test_that("accessors reject non-game inputs", {
  expect_error(mxo_status(list()), "must be an")
  expect_error(mxo_is_terminal(list()), "must be an")
  expect_error(mxo_to_move(list()), "must be an")
  expect_error(mxo_config(list()), "must be an")
  expect_error(mxo_history(list()), "must be an")
  expect_error(mxo_timelines(list()), "must be an")
  expect_error(mxo_board(list(), 0L, 0L), "must be an")
})

test_that("print and summary-print run on a branched game", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  withr::local_options(cli.num_colors = 1L)
  expect_invisible(print(g))
  expect_invisible(print(summary(g)))
})

test_that("as_tibble.mxo_game on the empty start has the 3-D columns and 0 rows", {
  g <- mxo_new_game()
  tb <- as_tibble.mxo_game(g)
  expect_equal(nrow(tb), 0L)
  expect_true(all(c("L", "t", "x", "y", "z", "idx", "player") %in% names(tb)))
})

test_that("as_tibble.mxo_game uses a coord list-column when d_spatial != 3", {
  g <- mxo_new_game(n = 3L, d_spatial = 2L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  tb <- as_tibble.mxo_game(g)
  expect_true("coord" %in% names(tb))
  expect_false("z" %in% names(tb))
  expect_true(is.list(tb$coord))
})

test_that("mxo_timelines is empty-typed when there are no timelines", {
  g <- mxo_new_game()
  empty <- g
  empty$timelines <- list()
  tl <- mxo_timelines(empty)
  expect_equal(nrow(tl), 0L)
  expect_named(tl, c("L", "parent", "branch_t", "present_t"))
})
