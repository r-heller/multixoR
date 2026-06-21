# Print methods, summaries, accessors, and tidy coercion.

#' Print a multixoR game
#'
#' @param x An `mxo_game` object.
#' @param ... Unused. Reserved for future arguments.
#' @return Invisibly returns `x`.
#' @export
#' @examples
#' print(mxo_new_game())
print.mxo_game <- function(x, ...) {
  rlang::check_dots_empty()
  cfg <- x$config
  n_timelines <- length(x$timelines)
  n_boards <- length(x$boards)
  who <- if (x$to_move == 1L) "X" else "O"
  cli::cli_h1("multixoR game")
  cli::cli_alert_info("Config: n={cfg$n}, d_spatial={cfg$d_spatial}, k={cfg$k}, ply_cap={cfg$ply_cap}, max_timelines={cfg$max_timelines}")
  cli::cli_alert_info("Multiverse: {n_timelines} timeline{?s}, {n_boards} board{?s}")
  cli::cli_alert_info("Plies played: {length(x$history)}; to move: {who}")
  cli::cli_alert_info("Status: {x$status}")
  if (n_timelines > 0L) {
    sketch <- .mxo_multiverse_sketch(x)
    cli::cli_text("")
    cli::cli_text("{.strong Multiverse sketch} (timelines x time; '.' = no board, '#' = occupied count)")
    for (line in sketch) cli::cli_text("  {line}")
  }
  invisible(x)
}

# Build a compact textual sketch of the multiverse.
.mxo_multiverse_sketch <- function(x) {
  labels <- .mxo_timeline_labels(x)
  max_t <- max(vapply(x$timelines, function(meta) as.integer(meta$present_t),
                     integer(1L)))
  header <- paste0("L\\t ", paste0(sprintf("%2d", 0:max_t), collapse = " "))
  rows <- vapply(labels, function(L) {
    cells <- vapply(0:max_t, function(ti) {
      key <- .mxo_key(L, ti)
      b <- x$boards[[key]]
      if (is.null(b)) "  ." else sprintf("%3d", sum(b != 0L))
    }, character(1L))
    paste0(sprintf("L%-2d", L), paste0(cells, collapse = ""))
  }, character(1L))
  c(header, rows)
}

#' @rdname print.mxo_game
#' @return For `format`, a character vector representation.
#' @export
format.mxo_game <- function(x, ...) {
  rlang::check_dots_empty()
  cfg <- x$config
  who <- if (x$to_move == 1L) "X" else "O"
  c(
    sprintf("<mxo_game> config=(n=%d,d=%d,k=%d) timelines=%d boards=%d plies=%d to_move=%s status=%s",
            cfg$n, cfg$d_spatial, cfg$k,
            length(x$timelines), length(x$boards), length(x$history), who,
            x$status)
  )
}

#' Summarise a multixoR game
#'
#' @param object An `mxo_game` object.
#' @param ... Unused. Reserved for future arguments.
#' @return An object of class `mxo_game_summary` with counts per player and
#'   branch information.
#' @export
#' @examples
#' summary(mxo_new_game())
summary.mxo_game <- function(object, ...) {
  rlang::check_dots_empty()
  marks <- c(x = 0L, o = 0L)
  for (b in object$boards) {
    marks["x"] <- marks["x"] + sum(b == 1L)
    marks["o"] <- marks["o"] + sum(b == 2L)
  }
  branches <- sum(vapply(object$history, function(h)
    identical(h$kind, "branch"), logical(1L)))
  out <- list(
    config    = object$config,
    n_timelines = length(object$timelines),
    n_boards  = length(object$boards),
    plies     = length(object$history),
    branches  = as.integer(branches),
    marks_x   = unname(marks["x"]),
    marks_o   = unname(marks["o"]),
    to_move   = object$to_move,
    status    = object$status,
    winner    = object$winner
  )
  structure(out, class = "mxo_game_summary")
}

