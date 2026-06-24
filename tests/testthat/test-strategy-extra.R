# Extra coverage for R/mxo_strategy.R and R/mxo_simulate.R guards.

test_that("mxo_opening_table rejects a non-policy opponent", {
  expect_error(
    mxo_opening_table(opponent = list(),
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L)),
    "must be an"
  )
})

test_that("mxo_policy_tournament rejects an unnamed policy list", {
  expect_error(
    mxo_policy_tournament(list(mxo_policy("random"), mxo_policy("random"))),
    "named list"
  )
})

test_that("mxo_branch_study rejects a non-function factory", {
  expect_error(mxo_branch_study(policy_factory = 42L), "must be a function")
})

test_that("mxo_simulate rejects a negative n_games", {
  expect_error(
    mxo_simulate(mxo_policy("random"), mxo_policy("random"), n_games = -1L,
                 progress = FALSE),
    "non-negative integer"
  )
})

test_that("summary of a zero-game simulation returns NA diagnostics", {
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 0L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
                      progress = FALSE)
  s <- summary(sim)
  expect_equal(s$n_games, 0L)
  expect_true(is.na(s$x_win_rate))
  expect_true(is.na(s$cross_timeline_win_fraction))
})

test_that("mxo_simulate with a progress bar runs to completion", {
  withr::local_options(cli.num_colors = 1L)
  sim <- mxo_simulate(mxo_policy("random"), mxo_policy("random"),
                      n_games = 2L,
                      config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
                      seed = 1L, record_eval = FALSE, progress = TRUE)
  expect_equal(nrow(sim$games), 2L)
})

test_that(".mxo_classify_win_line returns NA for a degenerate line", {
  expect_true(is.na(multixoR:::.mxo_classify_win_line(NULL)))
  expect_true(is.na(multixoR:::.mxo_classify_win_line(list(list(L = 0L, t = 0L, idx = 0L)))))
})
