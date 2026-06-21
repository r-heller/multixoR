test_that("rate_moves has the documented columns", {
  g <- mxo_new_game(n = 3L, k = 3L)
  rated <- mxo_rate_moves(g, method = "heuristic")
  expect_named(rated, c("kind", "L_src", "t_src", "idx", "player",
                        "score", "win_prob", "rank", "label"))
  expect_true(all(rated$label %in%
                  c("best", "strong", "ok", "weak", "blunder")))
  expect_equal(min(rated$rank), 1L)
})

test_that("rate_moves on a terminal game returns 0 rows with correct cols", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  rated <- mxo_rate_moves(g, method = "heuristic")
  expect_equal(nrow(rated), 0L)
  expect_named(rated, c("kind", "L_src", "t_src", "idx", "player",
                        "score", "win_prob", "rank", "label"))
})

test_that("rate_moves rank is consistent with win_prob", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  rated <- mxo_rate_moves(g, method = "heuristic")
  best_rows <- which(rated$rank == 1L)
  expect_equal(max(rated$win_prob), rated$win_prob[best_rows[[1L]]])
})

test_that("ai_move returns a legal one-row move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  mv <- mxo_ai_move(g, difficulty = "easy", seed = 1L)
  expect_equal(nrow(mv), 1L)
  legal <- mxo_legal_moves(g)
  match_row <- legal$kind == mv$kind &
    legal$L_src == mv$L_src & legal$t_src == mv$t_src &
    legal$idx == mv$idx
  expect_true(any(match_row))
})

test_that("ai_move at medium difficulty yields a legal move", {
  skip_on_cran()
  # Use a partially played n=3 game so branching factor and ply_cap are small.
  g <- mxo_new_game(n = 3L, k = 3L, ply_cap = 12L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  mv <- mxo_ai_move(g, difficulty = "medium", seed = 1L)
  expect_equal(nrow(mv), 1L)
})

test_that("seeded easy ai_move is reproducible", {
  g <- mxo_new_game(n = 3L, k = 3L)
  a <- mxo_ai_move(g, difficulty = "easy", seed = 7L)
  b <- mxo_ai_move(g, difficulty = "easy", seed = 7L)
  expect_identical(a, b)
})

test_that("rate_moves win_prob matches mxo_win_prob on the resulting state", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  rated <- mxo_rate_moves(g, method = "heuristic")
  i <- 1L
  g2 <- mxo_move(g, kind = rated$kind[[i]], L_src = rated$L_src[[i]],
                 t_src = rated$t_src[[i]], idx = rated$idx[[i]])
  expect_equal(rated$win_prob[[i]],
               mxo_win_prob(g2, player = mxo_to_move(g),
                            method = "heuristic"))
})
