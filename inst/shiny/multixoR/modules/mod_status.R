# Status module: shows ply count, to-move, timelines, and the win banner.

mxo_mod_status_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::hr(),
    shiny::h4("Status"),
    shiny::uiOutput(ns("badges"))
  )
}

mxo_mod_status_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    output$badges <- shiny::renderUI({
      shiny::req(state$game)
      g <- state$game
      to_move_label <- if (multixoR::mxo_to_move(g) == 1L) "X" else "O"
      shiny::tagList(
        shiny::p(shiny::strong("Status: "),
                 shiny::span(class = "badge bg-secondary", g$status)),
        shiny::p(shiny::strong("To move: "), to_move_label),
        shiny::p(shiny::strong("Plies: "), length(g$history)),
        shiny::p(shiny::strong("Timelines: "), length(g$timelines))
      )
    })
  })
}
