test_that("plot_tree returns a ggplot for a single-timeline game", {
  g <- mxo_new_game()
  expect_s3_class(mxo_plot_tree(g), "ggplot")
})

test_that("plot_tree handles branched games", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "branch", 0L, 0L, 63L)
  expect_s3_class(mxo_plot_tree(g), "ggplot")
})
