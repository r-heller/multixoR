# Heuristic position evaluator.
#
# Counts m-lines (length-k extents with `m` marks of one colour and the rest
# empty) across the entire multiverse, existence-gated as in the win-check.
# Each m-line is classified by axis class (spatial / time / timeline / mixed)
# and a weighted sum gives a single numeric score from `player`'s perspective.

# Axis classifier for a single direction row (dL, dt, ds_*).
.mxo_axis_class <- function(d_row) {
  dL <- d_row[[1L]]
  dt_ <- d_row[[2L]]
  ds <- d_row[-(1:2)]
  spatial_zero <- all(ds == 0L)
  if (dt_ == 0L && dL == 0L) return("spatial")
  if (dt_ != 0L && dL == 0L && spatial_zero) return("time")
  if (dt_ == 0L && dL != 0L && spatial_zero) return("timeline")
  "mixed"
}

# Enumerate every existing length-k extent in the multiverse and return a
# tibble (player, m, axis_class, count) of per-class m-line tallies.
#
# The implementation flattens the multiverse into a single integer vector
# `flat_cells` indexed by `(L * stride + t) * board_size + idx + 1L`. For each
# canonical direction d we determine the spatial start-indices that keep the
# whole extent in-bounds; for each existing source board whose (L, t)
# trajectory remains existent for all k steps, we vector-look-up the cell
# values at all valid starts in one R call per step. The per-extent
# colour-count is then a `rowSums` over the resulting (#starts) x k matrix.
.mxo_line_features <- function(game) {
  cfg <- game$config
  n <- cfg$n
  d_spatial <- cfg$d_spatial
  k <- cfg$k
  dirs <- .mxo_directions(d_spatial)
  boards <- game$boards
  board_size <- as.integer(n ^ d_spatial)
  axis_classes <- c("spatial", "time", "timeline", "mixed")
  counts <- array(0L,
                  dim = c(2L, k, length(axis_classes)),
                  dimnames = list(c("x", "o"), as.character(seq_len(k)),
                                  axis_classes))
  board_keys <- names(boards)
  if (length(board_keys) == 0L) return(.mxo_features_to_tibble(counts))
  parsed <- strsplit(board_keys, ":", fixed = TRUE)
  Ls <- vapply(parsed, function(p) as.integer(p[[1L]]), integer(1L))
  ts <- vapply(parsed, function(p) as.integer(p[[2L]]), integer(1L))
  max_L <- max(Ls); max_t <- max(ts)
  stride <- max_t + 1L
  total_slots <- (max_L + 1L) * stride
  flat_cells <- integer(total_slots * board_size)
  has_board <- logical(total_slots)
  for (i in seq_along(board_keys)) {
    slot <- Ls[i] * stride + ts[i] + 1L
    has_board[slot] <- TRUE
    base <- (slot - 1L) * board_size
    flat_cells[base + seq_len(board_size)] <- boards[[board_keys[i]]]
  }
  all_idx <- 0:(board_size - 1L)
  powers <- n ^ (seq_len(d_spatial) - 1L)
  coord_mat <- vapply(all_idx, function(idx) as.integer((idx %/% powers) %% n),
                      integer(d_spatial))
  n_dirs <- nrow(dirs)
  for (di in seq_len(n_dirs)) {
    dL <- dirs[di, 1L]; dt_ <- dirs[di, 2L]; ds <- dirs[di, -(1:2)]
    cls_i <- match(.mxo_axis_class(dirs[di, ]), axis_classes)
    valid_spatial <- rep(TRUE, board_size)
    for (s in 0:(k - 1L)) {
      shifted <- coord_mat + s * ds
      ok <- apply(shifted >= 0L & shifted < n, 2L, all)
      valid_spatial <- valid_spatial & ok
    }
    valid_idx <- all_idx[valid_spatial]
    if (length(valid_idx) == 0L) next
    delta_idx <- as.integer(sum(ds * powers))
    for (bk in seq_along(board_keys)) {
      L_s <- Ls[bk]; t_s <- ts[bk]
      exist_all <- TRUE
      slots <- integer(k)
      for (s in 0:(k - 1L)) {
        L_n <- L_s + s * dL; t_n <- t_s + s * dt_
        if (L_n < 0L || t_n < 0L || L_n > max_L || t_n > max_t) {
          exist_all <- FALSE; break
        }
        slot_n <- L_n * stride + t_n + 1L
        if (!has_board[slot_n]) { exist_all <- FALSE; break }
        slots[s + 1L] <- slot_n
      }
      if (!exist_all) next
      n_starts <- length(valid_idx)
      values <- matrix(0L, nrow = n_starts, ncol = k)
      for (s in 0:(k - 1L)) {
        base <- (slots[s + 1L] - 1L) * board_size
        values[, s + 1L] <- flat_cells[base + valid_idx + s * delta_idx + 1L]
      }
      cnt_x <- rowSums(values == 1L)
      cnt_o <- rowSums(values == 2L)
      live <- cnt_x == 0L | cnt_o == 0L
      occupied <- (cnt_x + cnt_o) > 0L
      keep <- live & occupied
      if (!any(keep)) next
      m_x_keep <- cnt_x[keep]
      m_o_keep <- cnt_o[keep]
      for (m in seq_len(k)) {
        nx <- sum(m_x_keep == m)
        no <- sum(m_o_keep == m)
        if (nx > 0L) counts[1L, m, cls_i] <- counts[1L, m, cls_i] + nx
        if (no > 0L) counts[2L, m, cls_i] <- counts[2L, m, cls_i] + no
      }
    }
  }
  .mxo_features_to_tibble(counts)
}

