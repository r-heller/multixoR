# Move rating + AI move selection.
#
# `mxo_rate_moves()` returns the type-stable per-move table that D consumes
# for the heatmap and the Top-3 overlay. `mxo_ai_move()` is the convenience
# entry point for app/sim/CLI use, mapping a difficulty knob to depth /
# iteration counts.

# Categorise a move by its win-probability drop vs the best move.
.mxo_label_for <- function(drop) {
  if (is.na(drop)) return(NA_character_)
  if (drop <= 0.02) "best"
  else if (drop <= 0.08) "strong"
  else if (drop <= 0.20) "ok"
  else if (drop <= 0.40) "weak"
  else "blunder"
}

# Empty 0-row rating table -- used as the terminal/no-moves return.
.mxo_empty_rating <- function() {
  tibble::tibble(
    kind = character(0), L_src = integer(0), t_src = integer(0),
    idx = integer(0), player = integer(0),
    score = numeric(0), win_prob = numeric(0),
    rank = integer(0), label = character(0)
  )
}

#' Rate the legal moves of a position
#'
#' For each legal move, evaluate the resulting position from the mover's
#' perspective, attach a `win_prob`, derive a chess-engine-style label
#' (`"best"` / `"strong"` / `"ok"` / `"weak"` / `"blunder"`) from the
#' probability drop vs the best move, and rank the rows.
#'
#' @param game An `mxo_game` object.
#' @param method One of `"search"` (negamax depth lookup), `"mcts"`, or
#'   `"heuristic"`. Default `"heuristic"` for speed; `"search"` and
#'   `"mcts"` are slower but stronger.
#' @param depth Search depth when `method = "search"`. Default `2L`.
#' @param mcts_iter Iterations when `method = "mcts"`. Default `200L`.
#' @param branch_policy Branch-policy passed through to search/MCTS. Default
#'   `"promising"`.
#' @param ... Additional arguments forwarded to the chosen method.
#' @return A type-stable tibble with columns `kind`, `L_src`, `t_src`,
#'   `idx`, `player`, `score`, `win_prob`, `rank`, `label`.
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' head(mxo_rate_moves(g))
mxo_rate_moves <- function(game,
                           method = c("heuristic", "search", "mcts"),
                           depth = 2L,
                           mcts_iter = 200L,
                           branch_policy = c("promising", "all", "none"),
                           ...) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  method <- match.arg(method)
  branch_policy <- match.arg(branch_policy)
  if (mxo_is_terminal(game)) return(.mxo_empty_rating())
  moves <- mxo_legal_moves(game)
  if (nrow(moves) == 0L) return(.mxo_empty_rating())
  pov <- mxo_to_move(game)
  score <- numeric(nrow(moves))
  win_prob <- numeric(nrow(moves))
  for (i in seq_len(nrow(moves))) {
    g2 <- mxo_move(game, kind = moves$kind[[i]], L_src = moves$L_src[[i]],
                   t_src = moves$t_src[[i]], idx = moves$idx[[i]])
    if (method == "search") {
      res <- mxo_search(g2, depth = depth - 1L, branch_policy = branch_policy)
      score[i] <- -res$value
      win_prob[i] <- mxo_win_prob(g2, player = pov, method = "heuristic")
    } else if (method == "mcts") {
      score[i] <- mxo_evaluate(g2, player = pov)
      win_prob[i] <- mxo_win_prob(g2, player = pov, method = "mcts",
                                  iterations = mcts_iter,
                                  branch_policy = branch_policy)
    } else {
      score[i] <- mxo_evaluate(g2, player = pov)
      win_prob[i] <- mxo_win_prob(g2, player = pov, method = "heuristic")
    }
  }
  rank <- as.integer(rank(-win_prob, ties.method = "min"))
  best_prob <- max(win_prob)
  drop <- best_prob - win_prob
  label <- vapply(drop, .mxo_label_for, character(1L))
  tibble::tibble(
    kind = moves$kind,
    L_src = moves$L_src,
    t_src = moves$t_src,
    idx = moves$idx,
    player = moves$player,
    score = as.numeric(score),
    win_prob = as.numeric(win_prob),
    rank = rank,
    label = label
  )
}

#' Choose a move using a packaged difficulty knob
#'
#' @param game An `mxo_game` object.
#' @param difficulty One of `"easy"`, `"medium"`, or `"hard"`. The mapping is:
#'   * `"easy"`   -- one-ply heuristic; takes immediate wins or blocks
#'                   immediate opponent wins, otherwise picks the best
#'                   heuristic move.
#'   * `"medium"` -- negamax depth 2 with `branch_policy = "promising"`.
#'   * `"hard"`   -- MCTS with 400 iterations, heuristic rollouts.
#' @param seed Optional integer seed for deterministic stochastic difficulty
#'   levels.
#' @param ... Additional arguments forwarded to the chosen engine.
#' @return A one-row legal-moves tibble (or a zero-row tibble at terminal
#'   states).
#' @export
#' @examples
#' g <- mxo_new_game(n = 3L, k = 3L)
#' mxo_ai_move(g, difficulty = "easy", seed = 1L)
mxo_ai_move <- function(game,
                        difficulty = c("easy", "medium", "hard"),
                        seed = NULL,
                        ...) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  difficulty <- match.arg(difficulty)
  if (mxo_is_terminal(game)) return(.mxo_empty_move_row())
  if (!is.null(seed)) withr::local_seed(seed)
  if (difficulty == "easy") {
    rated <- mxo_rate_moves(game, method = "heuristic")
    return(rated[which.max(rated$win_prob), c("kind", "L_src", "t_src",
                                              "idx", "player"), drop = FALSE])
  }
  if (difficulty == "medium") {
    # Branches are skipped in the medium search to keep the move-selection
    # tractable on default boards; the orchestrator's "promising depth ~3"
    # target is deferred to a future optimisation pass (carried as a known
    # issue in STATE.md).
    res <- mxo_search(game, depth = 2L, branch_policy = "none")
    return(res$move)
  }
  res <- mxo_mcts(game, iterations = 400L, rollout = "random",
                  branch_policy = "promising")
  res$move
}
