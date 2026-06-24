# Extra coverage for the visualisation stack: validation guards, the cube
# renderer with occupied marks, the focus-mode error, win-prob/eval empties,
# the opening-table guard, and the highlight-segment helper.

test_that("plot entry points reject non-game inputs", {
  expect_error(mxo_plot_board(list()), "must be an")
  expect_error(mxo_plot_multiverse(list()), "must be an")
  expect_error(mxo_plot_threats(list()), "must be an")
  expect_error(mxo_plot_tree(list()), "must be an")
})

test_that("cube view renders occupied marks", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  p <- mxo_plot_board(g, L = 0L, t = 1L, view = "cube")
  expect_s3_class(p, "plotly")
})

test_that("plot_multiverse focus mode requires a focus list", {
  g <- mxo_new_game()
  expect_error(mxo_plot_multiverse(g, mode = "focus"), "requires")
})

test_that("plot_win_prob and plot_eval handle empty records", {
  rec <- mxo_self_play(
    mxo_policy("random"), mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 2L),
    seed = 1L, record_eval = FALSE)
  # record_eval = FALSE => no win_probs / evals
  expect_s3_class(mxo_plot_win_prob(rec), "ggplot")
  expect_s3_class(mxo_plot_eval(rec), "ggplot")
})

test_that("plot_win_prob rejects a malformed source", {
  expect_error(mxo_plot_win_prob(tibble::tibble(a = 1)), "must be a tibble")
})

test_that("plot_eval rejects a non-record", {
  expect_error(mxo_plot_eval(list()), "must be an")
})

test_that("plot_win_prob on an empty tibble returns a placeholder ggplot", {
  df <- tibble::tibble(ply = integer(0), player = integer(0),
                       win_prob = numeric(0))
  expect_s3_class(mxo_plot_win_prob(df), "ggplot")
})

test_that("plot_opening guards required columns", {
  expect_error(mxo_plot_opening(tibble::tibble(idx = 0L)), "must include")
})

test_that("autoplot on a zero-game simulation returns a placeholder ggplot", {
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 0L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
                      progress = FALSE)
  expect_s3_class(ggplot2::autoplot(sim), "ggplot")
})

test_that(".mxo_lines_to_seg builds in-facet segments and drops cross-z pairs", {
  cfg <- mxo_config_default(n = 3L, k = 3L)
  # Three cells along x on z = 0: idx 0, 1, 2.
  line <- list(list(L = 0L, t = 0L, idx = 0L),
               list(L = 0L, t = 0L, idx = 1L),
               list(L = 0L, t = 0L, idx = 2L))
  seg <- multixoR:::.mxo_lines_to_seg(list(line), 0L, 0L, cfg)
  expect_s3_class(seg, "tbl_df")
  expect_true(nrow(seg) >= 1L)
  # A line whose cells are not on board (0,0) yields NULL.
  off <- list(list(L = 1L, t = 0L, idx = 0L),
              list(L = 1L, t = 0L, idx = 1L))
  expect_null(multixoR:::.mxo_lines_to_seg(list(off), 0L, 0L, cfg))
})
