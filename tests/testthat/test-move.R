test_that("mxo_legal_moves is type-stable and includes 64 present moves at start", {
  g <- mxo_new_game()
  moves <- mxo_legal_moves(g)
  expect_s3_class(moves, "tbl_df")
  expect_named(moves, c("kind", "L_src", "t_src", "idx", "player"))
  expect_equal(nrow(moves), 64L)
  expect_true(all(moves$kind == "present"))
  expect_true(all(moves$player == 1L))
})

test_that("present move advances present_t and flips to_move", {
  g <- mxo_new_game()
  g2 <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_equal(mxo_to_move(g2), 2L)
  expect_equal(g2$timelines[["0"]]$present_t, 1L)
  expect_equal(g2$boards[["0:0"]][1L], 1L)
  expect_equal(g2$boards[["0:1"]][1L], 1L)
})

test_that("branch creates a new timeline and does not mutate the source", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  src_before <- g$boards[["0:0"]]
  g2 <- mxo_move(g, "branch", 0L, 0L, 63L)
  expect_identical(g2$boards[["0:0"]], src_before)
  expect_true("1:0" %in% names(g2$boards))
  expect_equal(g2$boards[["1:0"]][64L], 1L)
  expect_equal(g2$timelines[["1"]]$parent, 0L)
  expect_equal(g2$timelines[["1"]]$branch_t, 0L)
  expect_equal(g2$timelines[["1"]]$present_t, 0L)
})

test_that("branching into an occupied past cell errors", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 5L)
  expect_snapshot(
    mxo_move(g, "branch", 0L, 0L, 0L),
    error = TRUE
  )
})

test_that("branching the present (non-past) board errors", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  expect_snapshot(
    mxo_move(g, "branch", 0L, 1L, 0L),
    error = TRUE
  )
})

test_that("playing on a terminal game errors", {
  g <- mxo_new_game(n = 3L, d_spatial = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_equal(g$status, "x_win")
  expect_error(mxo_move(g, "present", 0L, 5L, 4L), "already over")
})

test_that("exceeding max_timelines errors", {
  g <- mxo_new_game(max_timelines = 2L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 5L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  expect_snapshot(
    mxo_move(g, "branch", 0L, 0L, 62L),
    error = TRUE
  )
})

test_that("legal_moves on a terminal game is a 0-row typed tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  m <- mxo_legal_moves(g)
  expect_equal(nrow(m), 0L)
  expect_named(m, c("kind", "L_src", "t_src", "idx", "player"))
})

test_that("immutability: no board key is ever rewritten by present moves", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  pre_keys <- names(g$boards)
  pre_state <- g$boards[pre_keys]
  g <- mxo_move(g, "present", 0L, 1L, 5L)
  for (k in pre_keys[pre_keys != "0:1"]) {
    expect_identical(g$boards[[k]], pre_state[[k]])
  }
})

test_that("ply_cap turns the game into a draw", {
  g <- mxo_new_game(n = 4L, ply_cap = 4L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 3L)
  g <- mxo_move(g, "branch",  0L, 0L, 5L)
  g <- mxo_move(g, "branch",  0L, 0L, 7L)
  expect_equal(g$status, "draw")
})

test_that("undo + replay round-trips", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  g_undo <- mxo_undo(g, 1L)
  expect_length(g_undo$history, 2L)
  g_replay <- mxo_replay(g$history, g$config)
  expect_identical(g_replay$boards, g$boards)
  expect_identical(g_replay$timelines, g$timelines)
  expect_identical(g_replay$to_move, g$to_move)
})

test_that("mxo_play accepts one row of mxo_legal_moves output", {
  g <- mxo_new_game()
  mv <- mxo_legal_moves(g)[1L, ]
  g2 <- mxo_play(g, mv)
  expect_equal(mxo_to_move(g2), 2L)
})
