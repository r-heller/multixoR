# Extra coverage for R/mxo_mcts.R: validation, the heuristic rollout path,
# branch_policy='promising', and the terminal-node print branch.

test_that("mxo_mcts validates its game argument", {
  expect_error(mxo_mcts(list()), "must be an")
})

test_that("MCTS with heuristic rollout returns a legal move", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_mcts(g, iterations = 8L, rollout = "heuristic",
                  branch_policy = "none", epsilon = 1, seed = 2L)
  expect_s3_class(res, "mxo_mcts_result")
  expect_equal(nrow(res$move), 1L)
})

test_that("MCTS with branch_policy='promising' runs on a branched game", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L, ply_cap = 10L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 13L)
  res <- mxo_mcts(g, iterations = 6L, rollout = "random",
                  branch_policy = "promising", seed = 1L)
  expect_true(res$n_iter >= 1L)
})

test_that("print on a terminal MCTS result reports no move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  res <- mxo_mcts(g, iterations = 3L, branch_policy = "none")
  withr::local_options(cli.num_colors = 1L)
  expect_invisible(print(res))
})
