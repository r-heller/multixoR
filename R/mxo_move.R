# Move generation, application, undo, and replay.
#
# Two kinds of move exist (rules §4):
#   * `"present"`: place on an empty cell of the present board of timeline
#     `L_src`. Advances `present_t` by 1.
#   * `"branch"`: place on an empty cell of a strictly historical board
#     `(L_src, t_src)`. Spawns a new timeline `L_new` whose present is the
#     source board plus the new mark, leaving `L_src` untouched.

# Empty-typed tibble used as the zero-row legal-moves result.
.mxo_empty_moves <- function() {
  tibble::tibble(
    kind   = character(0),
    L_src  = integer(0),
    t_src  = integer(0),
    idx    = integer(0),
    player = integer(0)
  )
}

#' Enumerate the legal moves of a game state
#'
#' @param game An `mxo_game` object.
#' @return A type-stable tibble with columns `kind` (chr), `L_src` (int),
#'   `t_src` (int), `idx` (int), and `player` (int, equal to `mxo_to_move()`).
#'   Always has these columns, including when the game is terminal (0 rows).
#' @export
#' @examples
#' g <- mxo_new_game()
#' nrow(mxo_legal_moves(g))
mxo_legal_moves <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  if (mxo_is_terminal(game)) return(.mxo_empty_moves())
  cfg <- game$config
  board_size <- as.integer(cfg$n ^ cfg$d_spatial)
  player <- game$to_move
  tl_labels <- .mxo_timeline_labels(game)
  present_kind <- character(0)
  present_L <- integer(0)
  present_t <- integer(0)
  present_idx <- integer(0)
  branch_kind <- character(0)
  branch_L <- integer(0)
  branch_t <- integer(0)
  branch_idx <- integer(0)
  may_branch <- length(game$timelines) < cfg$max_timelines
  for (L in tl_labels) {
    pt <- .mxo_present_t(game, L)
    pres_key <- .mxo_key(L, pt)
    pres_board <- game$boards[[pres_key]]
    empty_idx <- which(pres_board == 0L) - 1L
    if (length(empty_idx) > 0L) {
      present_kind <- c(present_kind, rep_len("present", length(empty_idx)))
      present_L   <- c(present_L,   rep_len(as.integer(L), length(empty_idx)))
      present_t   <- c(present_t,   rep_len(as.integer(pt), length(empty_idx)))
      present_idx <- c(present_idx, as.integer(empty_idx))
    }
    if (may_branch && pt > 0L) {
      for (ti in 0:(pt - 1L)) {
        past_key <- .mxo_key(L, ti)
        past_board <- game$boards[[past_key]]
        empty_idx <- which(past_board == 0L) - 1L
        if (length(empty_idx) > 0L) {
          branch_kind <- c(branch_kind, rep_len("branch", length(empty_idx)))
          branch_L   <- c(branch_L,   rep_len(as.integer(L), length(empty_idx)))
          branch_t   <- c(branch_t,   rep_len(as.integer(ti), length(empty_idx)))
          branch_idx <- c(branch_idx, as.integer(empty_idx))
        }
      }
    }
  }
  tibble::tibble(
    kind   = c(present_kind, branch_kind),
    L_src  = c(present_L, branch_L),
    t_src  = c(present_t, branch_t),
    idx    = c(present_idx, branch_idx),
    player = rep_len(as.integer(player),
                     length(present_kind) + length(branch_kind))
  )
}

