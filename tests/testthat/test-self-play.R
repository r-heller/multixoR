test_that("self-play yields a valid outcome and history", {
  rec <- mxo_self_play(
    mxo_policy("random", branch_policy = "all"),
    mxo_policy("random", branch_policy = "all"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 8L),
    seed = 1L,
    record_eval = FALSE
  )
  expect_s3_class(rec, "mxo_game_record")
  expect_true(rec$outcome %in% c("x_win", "o_win", "draw"))
  expect_equal(rec$n_plies, nrow(rec$history))
  expect_true(rec$n_timelines >= 1L)
})

test_that("self-play records per-ply eval when requested", {
  rec <- mxo_self_play(
    mxo_policy("random"),
    mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 2L,
    record_eval = TRUE
  )
  expect_equal(length(rec$evals), rec$n_plies)
  expect_equal(length(rec$win_probs), rec$n_plies)
})

test_that("as_tibble.mxo_game_record returns one row per ply", {
  rec <- mxo_self_play(
    mxo_policy("random"),
    mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 6L),
    seed = 3L,
    record_eval = FALSE
  )
  tb <- as_tibble.mxo_game_record(rec)
  expect_equal(nrow(tb), rec$n_plies)
  expect_true(all(c("ply", "player", "kind", "idx", "eval", "win_prob")
                  %in% names(tb)))
})

test_that("self-play print method runs", {
  rec <- mxo_self_play(
    mxo_policy("random"),
    mxo_policy("random"),
    config = mxo_config_default(n = 3L, k = 3L, ply_cap = 4L),
    seed = 1L, record_eval = FALSE
  )
  expect_invisible(print(rec))
})

test_that("a forced timeline-win sequence flags cross_timeline_win", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 1L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  g <- mxo_move(g, "present", 0L, 2L, 16L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  expect_equal(g$status, "x_win")
  cls <- multixoR:::.mxo_classify_win_line(g$win_line)
  expect_equal(cls, "timeline")
})
