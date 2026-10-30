test_that("hard AI forwards requested engine limits including NULL", {
  g <- mxo_new_game(n=3L,k=3L)
  observed <- NULL
  local_mocked_bindings(mxo_mcts = function(game, ...) {
    observed <<- list(...)
    list(move=mxo_legal_moves(game)[1, , drop=FALSE])
  })
  move <- mxo_ai_move(g, "hard", iterations=7L, rollout_depth=2L, time_budget=NULL)
  expect_equal(nrow(move),1L)
  expect_identical(observed$iterations,7L)
  expect_identical(observed$rollout_depth,2L)
  expect_true("time_budget" %in% names(observed))
  expect_null(observed$time_budget)
  expect_error(mxo_ai_move(g,"hard", NULL, 7L), "unique names")
})

test_that("expired rollouts do not continue consuming moves", {
  g <- mxo_new_game(n=3L,k=3L)
  local_mocked_bindings(.mxo_filter_legal_moves=function(...) stop("unexpected move generation"))
  value <- multixoR:::.mxo_rollout(g,"random","all",100L,0.7,expired=function() TRUE)
  expect_true(is.finite(value))
})

test_that("bounded MCTS returns legal moves and validates its limits", {
  g <- mxo_new_game(n=3L,k=3L)
  res <- mxo_mcts(g,iterations=1000L,time_budget=0.02,rollout="random",branch_policy="none",seed=2L)
  expect_lt(res$n_iter,1000L)
  expect_equal(nrow(res$move),1L)
  expect_true(res$move$idx %in% mxo_legal_moves(g)$idx)
  for (bad in list(0,-1,NA_real_,Inf,1.5)) expect_error(mxo_mcts(g,iterations=bad),"iterations")
  for (bad in list(0,-1,NA_real_,Inf)) expect_error(mxo_mcts(g,time_budget=bad),"time_budget")
  expect_error(mxo_mcts(g,epsilon=1.1),"epsilon")
})


test_that("MCTS ratings forward rollout and time limits for every legal move", {
  g <- mxo_new_game(n=3L,k=3L)
  seen <- list()
  local_mocked_bindings(mxo_win_prob = function(game, player, method, ...) {
    seen[[length(seen)+1L]] <<- list(...)
    0.5
  })
  rated <- mxo_rate_moves(g, method="mcts", mcts_iter=3L, rollout_depth=1L,time_budget=0.1)
  expect_equal(length(seen),nrow(mxo_legal_moves(g)))
  expect_equal(nrow(rated),length(seen))
  expect_true(all(vapply(seen,function(x) identical(x$iterations,3L) && identical(x$rollout,"random") && identical(x$rollout_depth,1L) && identical(x$time_budget,0.1),logical(1))))
})
test_that("search ratings rank search scores without invented probability labels", {
  g <- mxo_new_game(n = 3L, k = 3L)
  testthat::local_mocked_bindings(
    mxo_search = function(game, ...) list(value = -game$history[[length(game$history)]]$idx),
    mxo_win_prob = function(...) 0.5
  )
  ratings <- mxo_rate_moves(g, method = "search", depth = 1L)
  expect_equal(ratings$rank, as.integer(rank(-ratings$score, ties.method = "min")))
  expect_gt(length(unique(ratings$rank)), 1L)
  expect_true(all(is.na(ratings$label)))
  expect_equal(ratings$win_prob, rep(0.5, nrow(ratings)))
})

test_that("search depth cannot be truncated or missing", {
  g <- mxo_new_game(n = 3L, k = 3L)
  for (bad in list(NA_real_, Inf, 1.5, numeric(), c(1, 2), "2", 1e100)) {
    expect_error(mxo_search(g, depth = bad), "non-negative integer")
    expect_error(mxo_rate_moves(g, method = "search", depth = bad), "positive integer")
  }
  expect_error(mxo_rate_moves(g, method = "search", depth = 0), "positive integer")
})

