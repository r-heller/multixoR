test_that("plot_win_prob accepts a win-prob tibble", {
  df <- tibble::tibble(ply = 1:3,
                       player = c(1L, 2L, 1L),
                       win_prob = c(0.5, 0.4, 0.6))
  p <- mxo_plot_win_prob(df)
  expect_s3_class(p, "ggplot")
})

test_that("plot_win_prob accepts an mxo_game_record", {
  rec <- mxo_self_play(
    mxo_policy("random"), mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 1L, record_eval = TRUE
  )
  expect_s3_class(mxo_plot_win_prob(rec), "ggplot")
})

test_that("plot_eval renders the heuristic curve", {
  rec <- mxo_self_play(
    mxo_policy("random"), mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L, record_eval = TRUE
  )
  p <- mxo_plot_eval(rec)
  expect_s3_class(p, "ggplot")
})

test_that("plot_opening accepts an opening_table from C", {
  tab <- mxo_opening_table(
    opponent = mxo_policy("random"),
    n_games_per_cell = 1L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L
  )
  p <- mxo_plot_opening(tab, n = 3L, d_spatial = 3L)
  expect_s3_class(p, "ggplot")
})
