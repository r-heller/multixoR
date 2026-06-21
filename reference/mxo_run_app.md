# Launch the multixoR Shiny app

Starts the bundled app under `inst/shiny/multixoR/`.

## Usage

``` r
mxo_run_app(game = NULL, difficulty = c("medium", "easy", "hard"), ...)
```

## Arguments

- game:

  Optional `mxo_game` to seed the app's initial state. Defaults to
  [`mxo_example_game()`](https://r-heller.github.io/multixoR/reference/mxo_example_game.md).

- difficulty:

  AI difficulty for the app's AI vs Human modes; one of `"easy"`,
  `"medium"`, `"hard"`. Default `"medium"`.

- ...:

  Additional arguments forwarded to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Invisible `NULL`. Launches a Shiny app.

## Examples

``` r
# \donttest{
if (interactive()) {
  mxo_run_app()
}
# }
```