#' @rdname summary.mxo_game
#' @param x An `mxo_game_summary` object.
#' @return Invisibly returns `x`.
#' @export
print.mxo_game_summary <- function(x, ...) {
  rlang::check_dots_empty()
  who <- if (x$to_move == 1L) "X" else "O"
  cli::cli_h1("mxo_game summary")
  cli::cli_alert_info("Status: {x$status}")
  cli::cli_alert_info("Plies: {x$plies} ({x$branches} branch ply/plies)")
  cli::cli_alert_info("Timelines: {x$n_timelines}; boards: {x$n_boards}")
  cli::cli_alert_info("Marks: X={x$marks_x}, O={x$marks_o}; to move: {who}")
  invisible(x)
}

#' Access a single board from the multiverse
#'
#' @param game An `mxo_game` object.
#' @param L Integer scalar, timeline label.
#' @param t Integer scalar, time index.
#' @return An integer vector of length `n^d_spatial` with values in
#'   `{0L, 1L, 2L}` (0 empty, 1 X, 2 O).
#' @export
#' @examples
#' mxo_board(mxo_new_game(), 0L, 0L)
mxo_board <- function(game, L, t) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  L <- .mxo_check_pos_int_zero(L, "L", call)
  t <- .mxo_check_pos_int_zero(t, "t", call)
  key <- .mxo_key(L, t)
  b <- game$boards[[key]]
  if (is.null(b)) {
    cli::cli_abort(
      "No board exists at ({.val L={L}},{.val t={t}}).",
      call = call
    )
  }
  b
}

#' Timeline metadata as a tibble
#'
#' @param game An `mxo_game` object.
#' @return A tibble with one row per timeline and columns `L` (int),
#'   `parent` (int, NA for the root), `branch_t` (int, NA for the root), and
#'   `present_t` (int).
#' @export
#' @examples
#' mxo_timelines(mxo_new_game())
mxo_timelines <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  labels <- .mxo_timeline_labels(game)
  if (length(labels) == 0L) {
    return(tibble::tibble(
      L = integer(0), parent = integer(0),
      branch_t = integer(0), present_t = integer(0)
    ))
  }
  tibble::tibble(
    L = as.integer(labels),
    parent = vapply(labels, function(L)
      as.integer(game$timelines[[as.character(L)]]$parent),
      integer(1L)),
    branch_t = vapply(labels, function(L)
      as.integer(game$timelines[[as.character(L)]]$branch_t),
      integer(1L)),
    present_t = vapply(labels, function(L)
      as.integer(game$timelines[[as.character(L)]]$present_t),
      integer(1L))
  )
}

#' Player to move
#'
#' @param game An `mxo_game` object.
#' @return Integer scalar, `1L` (X) or `2L` (O).
#' @export
#' @examples
#' mxo_to_move(mxo_new_game())
mxo_to_move <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  game$to_move
}

#' Game configuration
#'
#' @param game An `mxo_game` object.
#' @return The configuration list (`n`, `d_spatial`, `k`, `ply_cap`,
#'   `max_timelines`).
#' @export
#' @examples
#' mxo_config(mxo_new_game())
mxo_config <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  game$config
}

#' History as a tibble
#'
#' @param game An `mxo_game` object.
#' @return A tibble with one row per ply, columns `ply` (int), `player` (int),
#'   `kind` (chr), `L_src` (int), `t_src` (int), `idx` (int),
#'   `L_new` (int, NA when not a branch), and `t_new` (int).
#' @export
#' @examples
#' mxo_history(mxo_new_game())
mxo_history <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  h <- game$history
  if (length(h) == 0L) {
    return(tibble::tibble(
      ply = integer(0), player = integer(0), kind = character(0),
      L_src = integer(0), t_src = integer(0), idx = integer(0),
      L_new = integer(0), t_new = integer(0)
    ))
  }
  tibble::tibble(
    ply = seq_along(h),
    player = vapply(h, function(r) as.integer(r$player), integer(1L)),
    kind = vapply(h, function(r) r$kind, character(1L)),
    L_src = vapply(h, function(r) as.integer(r$L_src), integer(1L)),
    t_src = vapply(h, function(r) as.integer(r$t_src), integer(1L)),
    idx = vapply(h, function(r) as.integer(r$idx), integer(1L)),
    L_new = vapply(h, function(r) as.integer(r$L_new), integer(1L)),
    t_new = vapply(h, function(r) as.integer(r$t_new), integer(1L))
  )
}

