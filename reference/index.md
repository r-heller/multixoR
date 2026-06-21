# Package index

## Game engine

State, moves, history, and accessors.

- [`mxo_new_game()`](https://r-heller.github.io/multixoR/reference/mxo_new_game.md)
  : Start a new multixoR game

- [`mxo_move()`](https://r-heller.github.io/multixoR/reference/mxo_move.md)
  : Apply a move to a game state

- [`mxo_play()`](https://r-heller.github.io/multixoR/reference/mxo_play.md)
  :

  Play a move described by one row of
  [`mxo_legal_moves()`](https://r-heller.github.io/multixoR/reference/mxo_legal_moves.md)

- [`mxo_legal_moves()`](https://r-heller.github.io/multixoR/reference/mxo_legal_moves.md)
  : Enumerate the legal moves of a game state

- [`mxo_undo()`](https://r-heller.github.io/multixoR/reference/mxo_undo.md)
  : Undo plies by replaying from a fresh game

- [`mxo_replay()`](https://r-heller.github.io/multixoR/reference/mxo_replay.md)
  : Rebuild a game by replaying a history log

- [`mxo_status()`](https://r-heller.github.io/multixoR/reference/mxo_status.md)
  : Game status

- [`mxo_is_terminal()`](https://r-heller.github.io/multixoR/reference/mxo_is_terminal.md)
  : Test whether the game has ended

- [`mxo_board()`](https://r-heller.github.io/multixoR/reference/mxo_board.md)
  : Access a single board from the multiverse

- [`mxo_timelines()`](https://r-heller.github.io/multixoR/reference/mxo_timelines.md)
  : Timeline metadata as a tibble

- [`mxo_to_move()`](https://r-heller.github.io/multixoR/reference/mxo_to_move.md)
  : Player to move

- [`mxo_config()`](https://r-heller.github.io/multixoR/reference/mxo_config.md)
  : Game configuration

- [`mxo_history()`](https://r-heller.github.io/multixoR/reference/mxo_history.md)
  : History as a tibble

- [`is_mxo_game()`](https://r-heller.github.io/multixoR/reference/is_mxo_game.md)
  :

  Test whether an object is an `mxo_game`

- [`mxo_format_ply()`](https://r-heller.github.io/multixoR/reference/mxo_format_ply.md)
  : Serialize a ply record to canonical notation

- [`mxo_parse_ply()`](https://r-heller.github.io/multixoR/reference/mxo_parse_ply.md)
  : Parse a ply notation string into a record

- [`print(`*`<mxo_game>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_game.md)
  [`format(`*`<mxo_game>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_game.md)
  : Print a multixoR game

- [`summary(`*`<mxo_game>`*`)`](https://r-heller.github.io/multixoR/reference/summary.mxo_game.md)
  [`print(`*`<mxo_game_summary>`*`)`](https://r-heller.github.io/multixoR/reference/summary.mxo_game.md)
  : Summarise a multixoR game

- [`as_tibble.mxo_game()`](https://r-heller.github.io/multixoR/reference/as_tibble.mxo_game.md)
  : Coerce a game to a tidy tibble of occupied cells

## AI and evaluation

- [`mxo_evaluate()`](https://r-heller.github.io/multixoR/reference/mxo_evaluate.md)
  : Heuristic evaluation of a multixoR position

- [`mxo_search()`](https://r-heller.github.io/multixoR/reference/mxo_search.md)
  : Negamax with alpha-beta pruning

- [`mxo_mcts()`](https://r-heller.github.io/multixoR/reference/mxo_mcts.md)
  : Light UCT Monte-Carlo Tree Search

- [`print(`*`<mxo_mcts_result>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_mcts_result.md)
  :

  Print an `mxo_mcts_result`

- [`mxo_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob.md)
  : Probability that a player wins from the current position

- [`mxo_win_prob_curve()`](https://r-heller.github.io/multixoR/reference/mxo_win_prob_curve.md)
  : Win-probability curve along a game history

- [`mxo_rate_moves()`](https://r-heller.github.io/multixoR/reference/mxo_rate_moves.md)
  : Rate the legal moves of a position

- [`mxo_ai_move()`](https://r-heller.github.io/multixoR/reference/mxo_ai_move.md)
  : Choose a move using a packaged difficulty knob

## Simulation and strategy

- [`mxo_policy()`](https://r-heller.github.io/multixoR/reference/mxo_policy.md)
  : Build a multixoR policy

- [`is_mxo_policy()`](https://r-heller.github.io/multixoR/reference/is_mxo_policy.md)
  : Test whether an object is a multixoR policy

- [`mxo_policy_move()`](https://r-heller.github.io/multixoR/reference/mxo_policy_move.md)
  : Apply a policy to choose a move

- [`print(`*`<mxo_policy>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_policy.md)
  : Print a multixoR policy

- [`mxo_config_default()`](https://r-heller.github.io/multixoR/reference/mxo_config_default.md)
  : Default config list (used by self-play / simulate)

- [`mxo_self_play()`](https://r-heller.github.io/multixoR/reference/mxo_self_play.md)
  : Play a single self-play game between two policies

- [`print(`*`<mxo_game_record>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_game_record.md)
  : Print a self-play game record

- [`as_tibble.mxo_game_record()`](https://r-heller.github.io/multixoR/reference/as_tibble.mxo_game_record.md)
  : Coerce an mxo_game_record to a tidy per-ply tibble

- [`mxo_simulate()`](https://r-heller.github.io/multixoR/reference/mxo_simulate.md)
  : Batch self-play simulation

- [`summary(`*`<mxo_sim_result>`*`)`](https://r-heller.github.io/multixoR/reference/summary.mxo_sim_result.md)
  [`print(`*`<mxo_sim_summary>`*`)`](https://r-heller.github.io/multixoR/reference/summary.mxo_sim_result.md)
  : Summarise a batch self-play result

- [`print(`*`<mxo_sim_result>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_sim_result.md)
  :

  Print an `mxo_sim_result`

- [`mxo_opening_table()`](https://r-heller.github.io/multixoR/reference/mxo_opening_table.md)
  : Opening-cell win-rate table

- [`mxo_policy_tournament()`](https://r-heller.github.io/multixoR/reference/mxo_policy_tournament.md)
  : Round-robin tournament between policies

- [`mxo_branch_study()`](https://r-heller.github.io/multixoR/reference/mxo_branch_study.md)
  : Branch-frequency study

- [`mxo_timeline_win_rate()`](https://r-heller.github.io/multixoR/reference/mxo_timeline_win_rate.md)
  : Cross-timeline win-rate stress test

- [`mxo_make_calibration_data()`](https://r-heller.github.io/multixoR/reference/mxo_make_calibration_data.md)
  : Extract calibration data from self-play

- [`mxo_fit_calibration()`](https://r-heller.github.io/multixoR/reference/mxo_fit_calibration.md)
  : Fit a calibrator from calibration data

- [`mxo_calibrator_predict()`](https://r-heller.github.io/multixoR/reference/mxo_calibrator_predict.md)
  : Apply a calibrator to a numeric score

- [`print(`*`<mxo_calibrator>`*`)`](https://r-heller.github.io/multixoR/reference/print.mxo_calibrator.md)
  : Print a calibrator

## Visualisation

- [`mxo_plot_board()`](https://r-heller.github.io/multixoR/reference/mxo_plot_board.md)
  : Render a single multiverse board
- [`mxo_plot_multiverse()`](https://r-heller.github.io/multixoR/reference/mxo_plot_multiverse.md)
  : Plot the entire multiverse
- [`mxo_plot_threats()`](https://r-heller.github.io/multixoR/reference/mxo_plot_threats.md)
  : Plot the threatened lines of a position
- [`mxo_plot_win_prob()`](https://r-heller.github.io/multixoR/reference/mxo_plot_win_prob.md)
  : Plot a win-probability curve
- [`mxo_plot_eval()`](https://r-heller.github.io/multixoR/reference/mxo_plot_eval.md)
  : Plot the heuristic-evaluation curve along a game
- [`mxo_plot_opening()`](https://r-heller.github.io/multixoR/reference/mxo_plot_opening.md)
  : Plot the openings heatmap
- [`mxo_plot_tree()`](https://r-heller.github.io/multixoR/reference/mxo_plot_tree.md)
  : Plot the branch tree of a multixoR game
- [`autoplot(`*`<mxo_game>`*`)`](https://r-heller.github.io/multixoR/reference/autoplot.mxo_game.md)
  : Auto-render a multixoR game
- [`autoplot(`*`<mxo_sim_result>`*`)`](https://r-heller.github.io/multixoR/reference/autoplot.mxo_sim_result.md)
  : Auto-render a simulation result
- [`autoplot(`*`<mxo_game_record>`*`)`](https://r-heller.github.io/multixoR/reference/autoplot.mxo_game_record.md)
  : Auto-render a self-play record

## App and example data

- [`mxo_run_app()`](https://r-heller.github.io/multixoR/reference/mxo_run_app.md)
  : Launch the multixoR Shiny app
- [`mxo_example_game()`](https://r-heller.github.io/multixoR/reference/mxo_example_game.md)
  : A short example multixoR game
