# Analysis module: win-probability gauge + curve + move-rating table.

mxo_mod_analysis_ui <- function(id) {
  ns <- shiny::NS(id)
  shiny::tagList(
    shiny::fluidRow(
      shiny::column(
        5L,
        shiny::h4("Win probability"),
        shiny::uiOutput(ns("win_prob_text")),
        shiny::plotOutput(ns("win_prob_curve"), height = "260px")
      ),
      shiny::column(
        7L,
        shiny::h4("Move ratings"),
        DT::DTOutput(ns("rating_table"))
      )
    )
  )
}

mxo_mod_analysis_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    rating <- shiny::reactive({
      shiny::req(state$game)
      tryCatch(
        multixoR::mxo_rate_moves(state$game, method = "heuristic"),
        error = function(e) NULL
      )
    })
    output$win_prob_text <- shiny::renderUI({
      shiny::req(state$game)
      p <- multixoR::mxo_win_prob(state$game,
                                   player = multixoR::mxo_to_move(state$game),
                                   method = "heuristic")
      to_move_label <- if (multixoR::mxo_to_move(state$game) == 1L) "X" else "O"
      shiny::p(shiny::strong(paste0("P(", to_move_label, " wins): ")),
               sprintf("%.3f", p))
    })
    output$win_prob_curve <- shiny::renderPlot({
      shiny::req(state$game)
      if (length(state$game$history) == 0L) {
        return(ggplot2::ggplot() +
                 ggplot2::labs(title = "Play a move to see the curve."))
      }
      curve <- tryCatch(
        multixoR::mxo_win_prob_curve(state$game, method = "heuristic"),
        error = function(e) NULL
      )
      shiny::req(curve)
      multixoR::mxo_plot_win_prob(curve)
    })
    output$rating_table <- DT::renderDT({
      r <- rating()
      shiny::req(r)
      r[, c("kind", "L_src", "t_src", "idx", "win_prob", "rank", "label")]
    }, options = list(pageLength = 8L, dom = "tip"))
  })
}