#' Coerce a game to a tidy tibble of occupied cells
#'
#' One row per occupied cell with full `(L, t, x, y, z, player)` columns (for
#' the default 3-D config; for other spatial dimensions a `coord` list-column
#' is used).
#'
#' @param x An `mxo_game` object.
#' @param ... Unused. Reserved for future arguments.
#' @return A tibble with one row per occupied cell.
#' @export
#' @examples
#' as_tibble.mxo_game(mxo_new_game())
as_tibble.mxo_game <- function(x, ...) {
  rlang::check_dots_empty()
  cfg <- x$config
  n <- cfg$n
  d_spatial <- cfg$d_spatial
  rows_L <- integer(0)
  rows_t <- integer(0)
  rows_idx <- integer(0)
  rows_player <- integer(0)
  for (key in names(x$boards)) {
    b <- x$boards[[key]]
    occ <- which(b != 0L)
    if (length(occ) == 0L) next
    parts <- strsplit(key, ":", fixed = TRUE)[[1L]]
    L <- as.integer(parts[1L])
    t <- as.integer(parts[2L])
    rows_L <- c(rows_L, rep_len(L, length(occ)))
    rows_t <- c(rows_t, rep_len(t, length(occ)))
    rows_idx <- c(rows_idx, as.integer(occ - 1L))
    rows_player <- c(rows_player, as.integer(b[occ]))
  }
  out <- tibble::tibble(L = rows_L, t = rows_t, idx = rows_idx, player = rows_player)
  if (d_spatial == 3L) {
    coords <- lapply(rows_idx, function(i) .mxo_idx_to_coord(i, n, d_spatial))
    if (length(coords) == 0L) {
      out$x <- integer(0); out$y <- integer(0); out$z <- integer(0)
    } else {
      mat <- do.call(rbind, coords)
      out$x <- as.integer(mat[, 1L])
      out$y <- as.integer(mat[, 2L])
      out$z <- as.integer(mat[, 3L])
    }
    out <- out[, c("L", "t", "x", "y", "z", "idx", "player")]
  } else {
    coords <- lapply(rows_idx, function(i) .mxo_idx_to_coord(i, n, d_spatial))
    out$coord <- coords
    out <- out[, c("L", "t", "coord", "idx", "player")]
  }
  out
}

# Register the tibble S3 method when tibble is installed (it is an Import).
.onLoad <- function(libname, pkgname) {
  s3_register("tibble::as_tibble", "mxo_game")
}

# Inline-registered s3 helper (from rlang docs). Internal.
s3_register <- function(generic, class, method = NULL) {
  stopifnot(is.character(generic), length(generic) == 1L)
  stopifnot(is.character(class), length(class) == 1L)
  pieces <- strsplit(generic, "::")[[1L]]
  stopifnot(length(pieces) == 2L)
  package <- pieces[[1L]]
  generic <- pieces[[2L]]
  caller <- parent.frame()
  get_method_env <- function() {
    top <- topenv(caller)
    if (isNamespace(top)) top else globalenv()
  }
  get_method <- function(method, env) {
    if (is.null(method)) get(paste0(generic, ".", class), envir = env)
    else method
  }
  method_fn <- get_method(method, get_method_env())
  stopifnot(is.function(method_fn))
  setHook(packageEvent(package, "onLoad"), function(...) {
    ns <- asNamespace(package)
    method_fn <- get_method(method, get_method_env())
    registerS3method(generic, class, method_fn, envir = ns)
  })
  if (!isNamespaceLoaded(package)) return(invisible())
  envir <- asNamespace(package)
  if (exists(generic, envir = envir)) {
    registerS3method(generic, class, method_fn, envir = envir)
  }
  invisible()
}
