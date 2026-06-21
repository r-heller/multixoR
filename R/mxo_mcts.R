# Light UCT MCTS. Tree nodes live in an environment keyed by integer id; each
# selection step descends along UCB1, expands one child per iteration, runs a
# rollout to terminal (or to `rollout_depth`), and backs the value up the path
# negating the perspective at each level.

# Run a rollout from `game` to terminal (or `rollout_depth`) and return the
# rollout value in [-1, 1] from the perspective of the *initial* player to
# move.
.mxo_rollout <- function(game, rollout, branch_policy, rollout_depth, epsilon) {
  pov <- mxo_to_move(game)
  g <- game
  steps <- 0L
  while (!mxo_is_terminal(g) && steps < rollout_depth) {
    moves <- .mxo_filter_legal_moves(g, branch_policy)
    if (nrow(moves) == 0L) break
    i <- if (rollout == "heuristic" && stats::runif(1L) < epsilon) {
      scores <- vapply(seq_len(nrow(moves)), function(j) {
        g2 <- mxo_move(g, kind = moves$kind[[j]],
                       L_src = moves$L_src[[j]],
                       t_src = moves$t_src[[j]],
                       idx = moves$idx[[j]])
        -mxo_evaluate(g2, player = mxo_to_move(g2))
      }, numeric(1L))
      which.max(scores)
    } else {
      sample.int(nrow(moves), 1L)
    }
    g <- mxo_move(g, kind = moves$kind[[i]],
                  L_src = moves$L_src[[i]],
                  t_src = moves$t_src[[i]],
                  idx = moves$idx[[i]])
    steps <- steps + 1L
  }
  if (mxo_is_terminal(g)) {
    if (g$status == "draw") return(0)
    if (identical(g$winner, pov)) return(1)
    return(-1)
  }
  # Non-terminal: squash the heuristic to (-1, 1).
  tanh(mxo_evaluate(g, player = pov) / 100)
}

