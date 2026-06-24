# Extra coverage for R/mxo_policy.R: validation guards, the heuristic and
# negamax move-pickers, and the forced-first opening wrapper.

test_that("mxo_policy_move validates both arguments", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_policy_move(list(), g), "must be an")
  expect_error(mxo_policy_move(mxo_policy("random"), list()), "must be an")
})

test_that("heuristic policy returns a single legal move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  mv <- mxo_policy_move(mxo_policy("heuristic", branch_policy = "promising"), g)
  expect_equal(nrow(mv), 1L)
})

test_that("negamax policy returns a single move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  mv <- mxo_policy_move(mxo_policy("negamax", depth = 1L,
                                  branch_policy = "none"), g)
  expect_equal(nrow(mv), 1L)
})

test_that("forced-first policy plays the requested opening then defers", {
  g <- mxo_new_game(n = 3L, k = 3L)
  forced <- multixoR:::mxo_policy_force_first(
    first = list(kind = "present", L_src = 0L, t_src = 0L, idx = 4L),
    fallback = mxo_policy("random", branch_policy = "none")
  )
  expect_s3_class(forced, "mxo_policy")
  first_mv <- forced$fn(g)
  expect_equal(first_mv$idx, 4L)
  # After one ply, the fallback drives subsequent moves.
  g2 <- mxo_move(g, kind = first_mv$kind, L_src = first_mv$L_src,
                 t_src = first_mv$t_src, idx = first_mv$idx)
  set.seed(1L)
  nxt <- forced$fn(g2)
  expect_equal(nrow(nxt), 1L)
})

test_that("print method renders policy params", {
  withr::local_options(cli.num_colors = 1L)
  expect_invisible(print(mxo_policy("negamax", depth = 3L)))
  expect_invisible(print(mxo_policy("random")))
})