#' Apply a move to a game state
#'
#' @param game An `mxo_game` object.
#' @param kind Character scalar, `"present"` or `"branch"`.
#' @param L_src Integer scalar, source timeline label.
#' @param t_src Integer scalar, source time index.
#' @param idx Integer scalar, spatial linear index of the target cell.
#' @return A new `mxo_game` object with the move applied.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g2 <- mxo_move(g, "present", L_src = 0L, t_src = 0L, idx = 0L)
#' mxo_to_move(g2)
mxo_move <- function(game, kind, L_src, t_src, idx) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  if (mxo_is_terminal(game)) {
    cli::cli_abort(
      "Cannot move: the game is already over ({.val {game$status}}).",
      call = call
    )
  }
  if (!is.character(kind) || length(kind) != 1L || !(kind %in% c("present", "branch"))) {
    cli::cli_abort(
      "{.arg kind} must be either {.val present} or {.val branch}.",
      call = call
    )
  }
  L_src <- .mxo_check_pos_int_zero(L_src, "L_src", call)
  t_src <- .mxo_check_pos_int_zero(t_src, "t_src", call)
  idx <- .mxo_check_pos_int_zero(idx, "idx", call)
  cfg <- game$config
  board_size <- as.integer(cfg$n ^ cfg$d_spatial)
  if (idx < 0L || idx >= board_size) {
    cli::cli_abort(
      "{.arg idx} ({idx}) is out of range; must be in 0..{board_size - 1L}.",
      call = call
    )
  }
  L_key <- as.character(L_src)
  if (is.null(game$timelines[[L_key]])) {
    cli::cli_abort(
      "Timeline {.val L{L_src}} does not exist.",
      call = call
    )
  }
  pt <- .mxo_present_t(game, L_src)
  player <- game$to_move
  if (kind == "present") {
    if (t_src != pt) {
      cli::cli_abort(
        c(
          "A {.val present} move must target the present of timeline {.val L{L_src}}.",
          i = "Its present is {.val t={pt}}; you gave {.val t={t_src}}."
        ),
        call = call
      )
    }
    src_board <- game$boards[[.mxo_key(L_src, pt)]]
    if (src_board[idx + 1L] != 0L) {
      cli::cli_abort(
        "Cell {.val idx={idx}} on board ({L_src},{pt}) is already occupied.",
        call = call
      )
    }
    # View-1 semantics (rules §4.1): the mark lands on the current present
    # board (L_src, pt); a copy is then created at (L_src, pt+1) as the new
    # ready present.
    updated_present <- src_board
    updated_present[idx + 1L] <- player
    new_t <- pt + 1L
    new_boards <- game$boards
    new_boards[[.mxo_key(L_src, pt)]] <- updated_present
    new_boards[[.mxo_key(L_src, new_t)]] <- updated_present
    new_timelines <- game$timelines
    new_timelines[[L_key]]$present_t <- new_t
    new_history <- c(game$history, list(list(
      player = player, kind = "present",
      L_src = as.integer(L_src), t_src = as.integer(pt),
      idx = as.integer(idx), L_new = NA_integer_, t_new = as.integer(pt)
    )))
    new_to_move <- if (player == 1L) 2L else 1L
    new_game <- new_mxo_game(
      boards = new_boards, timelines = new_timelines,
      to_move = new_to_move, history = new_history,
      status = "in_progress",
      winner = NA_integer_, win_line = NULL, config = cfg
    )
    win <- .mxo_check_win_at(new_game, L_src, pt, idx, player)
    .mxo_finalize_status(new_game, win, player)
  } else {
    if (t_src >= pt) {
      cli::cli_abort(
        c(
          "A {.val branch} move requires a strictly past board of timeline {.val L{L_src}}.",
          i = "Its present is {.val t={pt}}; you gave {.val t={t_src}}.",
          i = "Use {.code kind = \"present\"} to play on the present board."
        ),
        call = call
      )
    }
    src_board <- game$boards[[.mxo_key(L_src, t_src)]]
    if (src_board[idx + 1L] != 0L) {
      cli::cli_abort(
        c(
          "Cannot overwrite history.",
          i = "Cell {.val idx={idx}} on past board ({L_src},{t_src}) is already occupied."
        ),
        call = call
      )
    }
    if (length(game$timelines) >= cfg$max_timelines) {
      cli::cli_abort(
        "Cannot branch: timeline cap of {.val {cfg$max_timelines}} reached.",
        call = call
      )
    }
    new_L <- .mxo_next_timeline(game)
    new_board <- src_board
    new_board[idx + 1L] <- player
    new_key <- .mxo_key(new_L, t_src)
    new_boards <- game$boards
    new_boards[[new_key]] <- new_board
    new_timelines <- game$timelines
    new_timelines[[as.character(new_L)]] <- list(
      parent = as.integer(L_src),
      branch_t = as.integer(t_src),
      present_t = as.integer(t_src)
    )
    new_history <- c(game$history, list(list(
      player = player, kind = "branch",
      L_src = as.integer(L_src), t_src = as.integer(t_src),
      idx = as.integer(idx), L_new = as.integer(new_L),
      t_new = as.integer(t_src)
    )))
    new_to_move <- if (player == 1L) 2L else 1L
    new_game <- new_mxo_game(
      boards = new_boards, timelines = new_timelines,
      to_move = new_to_move, history = new_history,
      status = "in_progress",
      winner = NA_integer_, win_line = NULL, config = cfg
    )
    win <- .mxo_check_win_at(new_game, new_L, t_src, idx, player)
    .mxo_finalize_status(new_game, win, player)
  }
}

