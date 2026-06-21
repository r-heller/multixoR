# Controls module: new game, undo, AI play, difficulty, mode.

mxo_mod_controls_ui <- function(id) {
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
                                   "AI vs AI"       = "avai"),
                       selected = "hvai"),
    shiny::selectInput(ns("difficulty"), "AI difficulty",
                       choices = c("easy", "medium", "hard"),
                       selected = "medium")
  )
}

mxo_mod_controls_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
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
    shiny::observeEvent(input$ai_move, {
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
    })
  })
}
