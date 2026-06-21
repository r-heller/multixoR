test_that("MCTS returns a type-stable result", {
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_mcts(g, iterations = 10L, rollout = "random",
                  branch_policy = "none", seed = 1L)
  expect_s3_class(res, "mxo_mcts_result")
  expect_named(res, c("move", "moves", "visits", "values", "n_iter", "elapsed"))
  expect_equal(nrow(res$move), 1L)
  expect_type(res$visits, "integer")
})

test_that("MCTS prefers a winning move when one exists", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 25L)
  res <- mxo_mcts(g, iterations = 60L, rollout = "random",
                  branch_policy = "none", seed = 1L)
  expect_equal(res$move$idx, 2L)
})

test_that("MCTS respects time_budget", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_mcts(g, iterations = 1e6L, rollout = "random",
                  branch_policy = "none", time_budget = 0.2, seed = 1L)
  expect_lt(res$elapsed, 2)
})

test_that("MCTS on a terminal game returns 0-row move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  res <- mxo_mcts(g, iterations = 5L, branch_policy = "none")
  expect_equal(nrow(res$move), 0L)
})

test_that("MCTS prints without erroring", {
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_mcts(g, iterations = 5L, rollout = "random",
                  branch_policy = "none", seed = 1L)
  expect_invisible(print(res))
})