# Apply win/draw bookkeeping after a placement.
.mxo_finalize_status <- function(game, win, player) {
  if (!is.null(win)) {
    game$status <- if (player == 1L) "x_win" else "o_win"
    game$winner <- as.integer(player)
    game$win_line <- win
    return(game)
  }
  if (length(game$history) >= game$config$ply_cap) {
    game$status <- "draw"
    game$winner <- NA_integer_
    game$win_line <- NULL
  }
  game
}

# Non-negative integer coercion.
.mxo_check_pos_int_zero <- function(x, arg, call) {
  if (length(x) != 1L) {
    cli::cli_abort("{.arg {arg}} must be a scalar.", call = call)
  }
  if (is.logical(x) || is.na(x) || !is.numeric(x)) {
    cli::cli_abort("{.arg {arg}} must be a non-negative integer.", call = call)
  }
  xi <- suppressWarnings(as.integer(x))
  if (is.na(xi) || xi < 0L || xi != x) {
    cli::cli_abort("{.arg {arg}} must be a non-negative integer.", call = call)
  }
  xi
}

#' Play a move described by one row of `mxo_legal_moves()`
#'
#' Convenience wrapper for piping a chosen row of [mxo_legal_moves()] back into
#' [mxo_move()].
#'
#' @param game An `mxo_game` object.
#' @param move A single-row tibble or a `list` with named entries `kind`,
#'   `L_src`, `t_src`, and `idx`.
#' @return A new `mxo_game` object.
#' @export
#' @examples
#' g <- mxo_new_game()
#' mv <- mxo_legal_moves(g)[1L, ]
#' mxo_play(g, mv)
mxo_play <- function(game, move) {
  call <- rlang::current_env()
  if (is.data.frame(move)) {
    if (nrow(move) != 1L) {
      cli::cli_abort(
        "{.arg move} must have exactly one row, not {nrow(move)}.",
        call = call
      )
    }
    mxo_move(game, kind = move$kind[[1L]],
             L_src = move$L_src[[1L]],
             t_src = move$t_src[[1L]],
             idx = move$idx[[1L]])
  } else if (is.list(move)) {
    needed <- c("kind", "L_src", "t_src", "idx")
    missing <- setdiff(needed, names(move))
    if (length(missing) > 0L) {
      cli::cli_abort(
        "{.arg move} is missing field{?s}: {.field {missing}}.",
        call = call
      )
    }
    mxo_move(game, kind = move$kind, L_src = move$L_src,
             t_src = move$t_src, idx = move$idx)
  } else {
    cli::cli_abort(
      "{.arg move} must be a one-row tibble or a named list.",
      call = call
    )
  }
}

#' Undo plies by replaying from a fresh game
#'
#' Replay-based undo guarantees correctness and exercises history determinism.
#'
#' @param game An `mxo_game` object.
#' @param steps Integer scalar, number of plies to undo. Default 1.
#' @return A new `mxo_game` object with the last `steps` plies removed.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' identical(mxo_undo(g)$history, list())
mxo_undo <- function(game, steps = 1L) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  steps <- .mxo_check_pos_int_zero(steps, "steps", call)
  history_len <- length(game$history)
  if (steps > history_len) {
    cli::cli_abort(
      "{.arg steps} ({steps}) exceeds the {history_len} ply/plies in history.",
      call = call
    )
  }
  if (steps == 0L) return(game)
  new_history <- utils::head(game$history, history_len - steps)
  mxo_replay(new_history, game$config)
}

#' Rebuild a game by replaying a history log
#'
#' Proves full replayability from `history` alone (rules §11).
#'
#' @param history A list of ply records, in order, of the form produced by
#'   [mxo_move()].
#' @param config A configuration list (`list(n, d_spatial, k, ply_cap,
#'   max_timelines)`).
#' @return A new `mxo_game` object equivalent to the original.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g <- mxo_move(g, "present", 0L, 0L, 0L)
#' identical(mxo_replay(g$history, g$config)$boards, g$boards)
mxo_replay <- function(history, config) {
  if (!is.list(history)) {
    cli::cli_abort(
      "{.arg history} must be a list of ply records.",
      call = rlang::current_env()
    )
  }
  g <- mxo_new_game(n = config$n, d_spatial = config$d_spatial,
                    k = config$k, ply_cap = config$ply_cap,
                    max_timelines = config$max_timelines)
  for (rec in history) {
    g <- mxo_move(g, kind = rec$kind, L_src = rec$L_src,
                  t_src = rec$t_src, idx = rec$idx)
  }
  g
}
