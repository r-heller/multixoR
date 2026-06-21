test_that("plot_board returns a ggplot for slices view", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  p <- mxo_plot_board(g, L = 0L, t = 0L)
  expect_s3_class(p, "ggplot")
})

test_that("plot_board returns a plotly for cube view", {
  g <- mxo_new_game()
  p <- mxo_plot_board(g, L = 0L, t = 0L, view = "cube")
  expect_s3_class(p, "plotly")
})

test_that("plot_board with overlay='top3' accepts an injected rating", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  rating <- mxo_rate_moves(g, method = "heuristic")
  p <- mxo_plot_board(g, L = 0L, t = 0L, overlay = "top3", rating = rating)
  expect_s3_class(p, "ggplot")
})

test_that("plot_board with overlay='heatmap' returns ggplot", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  rating <- mxo_rate_moves(g, method = "heuristic")
  p <- mxo_plot_board(g, L = 0L, t = 0L, overlay = "heatmap", rating = rating)
  expect_s3_class(p, "ggplot")
})

test_that("plot_board highlights a winning line on a terminal game", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_equal(g$status, "x_win")
  p <- mxo_plot_board(g, L = 0L, t = 4L)
  expect_s3_class(p, "ggplot")
})
