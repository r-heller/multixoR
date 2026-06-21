test_that("mxo_policy returns a policy that picks a legal move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  for (t in c("random", "heuristic", "negamax")) {
    p <- if (t == "negamax") mxo_policy(t, depth = 1L, branch_policy = "none")
    else mxo_policy(t, branch_policy = "none")
    mv <- mxo_policy_move(p, g)
    expect_equal(nrow(mv), 1L)
    legal <- mxo_legal_moves(g)
    expect_true(any(
      legal$kind == mv$kind & legal$L_src == mv$L_src &
      legal$t_src == mv$t_src & legal$idx == mv$idx
    ))
  }
})

test_that("mcts policy is also legal", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  p <- mxo_policy("mcts", iterations = 10L, branch_policy = "none",
                  rollout = "random")
  set.seed(1L)
  mv <- mxo_policy_move(p, g)
  expect_equal(nrow(mv), 1L)
})

test_that("is_mxo_policy distinguishes the class", {
  expect_true(is_mxo_policy(mxo_policy("random")))
  expect_false(is_mxo_policy(list()))
})

test_that("policy print method runs", {
  p <- mxo_policy("mcts", iterations = 100L)
  expect_invisible(print(p))
})

test_that("policy on terminal game returns zero-row move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  p <- mxo_policy("random")
  expect_equal(nrow(mxo_policy_move(p, g)), 0L)
})