.mxo_features_to_tibble <- function(counts) {
  d <- dim(counts)
  ms <- as.integer(dimnames(counts)[[2L]])
  classes <- dimnames(counts)[[3L]]
  rows <- expand.grid(
    player = c(1L, 2L),
    m = ms,
    axis_class = classes,
    KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE
  )
  rows$count <- mapply(function(p, m, cl) {
    counts[if (p == 1L) "x" else "o", as.character(m), cl]
  }, rows$player, rows$m, rows$axis_class)
  tibble::as_tibble(rows)
}

#' Heuristic evaluation of a multixoR position
#'
#' Returns a numeric scalar; positive values favour `player`. Terminal states
#' map to a large signed sentinel scaled to prefer faster wins.
#'
#' @param game An `mxo_game` object.
#' @param player Integer scalar, the perspective player (`1L` for X, `2L` for
#'   O). Defaults to the player to move.
#' @param w Numeric vector of length `k` giving the per-m-line weights. The
#'   default is exponential: `1, 8, 64, ...`.
#' @param w_timeline Numeric multiplier applied to m-lines whose direction
#'   traverses the timeline axis (axis class `"timeline"` or `"mixed"`).
#'   Default `1`. Larger values amplify cross-timeline tactics.
#' @param terminal_score Magnitude of the terminal sentinel. Default `1e6`.
#' @return A numeric scalar.
#' @export
#' @examples
#' g <- mxo_new_game()
#' mxo_evaluate(g)
mxo_evaluate <- function(game,
                         player = mxo_to_move(game),
                         w = NULL,
                         w_timeline = 1,
                         terminal_score = 1e6) {
  call <- rlang::current_env()
  if (!is_mxo_game(game)) {
    cli::cli_abort("{.arg game} must be an {.cls mxo_game} object.", call = call)
  }
  if (!is.numeric(player) || length(player) != 1L) {
    cli::cli_abort("{.arg player} must be {.val 1} or {.val 2}.", call = call)
  }
  player <- as.integer(player)
  cfg <- game$config
  k <- cfg$k
  if (is.null(w)) w <- 8 ^ (seq_len(k) - 1L)
  if (length(w) != k) {
    cli::cli_abort("{.arg w} must have length {.val {k}}.", call = call)
  }
  if (mxo_is_terminal(game)) {
    if (game$status == "draw") return(0)
    sgn <- if (identical(game$winner, player)) 1 else -1
    plies_left <- max(0L, cfg$ply_cap - length(game$history))
    return(sgn * terminal_score * (1 + plies_left * 1e-3))
  }
  feats <- .mxo_line_features(game)
  weights <- w[feats$m]
  axis_mult <- ifelse(feats$axis_class %in% c("timeline", "mixed"),
                      w_timeline, 1)
  contribution <- weights * axis_mult * feats$count
  my <- feats$player == player
  as.numeric(sum(contribution[my]) - sum(contribution[!my]))
}
