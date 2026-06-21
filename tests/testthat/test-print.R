test_that("print returns the game invisibly", {
  g <- mxo_new_game()
  out <- capture.output(res <- withr::with_options(
    list(cli.num_colors = 1L),
    print(g)
  ), type = "message")
  expect_identical(res, g)
})

test_that("format returns a character scalar with config info", {
  g <- mxo_new_game()
  fmt <- format(g)
  expect_type(fmt, "character")
  expect_match(fmt, "n=4")
  expect_match(fmt, "status=in_progress")
})

test_that("summary builds an mxo_game_summary with mark counts", {
  # Under View-1 semantics each placement also appears in the new ready
  # present board, so marks across boards grows by one per ply (one new
  # cell at t = pt, one propagated to t = pt+1).
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 5L)
  s <- summary(g)
  expect_s3_class(s, "mxo_game_summary")
  expect_equal(s$marks_x, 3L)
  expect_equal(s$marks_o, 2L)
  expect_equal(s$plies, 2L)
})

test_that("accessors return declared types on an empty game", {
  g <- mxo_new_game()
  expect_type(mxo_to_move(g), "integer")
  expect_type(mxo_config(g), "list")
  expect_s3_class(mxo_timelines(g), "tbl_df")
  expect_s3_class(mxo_history(g), "tbl_df")
  expect_equal(nrow(mxo_history(g)), 0L)
})

test_that("mxo_board fetches a single board", {
  g <- mxo_new_game()
  b <- mxo_board(g, 0L, 0L)
  expect_type(b, "integer")
  expect_length(b, 64L)
  expect_error(mxo_board(g, 9L, 0L), "No board exists")
})

test_that("as_tibble.mxo_game produces a long-form occupancy frame", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 5L)
  t <- as_tibble.mxo_game(g)
  expect_s3_class(t, "tbl_df")
  expect_true(all(c("L", "t", "x", "y", "z", "idx", "player") %in% names(t)))
  expect_true(all(t$player %in% c(1L, 2L)))
})
