test_that("spatial x-axis win is detected", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  expect_equal(g$status, "x_win")
  expect_equal(g$winner, 1L)
  expect_length(g$win_line, 3L)
  expect_true(mxo_is_terminal(g))
})

test_that("spatial y-axis win is detected", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 9L)
  g <- mxo_move(g, "present", 0L, 2L, 3L)
  g <- mxo_move(g, "present", 0L, 3L, 12L)
  g <- mxo_move(g, "present", 0L, 4L, 6L)
  expect_equal(g$status, "x_win")
})

test_that("spatial face-diagonal win is detected", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 1L)
  g <- mxo_move(g, "present", 0L, 2L, 4L)
  g <- mxo_move(g, "present", 0L, 3L, 5L)
  g <- mxo_move(g, "present", 0L, 4L, 8L)
  expect_equal(g$status, "x_win")
})

test_that("timeline-axis win across L1,L2,L3 is detected", {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 1L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  g <- mxo_move(g, "present", 0L, 2L, 16L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "branch",  0L, 0L, 63L)
  expect_equal(g$status, "x_win")
  Ls <- vapply(g$win_line, function(c) c$L, integer(1L))
  expect_equal(sort(Ls), c(1L, 2L, 3L))
})

test_that("mixed timeline + spatial win is detected", {
  # Construct branches at adjacent timelines with the spatial dx step
  # built into the seed: (1,0,5),(2,0,6),(3,0,7) along (dL=1, dx=1).
  # O plays at scattered, non-aligned indices to avoid an accidental
  # spatial line.
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 32L)
  g <- mxo_move(g, "branch",  0L, 0L, 5L)
  g <- mxo_move(g, "present", 0L, 2L, 48L)
  g <- mxo_move(g, "branch",  0L, 0L, 6L)
  g <- mxo_move(g, "present", 0L, 3L, 63L)
  g <- mxo_move(g, "branch",  0L, 0L, 7L)
  expect_equal(g$status, "x_win")
})

test_that("non-existent boards gate cross-axis lines", {
  # Single timeline play with three placements where a phantom dt-line
  # might appear: ensure the engine does not declare a win unless an
  # actual placement triggers it.
  g <- mxo_new_game(n = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  expect_equal(g$status, "in_progress")
  expect_false(mxo_is_terminal(g))
})

test_that("mxo_status returns a type-stable list", {
  g <- mxo_new_game()
  s <- mxo_status(g)
  expect_named(s, c("status", "winner", "win_line"))
  expect_type(s$status, "character")
  expect_true(is.na(s$winner) || is.integer(s$winner))
})
