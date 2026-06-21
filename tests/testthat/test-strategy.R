test_that("opening_table covers all spatial start cells", {
  cfg <- mxo_config_default(n = 3L, k = 3L, ply_cap = 6L)
  tab <- mxo_opening_table(
    opponent = mxo_policy("random"),
    n_games_per_cell = 2L,
    config = cfg,
    seed = 1L
  )
  expect_equal(nrow(tab), 27L)
  expect_true(all(tab$x_win_rate >= 0 & tab$x_win_rate <= 1))
  expect_true(all(tab$o_win_rate >= 0 & tab$o_win_rate <= 1))
  expect_true(all(tab$draw_rate >= 0 & tab$draw_rate <= 1))
})

test_that("timeline_win_rate returns the §12 stress-test number", {
  out <- mxo_timeline_win_rate(
    mxo_policy("random", branch_policy = "all"),
    mxo_policy("random", branch_policy = "all"),
    n_games = 6L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 1L
  )
  expect_named(out, c("n_games", "n_wins", "cross_timeline_wins",
                      "cross_timeline_fraction",
                      "spatial", "time", "timeline", "mixed"))
  expect_true(is.na(out$cross_timeline_fraction) ||
              (out$cross_timeline_fraction >= 0 &&
               out$cross_timeline_fraction <= 1))
})

test_that("policy tournament produces a typed pair table with ranking", {
  pols <- list(
    r = mxo_policy("random", branch_policy = "all"),
    h = mxo_policy("heuristic", branch_policy = "none")
  )
  tab <- mxo_policy_tournament(
    pols, n_games = 2L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L
  )
  expect_true(all(c("x_policy", "o_policy", "x_win_rate", "o_win_rate")
                  %in% names(tab)))
  rk <- attr(tab, "ranking")
  expect_s3_class(rk, "tbl_df")
  expect_equal(sort(rk$policy), sort(names(pols)))
})

test_that("branch_study spans the three policies", {
  factory <- function(bp) mxo_policy("random", branch_policy = bp)
  res <- mxo_branch_study(
    factory, n_games = 2L,
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L
  )
  expect_equal(sort(res$branch_policy), c("all", "none", "promising"))
})
