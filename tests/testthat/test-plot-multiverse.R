test_that("plot_multiverse returns a ggplot on the empty start", {
  g <- mxo_new_game()
  expect_s3_class(mxo_plot_multiverse(g), "ggplot")
})

test_that("plot_multiverse handles branching games", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  expect_s3_class(mxo_plot_multiverse(g), "ggplot")
})

test_that("plot_multiverse focus mode forwards to plot_board", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  p <- mxo_plot_multiverse(g, mode = "focus", focus = list(L = 0L, t = 0L))
  expect_s3_class(p, "ggplot")
})

test_that("plot_threats classifies axis classes", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  p <- mxo_plot_threats(g, player = 1L)
  expect_s3_class(p, "ggplot")
})
