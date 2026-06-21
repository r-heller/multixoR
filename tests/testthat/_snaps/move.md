# branching into an occupied past cell errors

    Code
      mxo_move(g, "branch", 0L, 0L, 0L)
    Condition
      Error in `mxo_move()`:
      ! Cannot overwrite history.
      i Cell "idx=0" on past board (0,0) is already occupied.

# branching the present (non-past) board errors

    Code
      mxo_move(g, "branch", 0L, 1L, 0L)
    Condition
      Error in `mxo_move()`:
      ! A "branch" move requires a strictly past board of timeline "L0".
      i Its present is "t=1"; you gave "t=1".
      i Use `kind = "present"` to play on the present board.

# exceeding max_timelines errors

    Code
      mxo_move(g, "branch", 0L, 0L, 62L)
    Condition
      Error in `mxo_move()`:
      ! Cannot branch: timeline cap of 2 reached.