#' Light UCT Monte-Carlo Tree Search
#'
#' Runs `iterations` MCTS playouts (or stops earlier when `time_budget` is
#' exceeded) and returns a per-root-move summary.
#'
#' @param game An `mxo_game` object.
#' @param iterations Integer scalar, maximum MCTS iterations. Default `1000L`.
#' @param c_uct Exploration constant. Default `1.4`.
#' @param rollout One of `"heuristic"` (default, epsilon-greedy over a 1-ply
#'   evaluator) or `"random"` (uniform legal).
#' @param branch_policy One of `"promising"` (default), `"all"`, `"none"`.
#'   See [mxo_search()] for the trade-off.
#' @param time_budget Optional numeric. If supplied, stops once the elapsed
#'   wall time exceeds this many seconds.
#' @param rollout_depth Maximum rollout depth in plies. Defaults to the
#'   game's `ply_cap`.
#' @param epsilon Probability of taking the greedy move during a heuristic
#'   rollout. Default `0.7`.
#' @param seed Optional integer seed for reproducible runs.
#' @return An object of class `mxo_mcts_result`.
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' set.seed(1)
#' res <- mxo_mcts(g, iterations = 50L, branch_policy = "none")
#' res$move
mxo_mcts <- function(game,
                     iterations = 1000L,
                     c_uct = 1.4,
                     rollout = c("heuristic", "random"),
                     branch_policy = c("promising", "all", "none"),
                     time_budget = NULL,
                     rollout_depth = NULL,
                     epsilon = 0.7,
                     seed = NULL) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  rollout <- match.arg(rollout)
  branch_policy <- match.arg(branch_policy)
  if (!is.null(seed)) withr::local_seed(seed)
  if (is.null(rollout_depth)) rollout_depth <- as.integer(game$config$ply_cap)
  rollout_depth <- as.integer(rollout_depth)
  tree <- new.env(parent = emptyenv())
  next_id <- 1L
  make_node <- function(game_state, parent_id) {
    moves <- .mxo_filter_legal_moves(game_state, branch_policy)
    terminal <- mxo_is_terminal(game_state)
    terminal_value <- if (terminal) {
      if (game_state$status == "draw") 0
      else if (identical(game_state$winner, mxo_to_move(game_state))) 1
      else -1
    } else NA_real_
    node <- list(
      id = next_id, parent_id = parent_id, game = game_state,
      moves = moves, child_ids = integer(nrow(moves)),
      N = 0L, W = 0, terminal = terminal,
      terminal_value = terminal_value
    )
    assign(as.character(next_id), node, envir = tree)
    id <- next_id
    next_id <<- next_id + 1L
    id
  }
  root_id <- make_node(game, NA_integer_)
  do_iter <- function() {
    nid <- root_id
    path <- nid
    repeat {
      node <- get(as.character(nid), envir = tree)
      if (node$terminal) break
      if (nrow(node$moves) == 0L) break
      unexp <- which(node$child_ids == 0L)
      if (length(unexp) > 0L) {
        i <- if (length(unexp) == 1L) unexp else sample(unexp, 1L)
        mv <- node$moves[i, ]
        g_new <- mxo_move(node$game, kind = mv$kind, L_src = mv$L_src,
                          t_src = mv$t_src, idx = mv$idx)
        new_id <- make_node(g_new, nid)
        node$child_ids[i] <- new_id
        assign(as.character(nid), node, envir = tree)
        nid <- new_id
        path <- c(path, nid)
        break
      }
      child_scores <- vapply(node$child_ids, function(cid) {
        c <- get(as.character(cid), envir = tree)
        q <- if (c$N == 0L) 0 else c$W / c$N
        u <- c_uct * sqrt(log(node$N + 1L) / max(c$N, 1L))
        -q + u
      }, numeric(1L))
      i <- which.max(child_scores)
      nid <- node$child_ids[i]
      path <- c(path, nid)
    }
    leaf <- get(as.character(nid), envir = tree)
    rollout_value <- if (leaf$terminal) {
      leaf$terminal_value
    } else {
      .mxo_rollout(leaf$game, rollout, branch_policy, rollout_depth, epsilon)
    }
    val <- rollout_value
    for (i in rev(seq_along(path))) {
      pid <- path[i]
      pnode <- get(as.character(pid), envir = tree)
      pnode$N <- pnode$N + 1L
      pnode$W <- pnode$W + val
      assign(as.character(pid), pnode, envir = tree)
      val <- -val
    }
  }
  start_time <- Sys.time()
  n_iter <- 0L
  for (it in seq_len(iterations)) {
    do_iter()
    n_iter <- n_iter + 1L
    if (!is.null(time_budget) &&
        as.numeric(Sys.time() - start_time, units = "secs") > time_budget) break
  }
  root <- get(as.character(root_id), envir = tree)
  elapsed <- as.numeric(Sys.time() - start_time, units = "secs")
  if (nrow(root$moves) == 0L) {
    return(structure(list(
      move = .mxo_empty_move_row(),
      moves = root$moves,
      visits = integer(0L),
      values = numeric(0L),
      n_iter = n_iter, elapsed = elapsed
    ), class = "mxo_mcts_result"))
  }
  visits <- vapply(root$child_ids, function(cid) {
    if (cid == 0L) 0L
    else as.integer(get(as.character(cid), envir = tree)$N)
  }, integer(1L))
  values <- vapply(root$child_ids, function(cid) {
    if (cid == 0L) return(0)
    c <- get(as.character(cid), envir = tree)
    if (c$N == 0L) 0 else -c$W / c$N
  }, numeric(1L))
  best_i <- which.max(visits)
  structure(list(
    move = root$moves[best_i, , drop = FALSE],
    moves = root$moves,
    visits = visits,
    values = values,
    n_iter = as.integer(n_iter),
    elapsed = elapsed
  ), class = "mxo_mcts_result")
}

#' Print an `mxo_mcts_result`
#'
#' @param x An `mxo_mcts_result` object.
#' @param top Integer scalar, number of top-visited moves to display.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.mxo_mcts_result <- function(x, top = 5L, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("MCTS result")
  cli::cli_alert_info(
    "Iterations: {x$n_iter} (elapsed {round(x$elapsed, 2L)}s)"
  )
  if (nrow(x$moves) == 0L) {
    cli::cli_alert_info("Terminal -- no move.")
    return(invisible(x))
  }
  ord <- order(-x$visits)
  show <- utils::head(ord, top)
  for (i in show) {
    cli::cli_alert(c(
      "{x$moves$kind[i]} L{x$moves$L_src[i]} t{x$moves$t_src[i]} ",
      "idx{x$moves$idx[i]}: N={x$visits[i]}, Q={round(x$values[i], 3L)}"
    ))
  }
  invisible(x)
}
