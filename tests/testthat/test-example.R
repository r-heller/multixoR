test_that("mxo_example_game is reproducible and includes a branch", {
  a <- mxo_example_game()
  b <- mxo_example_game()
  expect_identical(a$boards, b$boards)
  expect_identical(a$timelines, b$timelines)
  expect_true(length(a$timelines) >= 2L)
  expect_true(any(vapply(a$history, function(h)
    identical(h$kind, "branch"), logical(1L))))
})

test_that("mxo_example_game's status is in_progress and ready to play", {
  g <- mxo_example_game()
  expect_equal(g$status, "in_progress")
  expect_gt(nrow(mxo_legal_moves(g)), 0L)
})
