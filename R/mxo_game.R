# S3 game-state object: constructor / validator / user helper.
#
# Layout (rules doc §7):
#   boards     named list keyed by "L:t" -> integer(n^d_spatial)  (0/1/2)
#   timelines  list keyed by character(L) -> list(parent, branch_t, present_t)
#   to_move    1L (X) or 2L (O)
#   history    list of ply records (see mxo_move.R)
#   status     "in_progress" | "x_win" | "o_win" | "draw"
#   winner     NA_integer_ or 1L/2L
#   win_line   NULL or list of cells (L, t, idx)
#   config     list(n, d_spatial, k, ply_cap, max_timelines)

# Low-level constructor. Internal: callers must supply already-validated args.
new_mxo_game <- function(boards, timelines, to_move, history, status,
                         winner = NA_integer_, win_line = NULL, config) {
  stopifnot(
    is.list(boards),
    is.list(timelines),
    is.integer(to_move), length(to_move) == 1L, to_move %in% c(1L, 2L),
    is.list(history),
    is.character(status), length(status) == 1L,
    is.list(config)
  )
  structure(
    list(
      boards    = boards,
      timelines = timelines,
      to_move   = to_move,
      history   = history,
      status    = status,
      winner    = winner,
      win_line  = win_line,
      config    = config
    ),
    class = "mxo_game"
  )
}

# Static-invariant validator. Called by user-facing constructors and accepts
# user-built states. cli errors include the calling context.
validate_mxo_game <- function(x, call = rlang::caller_env()) {
  if (!inherits(x, "mxo_game")) {
    cli::cli_abort("{.arg x} must be an {.cls mxo_game} object.", call = call)
  }
  cfg <- x$config
  required_cfg <- c("n", "d_spatial", "k", "ply_cap", "max_timelines")
  missing_cfg <- setdiff(required_cfg, names(cfg))
  if (length(missing_cfg) > 0L) {
    cli::cli_abort(
      "Config is missing field{?s}: {.field {missing_cfg}}.",
      call = call
    )
  }
  n <- cfg$n
  d_spatial <- cfg$d_spatial
  board_size <- as.integer(n ^ d_spatial)
  keys <- names(x$boards)
  if (any(duplicated(keys))) {
    cli::cli_abort("Duplicate board key{?s} detected.", call = call)
  }
  for (key in keys) {
    b <- x$boards[[key]]
    if (!is.integer(b) || length(b) != board_size) {
      cli::cli_abort(
        "Board {.val {key}} must be an integer vector of length {board_size}.",
        call = call
      )
    }
    if (any(!(b %in% c(0L, 1L, 2L)))) {
      cli::cli_abort(
        "Board {.val {key}} contains values outside {{0,1,2}}.",
        call = call
      )
    }
  }
  tl_labels <- suppressWarnings(as.integer(names(x$timelines)))
  if (any(is.na(tl_labels))) {
    cli::cli_abort("Timeline labels must be integer-valued names.", call = call)
  }
  if (any(duplicated(tl_labels))) {
    cli::cli_abort("Timeline labels must be unique.", call = call)
  }
  if (length(tl_labels) > 0L) {
    sorted <- sort(tl_labels)
    if (!identical(sorted, seq.int(0L, length(tl_labels) - 1L))) {
      cli::cli_abort(
        "Timeline labels must be the contiguous integers {.val 0..N-1}.",
        call = call
      )
    }
  }
  history_len <- length(x$history)
  expected_to_move <- if (history_len %% 2L == 0L) 1L else 2L
  if (x$status == "in_progress" && x$to_move != expected_to_move) {
    cli::cli_abort(
      c("Parity mismatch.",
        i = "History length {history_len} implies {.val {expected_to_move}} to move; got {.val {x$to_move}}."),
      call = call
    )
  }
  invisible(x)
}

#' Start a new multixoR game
#'
#' Creates a fresh game state with one empty board at `(L0, t0)`. The geometry
#' is parameterised by `(n, d_spatial, k)`; the default 4 / 3 / 3 corresponds
#' to the canonical configuration described in the game specification.
#'
#' @param n Integer scalar, spatial side length. Default 4.
#' @param d_spatial Integer scalar, number of spatial dimensions. Default 3.
#' @param k Integer scalar, run length required to win. Default 3. Must satisfy
#'   `k <= n`.
#' @param ply_cap Integer scalar, total plies allowed before the game is
#'   declared a draw. Default 60.
#' @param max_timelines Integer scalar, maximum number of timelines the
#'   multiverse may host. Default 32.
#'
#' @return An object of class `mxo_game` with one empty board at `(L0, t0)`
#'   and X to move.
#' @export
#' @examples
#' g <- mxo_new_game()
#' g
#' mxo_to_move(g)
mxo_new_game <- function(n = 4L, d_spatial = 3L, k = 3L,
                         ply_cap = 60L, max_timelines = 32L) {
  call <- rlang::current_env()
  n <- .mxo_check_pos_int(n, "n", call)
  d_spatial <- .mxo_check_pos_int(d_spatial, "d_spatial", call)
  k <- .mxo_check_pos_int(k, "k", call)
  ply_cap <- .mxo_check_pos_int(ply_cap, "ply_cap", call)
  max_timelines <- .mxo_check_pos_int(max_timelines, "max_timelines", call)
  if (k > n) {
    cli::cli_abort(
      "{.arg k} ({k}) cannot exceed {.arg n} ({n}).",
      call = call
    )
  }
  if (max_timelines < 1L) {
    cli::cli_abort("{.arg max_timelines} must be at least 1.", call = call)
  }
  board_size <- as.integer(n ^ d_spatial)
  boards <- list()
  boards[[.mxo_key(0L, 0L)]] <- integer(board_size)
  timelines <- list()
  timelines[["0"]] <- list(parent = NA_integer_, branch_t = NA_integer_,
                           present_t = 0L)
  config <- list(n = n, d_spatial = d_spatial, k = k,
                 ply_cap = ply_cap, max_timelines = max_timelines)
  g <- new_mxo_game(
    boards = boards, timelines = timelines,
    to_move = 1L, history = list(), status = "in_progress",
    winner = NA_integer_, win_line = NULL, config = config
  )
  validate_mxo_game(g, call = call)
  g
}

#' Test whether an object is an `mxo_game`
#'
#' @param x An object.
#' @return Logical scalar.
#' @export
#' @examples
#' is_mxo_game(mxo_new_game())
#' is_mxo_game(list())
is_mxo_game <- function(x) {
  inherits(x, "mxo_game")
}

# Coerce arg to a single positive integer or abort.
.mxo_check_pos_int <- function(x, arg, call) {
  if (length(x) != 1L) {
    cli::cli_abort("{.arg {arg}} must be a scalar.", call = call)
  }
  if (is.logical(x) || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be a positive integer.", call = call)
  }
  if (!is.numeric(x)) {
    cli::cli_abort("{.arg {arg}} must be a positive integer.", call = call)
  }
  xi <- suppressWarnings(as.integer(x))
  if (is.na(xi) || xi <= 0L || xi != x) {
    cli::cli_abort("{.arg {arg}} must be a positive integer.", call = call)
  }
  xi
}

# Internal accessor (cheap, no validation).
.mxo_present_t <- function(game, L) {
  game$timelines[[as.character(as.integer(L))]]$present_t
}

# Sorted integer timeline labels.
.mxo_timeline_labels <- function(game) {
  sort(as.integer(names(game$timelines)))
}

# Next free timeline label.
.mxo_next_timeline <- function(game) {
  if (length(game$timelines) == 0L) return(0L)
  max(.mxo_timeline_labels(game)) + 1L
}
