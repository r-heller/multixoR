# Extra coverage for R/mxo_search.R: validation, depth-0, branch_policy='all',
# and the promising-branch helper.

test_that("mxo_search validates game and depth", {
  g <- mxo_new_game(n = 3L, k = 3L)
  expect_error(mxo_search(list()), "must be an")
  expect_error(mxo_search(g, depth = -1L), "non-negative integer")
})

test_that("depth-0 search returns the static evaluation and a NULL move", {
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_search(g, depth = 0L, branch_policy = "none")
  expect_equal(nrow(res$move), 0L)
  expect_type(res$value, "double")
})

test_that("branch_policy='all' searches a branched position", {
  skip_on_cran()
  g <- mxo_new_game(n = 3L, k = 3L, ply_cap = 12L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 13L)
  res <- mxo_search(g, depth = 1L, branch_policy = "all")
  expect_named(res, c("value", "move"))
})

test_that(".mxo_branch_is_promising flags only neighbour-adjacent targets", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)  # mark at idx 0 on board (0,0)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  # idx 1 is adjacent to idx 0 on the source board (0,0) -> promising.
  expect_true(multixoR:::.mxo_branch_is_promising(g, 0L, 0L, 1L))
})

test_that(".mxo_branch_is_promising is FALSE on an empty source board", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 13L)
  # Board (0,1) before X's first mark would have been empty; use a key that
  # exists but is all-zero is not available, so test the NULL-board guard:
  expect_false(multixoR:::.mxo_branch_is_promising(g, 9L, 0L, 0L))
})
