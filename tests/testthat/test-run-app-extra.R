# Extra coverage for R/mxo_run_app.R: the difficulty match.arg guard, reached
# after the Suggests-dependency check but before any Shiny server launch.

test_that("mxo_run_app rejects an unknown difficulty", {
  skip_if_not_installed("shiny")
  skip_if_not_installed("bslib")
  skip_if_not_installed("DT")
  expect_error(mxo_run_app(difficulty = "impossible"),
               "should be one of")
})
