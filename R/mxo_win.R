# Incremental, local win detection.
#
# After a placement at cell (L, t, idx), only lines passing through that cell
# can newly complete. We enumerate, for each of the (3^(d_spatial+2) - 1)/2
# canonical directions, the k extents that include the placed cell, gate each
# extent by board existence and spatial bounds, and verify single-colour
# occupancy. Hot path: pure integer ops, no R-only sugar in the inner loop
# (Rcpp-ready).

# Returns NULL if no win, else a list of length-k cell records (L, t, idx).
.mxo_check_win_at <- function(game, L, t, idx, player) {
  cfg <- game$config
  n <- cfg$n
  d_spatial <- cfg$d_spatial
  k <- cfg$k
  dirs <- .mxo_directions(d_spatial)
  start_coord <- .mxo_idx_to_coord(idx, n, d_spatial)
  boards <- game$boards
  n_dirs <- nrow(dirs)
  for (di in seq_len(n_dirs)) {
    d_row <- dirs[di, ]
    dL <- d_row[1L]
    dt_ <- d_row[2L]
    ds <- d_row[-(1:2)]
    for (j in 0:(k - 1L)) {
      cells <- vector("list", k)
      ok <- TRUE
      for (m in 0:(k - 1L)) {
        step <- m - j
        L_m <- as.integer(L + step * dL)
        t_m <- as.integer(t + step * dt_)
        coord_m <- start_coord + step * ds
        if (L_m < 0L || t_m < 0L) { ok <- FALSE; break }
        if (any(coord_m < 0L) || any(coord_m >= n)) { ok <- FALSE; break }
        key_m <- paste0(L_m, ":", t_m)
        b <- boards[[key_m]]
        if (is.null(b)) { ok <- FALSE; break }
        idx_m <- .mxo_coord_to_idx(coord_m, n, d_spatial)
        if (b[idx_m + 1L] != player) { ok <- FALSE; break }
        cells[[m + 1L]] <- list(L = L_m, t = t_m, idx = idx_m)
      }
      if (ok) return(cells)
    }
  }
  NULL
}

#' Game status
#'
#' @param game An `mxo_game` object.
#' @return A list with components:
#'   * `status` (chr): one of `"in_progress"`, `"x_win"`, `"o_win"`, `"draw"`.
#'   * `winner` (int): `NA_integer_`, `1L` (X), or `2L` (O).
#'   * `win_line` (list or NULL): the winning cells if terminal-with-win.
#' @export
#' @examples
#' mxo_status(mxo_new_game())
mxo_status <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  list(status = game$status, winner = game$winner, win_line = game$win_line)
}

#' Test whether the game has ended
#'
#' @param game An `mxo_game` object.
#' @return Logical scalar.
#' @export
#' @examples
#' mxo_is_terminal(mxo_new_game())
mxo_is_terminal <- function(game) {
  if (!is_mxo_game(game)) {
    cli::cli_abort(
      "{.arg game} must be an {.cls mxo_game} object.",
      call = rlang::current_env()
    )
  }
  !identical(game$status, "in_progress")
}
