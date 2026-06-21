# Launcher for the bundled Shiny app.
#
# `shiny`, `bslib`, and `DT` are app-only deps kept in `Suggests` (per Stack E
# §E.1). We verify their availability at launch time and abort with an
# install hint if any are missing.

#' Launch the multixoR Shiny app
#'
#' Starts the bundled app under `inst/shiny/multixoR/`.
#'
#' @param game Optional `mxo_game` to seed the app's initial state. Defaults
#'   to [mxo_example_game()].
#' @param difficulty AI difficulty for the app's AI vs Human modes; one of
#'   `"easy"`, `"medium"`, `"hard"`. Default `"medium"`.
#' @param ... Additional arguments forwarded to [shiny::runApp()].
#' @return Invisible `NULL`. Launches a Shiny app.
#' @export
#' @examples
#' \donttest{
#' if (interactive()) {
#'   mxo_run_app()
#' }
#' }
mxo_run_app <- function(game = NULL, difficulty = c("medium", "easy", "hard"),
                        ...) {
  call <- rlang::current_env()
  needed <- c("shiny", "bslib", "DT")
  missing <- needed[!vapply(needed, requireNamespace, logical(1L),
                            quietly = TRUE)]
  if (length(missing) > 0L) {
    install_call <- paste0(
      "install.packages(c(",
      paste0("\"", missing, "\"", collapse = ", "),
      "))"
    )
    cli::cli_abort(
      c(
        "Cannot launch the multixoR app: missing package{?s} {.pkg {missing}}.",
        i = "Install with: {.code {install_call}}"
      ),
      call = call
    )
  }
  difficulty <- match.arg(difficulty)
  app_dir <- system.file("shiny", "multixoR", package = "multixoR")
  if (!nzchar(app_dir)) {
    cli::cli_abort(
      "Could not find the bundled Shiny app under {.code inst/shiny/multixoR}.",
      call = call
    )
  }
  if (is.null(game)) game <- mxo_example_game()
  withr::with_options(
    list(mxo_app_initial_game = game, mxo_app_difficulty = difficulty),
    shiny::runApp(app_dir, ...)
  )
  invisible(NULL)
}
