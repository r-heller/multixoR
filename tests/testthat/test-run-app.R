test_that("mxo_run_app errors helpfully when a Suggests dep is absent", {
  needed <- c("shiny", "bslib", "DT")
  withr::with_envvar(c(), {
    # Stub requireNamespace via mocked helper: use trace + local mocking.
    local_mock_require <- function(pkg, ...) FALSE
    # Bind only inside our test environment by shadowing.
    fake_env <- new.env(parent = baseenv())
    fake_env$requireNamespace <- function(...) FALSE
    fake_env$mxo_run_app <- multixoR::mxo_run_app
    environment(fake_env$mxo_run_app) <- fake_env
    expect_error(fake_env$mxo_run_app(), "missing")
  })
})

test_that("the bundled app file is present and sources its modules", {
  app_dir <- system.file("shiny", "multixoR", package = "multixoR")
  if (!nzchar(app_dir)) skip("app_dir not installed in this test config")
  expect_true(file.exists(file.path(app_dir, "app.R")))
  mods <- list.files(file.path(app_dir, "modules"),
                     pattern = "\\.R$", full.names = TRUE)
  expect_true(length(mods) >= 4L)
  for (m in mods) expect_silent(parse(m))
})
