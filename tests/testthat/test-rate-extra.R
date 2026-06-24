# Extra coverage for R/mxo_rate.R: validation, the search/mcts rating methods,
# the label classifier, and the medium/hard ai_move branches.

test_that("mxo_rate_moves and mxo_ai_move reject non-game inputs", {
  expect_error(mxo_rate_moves(list()), "must be an")
  expect_error(mxo_ai_move(list()), "must be an")
})

test_that(".mxo_label_for spans the full label ladder", {
  expect_true(is.na(multixoR:::.mxo_label_for(NA_real_)))
  expect_equal(multixoR:::.mxo_label_for(0.00), "best")
  expect_equal(multixoR:::.mxo_label_for(0.05), "strong")
  expect_equal(multixoR:::.mxo_label_for(0.15), "ok")
  expect_equal(multixoR:::.mxo_label_for(0.30), "weak")
  expect_equal(multixoR:::.mxo_label_for(0.90), "blunder")
})

test_that("rate_moves with method='search' returns the documented columns", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  rated <- mxo_rate_moves(g, method = "search", depth = 1L,
                          branch_policy = "none")
  expect_named(rated, c("kind", "L_src", "t_src", "idx", "player",
                        "score", "win_prob", "rank", "label"))
  expect_true(all(rated$win_prob >= 0 & rated$win_prob <= 1))
})

test_that("rate_moves with method='mcts' returns valid probabilities", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  set.seed(1L)
  rated <- mxo_rate_moves(g, method = "mcts", mcts_iter = 8L,
                          branch_policy = "none")
  expect_true(all(rated$win_prob >= 0 & rated$win_prob <= 1))
})

test_that("ai_move on a terminal game returns a zero-row tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_equal(nrow(mxo_ai_move(g, difficulty = "easy")), 0L)
})

test_that("ai_move hard difficulty (MCTS) returns a single legal move", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L)
  mv <- mxo_ai_move(g, difficulty = "hard", seed = 1L)
  expect_equal(nrow(mv), 1L)
})
