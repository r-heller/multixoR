test_that("simulate with n_games = 0 returns the typed empty result", {
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 0L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
                      progress = FALSE)
  expect_s3_class(sim, "mxo_sim_result")
  expect_equal(nrow(sim$games), 0L)
  expect_named(sim$games, c("game_id", "seed", "winner", "outcome",
                            "n_plies", "n_timelines", "win_axis_class",
                            "cross_timeline_win", "first_move_kind",
                            "first_move_idx"))
})

test_that("simulate is reproducible under seed", {
  cfg <- mxo_config_default(n = 3L, k = 3L, ply_cap = 6L)
  a <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                    n_games = 3L, config = cfg, seed = 42L,
                    record_eval = FALSE, progress = FALSE)
  b <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                    n_games = 3L, config = cfg, seed = 42L,
                    record_eval = FALSE, progress = FALSE)
  expect_identical(a$games, b$games)
})

test_that("summary returns rates in [0, 1]", {
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 4L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
                      seed = 1L, record_eval = FALSE, progress = FALSE)
  s <- summary(sim)
  expect_s3_class(s, "mxo_sim_summary")
  for (nm in c("x_win_rate", "o_win_rate", "draw_rate")) {
    expect_gte(s[[nm]], 0)
    expect_lte(s[[nm]], 1)
  }
  expect_equal(s$x_win_rate + s$o_win_rate + s$draw_rate, 1)
})

test_that("sim_result print method runs", {
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 1L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
                      seed = 1L, record_eval = FALSE, progress = FALSE)
  expect_invisible(print(sim))
  expect_invisible(print(summary(sim)))
})
