# multixoR Shiny app entry point.
# Namespace-qualify everything (no `library()` calls per CRAN policy).
# Modules live under modules/ and are sourced relative to this file.

local({
  app_dir <- dirname(sys.frame(1)$ofile %||% getwd())
  for (m in list.files(file.path(app_dir, "modules"),
                       pattern = "\\.R$", full.names = TRUE)) {
    source(m, local = TRUE)
  }

  initial_game <- getOption("mxo_app_initial_game",
                            multixoR::mxo_example_game())
  difficulty <- getOption("mxo_app_difficulty", "medium")

  ui <- bslib::page_sidebar(
    title = "multixoR",
    theme = bslib::bs_theme(
      version = 5L, primary = "#5E2C8E",
      base_font = bslib::font_google("Inter")
    ),
    sidebar = bslib::sidebar(
      width = 280L,
      mxo_mod_controls_ui("controls"),
      mxo_mod_status_ui("status")
    ),
    bslib::navset_card_tab(
      bslib::nav_panel(
        "Multiverse",
        mxo_mod_board_ui("multiverse", view = "multiverse")
      ),
      bslib::nav_panel(
        "Board",
        mxo_mod_board_ui("board", view = "board")
      ),
      bslib::nav_panel(
        "Threats",
        shiny::plotOutput("threats_plot", height = "420px")
      ),
      bslib::nav_panel(
        "Tree",
        shiny::plotOutput("tree_plot", height = "420px")
      ),
      bslib::nav_panel(
        "Analysis",
        mxo_mod_analysis_ui("analysis")
      )
    )
  )

  server <- function(input, output, session) {
    state <- shiny::reactiveValues(
      game = initial_game,
      difficulty = difficulty
    )

    mxo_mod_controls_server("controls", state = state)
    mxo_mod_status_server("status", state = state)
    mxo_mod_board_server("multiverse", state = state, view = "multiverse")
    mxo_mod_board_server("board", state = state, view = "board")
    mxo_mod_analysis_server("analysis", state = state)

    output$threats_plot <- shiny::renderPlot({
      shiny::req(state$game)
      multixoR::mxo_plot_threats(state$game)
    })
    output$tree_plot <- shiny::renderPlot({
      shiny::req(state$game)
      multixoR::mxo_plot_tree(state$game)
    })
  }

  shiny::shinyApp(ui = ui, server = server)
})
