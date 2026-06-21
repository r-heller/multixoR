# Tiny example game used by docs, vignettes, the app's default state, and
# `autoplot()` examples. Deterministic and small (a handful of plies,
# including one branch and one near-threat).

#' A short example multixoR game
#'
#' Plays a deterministic sequence of moves that includes one branch and at
#' least one 2-in-a-row near-threat. Used by docs, vignettes, and as the
#' Shiny app's default state.
#'
#' @return An `mxo_game` object.
#' @export
#' @examples
#' g <- mxo_example_game()
#' mxo_to_move(g)
#' length(g$timelines)
mxo_example_game <- function() {
  g <- mxo_new_game()
  g <- mxo_move(g, "present", 0L, 0L, 0L)   # X (0,0,0)
  g <- mxo_move(g, "present", 0L, 1L, 5L)   # O (1,1,0)
  g <- mxo_move(g, "present", 0L, 2L, 1L)   # X (1,0,0)
  g <- mxo_move(g, "branch",  0L, 1L, 63L)  # O branches at past, spawns L1
  g <- mxo_move(g, "present", 0L, 3L, 16L)  # X (0,0,1)
  g
}
