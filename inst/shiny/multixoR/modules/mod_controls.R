# Controls module: new game, undo, AI play, difficulty, mode.

mxo_mod_controls_ui <- function(id, difficulty = "medium") {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::h4("Game"),
    shiny::actionButton(ns("new_game"), "New game", width = "100%"),
    shiny::actionButton(ns("undo"), "Undo last ply", width = "100%"),
    shiny::actionButton(ns("ai_move"), "Make AI move", width = "100%",
                        class = "btn-primary"),
    shiny::hr(),
    shiny::h4("Mode"),
    shiny::selectInput(ns("mode"), "Play mode",
                       choices = c("Human vs Human" = "hvh",
                                   "Human vs AI"    = "hvai",
                                   "AI vs AI (step with button)" = "avai"),
                       selected = "hvai"),
    shiny::selectInput(ns("difficulty"), "AI difficulty",
                       choices = c("easy", "medium", "hard"),
                       selected = difficulty),
    shiny::hr(),
    shiny::selectInput(ns("human_move"), "Legal move", choices = character()),
    shiny::actionButton(ns("play_move"), "Play selected move", width = "100%"),
    shiny::helpText("Human vs AI: you play X. AI vs AI advances one move per button press.")
  )
}

mxo_mod_controls_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    move_keys <- function(moves) paste(moves$kind, moves$L_src, moves$t_src,
                                        moves$idx, sep = ":")
    shiny::observe({
      moves <- multixoR::mxo_legal_moves(state$game)
      labels <- paste(moves$kind, "timeline", moves$L_src, "time", moves$t_src,
                      "cell", moves$idx)
      shiny::updateSelectInput(session, "human_move",
                               choices = stats::setNames(move_keys(moves), labels))
    })
    shiny::observeEvent(input$new_game, {
      cfg <- multixoR::mxo_config(state$game)
      state$game <- multixoR::mxo_new_game(
        n = cfg$n, d_spatial = cfg$d_spatial, k = cfg$k,
        ply_cap = cfg$ply_cap, max_timelines = cfg$max_timelines
      )
    })
    shiny::observeEvent(input$undo, {
      if (length(state$game$history) == 0L) {
        shiny::showNotification("Nothing to undo.", type = "warning")
        return()
      }
      state$game <- multixoR::mxo_undo(state$game, steps = 1L)
    })
    shiny::observeEvent(input$difficulty, {
      state$difficulty <- input$difficulty
    })
    play_ai <- function() {
      if (multixoR::mxo_is_terminal(state$game)) {
        shiny::showNotification("Game already over.", type = "warning")
        return()
      }
      mv <- tryCatch(
        multixoR::mxo_ai_move(state$game, difficulty = state$difficulty,
                              seed = sample.int(1e6L, 1L)),
        error = function(e) {
          shiny::showNotification(paste0("AI error: ", e$message),
                                  type = "error")
          NULL
        }
      )
      if (is.null(mv) || nrow(mv) == 0L) return()
      state$game <- multixoR::mxo_move(
        state$game, kind = mv$kind[[1L]], L_src = mv$L_src[[1L]],
        t_src = mv$t_src[[1L]], idx = mv$idx[[1L]]
      )
    }
    shiny::observeEvent(input$ai_move, play_ai())
    shiny::observeEvent(input$play_move, {
      if (identical(input$mode, "avai")) {
        shiny::showNotification("Use Make AI move to advance AI vs AI.")
        return()
      }
      if (identical(input$mode, "hvai") && multixoR::mxo_to_move(state$game) != 1L) {
        shiny::showNotification("It is O's turn; use Make AI move.")
        return()
      }
      moves <- multixoR::mxo_legal_moves(state$game)
      i <- match(input$human_move, move_keys(moves))
      if (length(i) != 1L || is.na(i)) {
        shiny::showNotification("Select a current legal move.", type = "warning")
        return()
      }
      m <- moves[i, , drop = FALSE]
      state$game <- multixoR::mxo_move(state$game, m$kind, m$L_src, m$t_src, m$idx)
      if (identical(input$mode, "hvai") && !multixoR::mxo_is_terminal(state$game)) play_ai()
    })
  })
}
