test_that("heuristic win-prob is in [0, 1] and 0.5 on the empty start", {
  g <- mxo_new_game(n = 3L, k = 3L)
  p <- mxo_win_prob(g, player = 1L, method = "heuristic")
  expect_gte(p, 0)
  expect_lte(p, 1)
  expect_equal(p, 0.5)
})

test_that("heuristic win-prob saturates at terminal", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_equal(mxo_win_prob(g, player = 1L, method = "heuristic"), 1)
  expect_equal(mxo_win_prob(g, player = 2L, method = "heuristic"), 0)
})

test_that("mcts win-prob is in [0,1]", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  p <- mxo_win_prob(g, player = 1L, method = "mcts",
                    iterations = 20L, rollout = "random",
                    branch_policy = "none", seed = 1L)
  expect_gte(p, 0)
  expect_lte(p, 1)
})

test_that("curve has the documented columns and one row per (ply, player)", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  curve <- mxo_win_prob_curve(g)
  expect_named(curve, c("ply", "player", "win_prob"))
  expect_equal(nrow(curve), 4L)
})
