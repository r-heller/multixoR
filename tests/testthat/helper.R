# Small reusable fixtures for Stack A tests.

# 3x3x3 with k=3 makes for tiny boards (27 cells) and tight win lines.
small_game <- function(...) {
  mxo_new_game(n = 3L, d_spatial = 3L, k = 3L, ...)
}

play_seq <- function(game, moves) {
  for (m in moves) {
    game <- mxo_move(game, kind = m$kind, L_src = m$L_src,
                     t_src = m$t_src, idx = m$idx)
  }
  game
}

p_move <- function(L, t, idx) {
  list(kind = "present", L_src = as.integer(L),
       t_src = as.integer(t), idx = as.integer(idx))
}

b_move <- function(L, t, idx) {
  list(kind = "branch", L_src = as.integer(L),
       t_src = as.integer(t), idx = as.integer(idx))
}
