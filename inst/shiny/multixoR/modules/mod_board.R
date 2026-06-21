# Board module: renders either the multiverse overview or a single board.
# Click-to-move via plotly events is captured here, mapped via
# `multixoR:::.mxo_cube_coords`, and applied to `state$game`.

mxo_mod_board_ui <- function(id, view = c("multiverse", "board")) {
  ns <- shiny::NS(id)
  view <- match.arg(view)
  shiny::tagList(
    shiny::fluidRow(
      if (view == "board") shiny::column(
        4L,
        shiny::numericInput(ns("L"), "Timeline (L)",
                            value = 0L, min = 0L, step = 1L),
        shiny::numericInput(ns("t"), "Time (t)",
                            value = 0L, min = 0L, step = 1L),
        shiny::selectInput(ns("overlay"), "Overlay",
                           choices = c("none", "top3", "heatmap"))
      ) else NULL,
      shiny::column(
        if (view == "board") 8L else 12L,
        plotly::plotlyOutput(ns("plot"), height = "520px")
      )
    )
  )
}

mxo_mod_board_server <- function(id, state, view = c("multiverse", "board")) {
  view <- match.arg(view)
  shiny::moduleServer(id, function(input, output, session) {
    output$plot <- plotly::renderPlotly({
      shiny::req(state$game)
      if (view == "multiverse") {
        plotly::ggplotly(multixoR::mxo_plot_multiverse(state$game))
      } else {
        rating <- if (!is.null(input$overlay) && input$overlay != "none") {
          tryCatch(multixoR::mxo_rate_moves(state$game, method = "heuristic"),
                   error = function(e) NULL)
        } else NULL
        p <- tryCatch(
          multixoR::mxo_plot_board(state$game,
                                   L = input$L %||% 0L,
                                   t = input$t %||% 0L,
                                   view = "cube",
                                   overlay = input$overlay %||% "none",
                                   rating = rating),
          error = function(e) {
            plotly::plot_ly() |>
              plotly::layout(title = paste0("Error: ", e$message))
          }
        )
        p
      }
    })
  })
}
