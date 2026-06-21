# Negamax + alpha-beta search with a configurable branch-move policy.
#
# The multiverse explodes the branching factor: every empty cell of every past
# board is a potential branch move. `branch_policy` controls which branches
# survive into the search frontier:
#   * "all"        - exhaustive, the search is sound but extremely slow.
#   * "promising"  - only branches whose target has a neighbour mark within
#                    Chebyshev distance k-1 on the source board. Default.
#   * "none"       - drop all branches and search present moves only.

# Empty 0-row results — used as type-stable defaults.
.mxo_empty_move_row <- function() {
  tibble::tibble(
    kind = character(0), L_src = integer(0), t_src = integer(0),
    idx = integer(0), player = integer(0)
  )
}

# Branch-policy filter applied on top of `mxo_legal_moves()`.
.mxo_filter_legal_moves <- function(game, branch_policy) {
  moves <- mxo_legal_moves(game)
  if (nrow(moves) == 0L) return(moves)
  if (branch_policy == "all") return(moves)
  is_present <- moves$kind == "present"
  if (branch_policy == "none") return(moves[is_present, , drop = FALSE])
  # promising
  branch_pos <- which(!is_present)
  if (length(branch_pos) == 0L) return(moves)
  keep <- vapply(branch_pos, function(i) {
    .mxo_branch_is_promising(game, moves$L_src[[i]],
                             moves$t_src[[i]], moves$idx[[i]])
  }, logical(1L))
  moves[c(which(is_present), branch_pos[keep]), , drop = FALSE]
}

# A branch move is "promising" iff at least one spatial cell within Chebyshev
# distance k-1 of the target idx is occupied (either colour) on the source
# board. Cheap proxy for tactical interaction.
.mxo_branch_is_promising <- function(game, L_src, t_src, idx) {
  cfg <- game$config
  n <- cfg$n
  d_spatial <- cfg$d_spatial
  k <- cfg$k
  board <- game$boards[[.mxo_key(L_src, t_src)]]
  if (is.null(board)) return(FALSE)
  if (all(board == 0L)) return(FALSE)
  centre <- .mxo_idx_to_coord(idx, n, d_spatial)
  occ_idx <- which(board != 0L) - 1L
  for (oi in occ_idx) {
    coord <- .mxo_idx_to_coord(oi, n, d_spatial)
    if (max(abs(coord - centre)) <= (k - 1L)) return(TRUE)
  }
  FALSE
}

# Negamax: returns value from the perspective of the player to move at `game`.
.mxo_negamax <- function(game, depth, alpha, beta,
                         branch_policy, w_args) {
  if (mxo_is_terminal(game) || depth == 0L) {
    pov <- mxo_to_move(game)
    val <- mxo_evaluate(game, player = pov, w = w_args$w,
                        w_timeline = w_args$w_timeline,
                        terminal_score = w_args$terminal_score)
    return(list(value = val, best_move = NULL))
  }
  moves <- .mxo_filter_legal_moves(game, branch_policy)
  if (nrow(moves) == 0L) {
    pov <- mxo_to_move(game)
    val <- mxo_evaluate(game, player = pov, w = w_args$w,
                        w_timeline = w_args$w_timeline,
                        terminal_score = w_args$terminal_score)
    return(list(value = val, best_move = NULL))
  }
  # Move ordering disabled in v1.0 — a full one-ply pre-score doubles leaf
  # evaluations and dominates depth-2 search on small boards. Alpha-beta
  # still prunes; future versions may add a cheap heuristic order.
  best_value <- -Inf
  best_move <- NULL
  for (i in seq_len(nrow(moves))) {
    g2 <- mxo_move(game, kind = moves$kind[[i]],
                   L_src = moves$L_src[[i]],
                   t_src = moves$t_src[[i]],
                   idx = moves$idx[[i]])
    child <- .mxo_negamax(g2, depth - 1L, -beta, -alpha,
                          branch_policy, w_args)
    val <- -child$value
    if (val > best_value) {
      best_value <- val
      best_move <- moves[i, , drop = FALSE]
    }
    alpha <- max(alpha, val)
    if (alpha >= beta) break
  }
  list(value = best_value, best_move = best_move)
}

#' Negamax with alpha-beta pruning
#'
#' Searches `depth` plies deep under a configurable branch-move policy and
#' returns the best move found along with its negamax value.
#'
#' @param game An `mxo_game` object.
#' @param depth Integer scalar, search depth in plies. Default `3L`.
#' @param branch_policy One of `"promising"` (default), `"all"`, or `"none"`.
#' @param w Optional weight vector of length `k` (see [mxo_evaluate()]).
#' @param w_timeline Numeric multiplier for cross-timeline lines. Default `1`.
#' @param terminal_score Magnitude of terminal sentinel. Default `1e6`.
#' @return A type-stable list with components:
#'   * `value` (dbl): the negamax value from the mover's perspective.
#'   * `move` (tibble): the best move (one row in legal-moves form) or a
#'     zero-row tibble when the game is terminal.
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' res <- mxo_search(g, depth = 1L, branch_policy = "none")
#' res$value
mxo_search <- function(game, depth = 3L,
                       branch_policy = c("promising", "all", "none"),
                       w = NULL, w_timeline = 1, terminal_score = 1e6) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  branch_policy <- match.arg(branch_policy)
  depth <- as.integer(depth)
  if (is.na(depth) || depth < 0L) {
    cli::cli_abort("{.arg depth} must be a non-negative integer.", call = call)
  }
  w_args <- list(w = w, w_timeline = w_timeline,
                 terminal_score = terminal_score)
  res <- .mxo_negamax(game, depth, alpha = -Inf, beta = Inf,
                      branch_policy = branch_policy, w_args = w_args)
  move_tbl <- if (is.null(res$best_move)) .mxo_empty_move_row() else res$best_move
  list(value = res$value, move = move_tbl)
}
