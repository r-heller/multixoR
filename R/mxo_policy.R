# Small policy abstraction: a closure carrying its parameters plus a thin
# wrapper around the Stack B searchers. Used by self-play, batch simulation,
# tournaments, and calibration.

#' Build a multixoR policy
#'
#' Returns an `mxo_policy` object: a parameterised strategy that, given a
#' game, picks one legal move. Thin wrapper over Stack B's searchers.
#'
#' @param type One of `"random"`, `"heuristic"`, `"negamax"`, `"mcts"`.
#' @param ... Named parameters forwarded to the underlying engine
#'   (`depth`, `branch_policy`, `iterations`, `time_budget`, ...).
#' @return An object of class `mxo_policy` with components `type`, `params`,
#'   `fn` (the move-picker).
#' @export
#' @examples
#' p <- mxo_policy("random")
#' p
mxo_policy <- function(type = c("random", "heuristic", "negamax", "mcts"), ...) {
  call <- rlang::current_env()
  type <- match.arg(type)
  params <- list(...)
  fn <- switch(
    type,
    random = function(game) {
      moves <- mxo_legal_moves(game)
      if (nrow(moves) == 0L) return(.mxo_empty_move_row())
      bp <- params$branch_policy %||% "all"
      moves <- .mxo_filter_legal_moves(game, bp)
      if (nrow(moves) == 0L) moves <- mxo_legal_moves(game)
      moves[sample.int(nrow(moves), 1L), , drop = FALSE]
    },
    heuristic = function(game) {
      moves <- mxo_legal_moves(game)
      if (nrow(moves) == 0L) return(.mxo_empty_move_row())
      bp <- params$branch_policy %||% "promising"
      moves <- .mxo_filter_legal_moves(game, bp)
      if (nrow(moves) == 0L) return(.mxo_empty_move_row())
      pov <- mxo_to_move(game)
      scores <- vapply(seq_len(nrow(moves)), function(i) {
        g2 <- mxo_move(game, kind = moves$kind[[i]],
                       L_src = moves$L_src[[i]],
                       t_src = moves$t_src[[i]],
                       idx = moves$idx[[i]])
        mxo_evaluate(g2, player = pov)
      }, numeric(1L))
      moves[which.max(scores), , drop = FALSE]
    },
    negamax = function(game) {
      depth <- params$depth %||% 2L
      bp <- params$branch_policy %||% "none"
      mxo_search(game, depth = depth, branch_policy = bp)$move
    },
    mcts = function(game) {
      iter <- params$iterations %||% 200L
      bp <- params$branch_policy %||% "promising"
      ro <- params$rollout %||% "random"
      tb <- params$time_budget
      mxo_mcts(game, iterations = iter, branch_policy = bp,
               rollout = ro, time_budget = tb)$move
    }
  )
  structure(list(type = type, params = params, fn = fn),
            class = "mxo_policy")
}

#' Test whether an object is a multixoR policy
#'
#' @param x An object.
#' @return Logical scalar.
#' @export
is_mxo_policy <- function(x) inherits(x, "mxo_policy")

#' Apply a policy to choose a move
#'
#' @param policy An `mxo_policy` object.
#' @param game An `mxo_game` object.
#' @return A one-row legal-moves tibble (or zero-row at terminal states).
#' @export
mxo_policy_move <- function(policy, game) {
  if (!is_mxo_policy(policy)) {
    cli::cli_abort(
      "{.arg policy} must be an {.cls mxo_policy} object.",
      call = rlang::current_env()
    )
  }
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  policy$fn(game)
}

#' Print a multixoR policy
#'
#' @param x An `mxo_policy`.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.mxo_policy <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("multixoR policy")
  cli::cli_alert_info("Type: {x$type}")
  if (length(x$params) > 0L) {
    cli::cli_alert_info("Params:")
    for (nm in names(x$params)) {
      cli::cli_alert("  {nm} = {format(x$params[[nm]])}")
    }
  }
  invisible(x)
}
