test_that("autoplot.mxo_game dispatches per type", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_s3_class(ggplot2::autoplot(g, type = "multiverse"), "ggplot")
  expect_s3_class(ggplot2::autoplot(g, type = "board",
                                    L = 0L, t = 0L), "ggplot")
  expect_s3_class(ggplot2::autoplot(g, type = "threats"), "ggplot")
  expect_s3_class(ggplot2::autoplot(g, type = "tree"), "ggplot")
})

test_that("autoplot.mxo_sim_result returns ggplot", {
  sim <- mxo_simulate(
    mxo_policy("random"), mxo_policy("random"),
    n_games = 2L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L, record_eval = FALSE, progress = FALSE
  )
  expect_s3_class(ggplot2::autoplot(sim), "ggplot")
})

test_that("autoplot.mxo_game_record returns ggplot", {
  rec <- mxo_self_play(
    mxo_policy("random"), mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L, record_eval = TRUE
  )
  expect_s3_class(ggplot2::autoplot(rec), "ggplot")
})
