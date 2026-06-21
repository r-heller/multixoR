test_that("negamax finds a win-in-1 with depth 1", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 25L)
  res <- mxo_search(g, depth = 1L, branch_policy = "none")
  expect_equal(res$move$idx, 2L)
  expect_gt(res$value, 1e5)
})

test_that("search returns a type-stable list including a 1-row move tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  res <- mxo_search(g, depth = 1L, branch_policy = "none")
  expect_named(res, c("value", "move"))
  expect_type(res$value, "double")
  expect_s3_class(res$move, "tbl_df")
  expect_equal(nrow(res$move), 1L)
})

test_that("search on a terminal game returns a 0-row move tibble", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 16L)
  g <- mxo_move(g, "present", 0L, 2L, 1L)
  g <- mxo_move(g, "present", 0L, 3L, 17L)
  g <- mxo_move(g, "present", 0L, 4L, 2L)
  res <- mxo_search(g, depth = 1L)
  expect_equal(nrow(res$move), 0L)
})

test_that("branch_policy='none' drops branch moves", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  filtered <- multixoR:::.mxo_filter_legal_moves(g, "none")
  expect_true(all(filtered$kind == "present"))
})

test_that("branch_policy='promising' is a subset of 'all'", {
  g <- mxo_new_game(n = 3L, k = 3L)
  g <- mxo_move(g, "present", 0L, 0L, 0L)
  g <- mxo_move(g, "present", 0L, 1L, 26L)
  all_m <- multixoR:::.mxo_filter_legal_moves(g, "all")
  prom <- multixoR:::.mxo_filter_legal_moves(g, "promising")
  expect_lte(nrow(prom), nrow(all_m))
})
