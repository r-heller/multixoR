player_validation_games <- function() {
  active <- mxo_new_game(n = 3L, k = 3L)
  active <- mxo_move(active, "present", 0L, 0L, 0L)
  won <- mxo_new_game(n = 3L, k = 3L)
  moves <- c(0L, 16L, 1L, 17L, 2L)
  for (i in seq_along(moves)) {
    won <- mxo_move(won, "present", 0L, i - 1L, moves[i])
  }
  draw <- mxo_new_game(n = 3L, k = 3L, ply_cap = 1L)
  draw <- mxo_move(draw, "present", 0L, 0L, 0L)
  list(active = active, won = won, draw = draw)
}

test_that("both APIs reject invalid players before active or terminal evaluation", {
  games <- player_validation_games()
  expect_identical(games$active$status, "in_progress")
  expect_identical(games$won$status, "x_win")
  expect_identical(games$draw$status, "draw")
  invalid <- list(1.9, 2.1, 0L, 3L, -1L, NA_integer_, NA_real_, NaN,
                  Inf, -Inf, NULL, numeric(), c(1L, 2L), "1", TRUE,
                  factor("1"), list(1L), 1 + 0i, matrix(1L), array(2L, c(1, 1, 1)))
  for (game in games) {
    for (player in invalid) {
      expect_error(mxo_evaluate(game, player), "player.*numeric scalar")
      expect_error(mxo_win_prob(game, player, method = "heuristic"),
                   "player.*numeric scalar")
      # No MCTS work should be needed to reject a malformed perspective.
      expect_error(mxo_win_prob(game, player, method = "mcts"),
                   "player.*numeric scalar")
    }
  }
})

test_that("integer and numeric player perspectives retain their valid results", {
  games <- player_validation_games()
  for (game in games) {
    for (player in c(1L, 2L)) {
      for (valid in list(as.double(player), setNames(player, "perspective"))) {
        expect_identical(mxo_evaluate(game, valid), mxo_evaluate(game, player))
        expect_identical(mxo_win_prob(game, valid, method = "heuristic"),
                         mxo_win_prob(game, player, method = "heuristic"))
      }
    }
  }
  expect_identical(mxo_evaluate(games$draw, 1), 0)
  expect_identical(mxo_win_prob(games$won, 1, method = "mcts"), 1)
  expect_identical(mxo_win_prob(games$won, 2, method = "mcts"), 0)
  expect_identical(mxo_win_prob(games$draw, 2, method = "mcts"), 0.5)
  # Small fixed-work search also checks both accepted numeric representations.
  mcts <- function(player) mxo_win_prob(games$active, player, method = "mcts",
    iterations = 4L, branch_policy = "none", rollout = "random", seed = 123L)
  expect_identical(mcts(1), mcts(1L))
  expect_identical(mcts(2), mcts(2L))
  expect_equal(mcts(1L) + mcts(2L), 1)
})

test_that("an invalid stored default perspective is rejected explicitly", {
  for (game in player_validation_games()) {
    game$to_move <- NA_integer_
    expect_error(mxo_evaluate(game), "player.*numeric scalar")
    expect_error(mxo_win_prob(game, method = "heuristic"), "player.*numeric scalar")
    expect_error(mxo_win_prob(game, method = "mcts"), "player.*numeric scalar")
  }
})
