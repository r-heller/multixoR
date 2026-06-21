# Generic n^d lattice geometry for multixoR.
#
# All functions here are internal helpers: index/coord conversion, canonical
# direction enumeration over (timeline, time, spatial) axes, and extent
# existence gating. The geometry is parameterised by `(n, d_spatial, k)`; the
# 4^3 / k=3 default is supplied by the caller, never hardcoded here.

# Direction-table cache, keyed by d_spatial. Filled lazily on first call.
.mxo_dir_cache <- new.env(parent = emptyenv())

# Spatial linear index <-> coordinate vector.
# idx = sum_{a=0}^{d_spatial-1} coord[a] * n^a, range 0..n^d_spatial - 1.
.mxo_idx_to_coord <- function(idx, n, d_spatial) {
  powers <- n ^ (seq_len(d_spatial) - 1L)
  vapply(powers, function(p) as.integer((idx %/% p) %% n), integer(1L))
}

.mxo_coord_to_idx <- function(coord, n, d_spatial) {
  powers <- n ^ (seq_len(d_spatial) - 1L)
  as.integer(sum(as.integer(coord) * powers))
}

# Number of canonical directions in (d_spatial + 2) axes: (3^a - 1) / 2.
.mxo_n_directions <- function(d_spatial) {
  axes <- d_spatial + 2L
  as.integer((3L ^ axes - 1L) %/% 2L)
}

# Build the canonical direction matrix for a given spatial dimension.
# Columns: dL, dt, ds_0, ..., ds_{d_spatial-1}. Components in {-1, 0, +1}.
# Excludes the all-zero vector. Canonicalised so the first non-zero component
# is positive, giving exactly (3^(d_spatial+2) - 1) / 2 rows.
.mxo_build_directions <- function(d_spatial) {
  axes <- d_spatial + 2L
  arg_list <- rep(list(c(-1L, 0L, 1L)), axes)
  names(arg_list) <- c("dL", "dt", paste0("ds", seq_len(d_spatial) - 1L))
  grid <- expand.grid(arg_list, KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
  m <- as.matrix(grid)
  storage.mode(m) <- "integer"
  nonzero <- rowSums(m != 0L) > 0L
  m <- m[nonzero, , drop = FALSE]
  first_pos <- vapply(seq_len(nrow(m)), function(i) {
    row <- m[i, ]
    fnz <- row[row != 0L][1L]
    isTRUE(fnz > 0L)
  }, logical(1L))
  m[first_pos, , drop = FALSE]
}

# Cached accessor for the canonical direction matrix.
.mxo_directions <- function(d_spatial) {
  key <- as.character(d_spatial)
  cached <- .mxo_dir_cache[[key]]
  if (is.null(cached)) {
    cached <- .mxo_build_directions(d_spatial)
    assign(key, cached, envir = .mxo_dir_cache)
  }
  cached
}

# Board-existence helper. `multiverse_keys` is a character vector of "L:t".
.mxo_key <- function(L, t) {
  paste0(as.integer(L), ":", as.integer(t))
}

# Existence test for one extent (a list of (L, t, coord) triples).
# Returns TRUE iff every cell has in-bounds coord and the board (L,t) exists.
.mxo_extent_exists <- function(boards, cells, n) {
  for (c in cells) {
    if (any(c$coord < 0L) || any(c$coord >= n)) return(FALSE)
    if (is.null(boards[[.mxo_key(c$L, c$t)]])) return(FALSE)
  }
  TRUE
}
