# Extra coverage for R/mxo_viz_coords.R: the non-3D slice layout warning,
# palette/theme helpers, and the cube-coordinate helper.

test_that("slice_layout warns and uses a flat layout for d_spatial != 3", {
  expect_warning(
    layout <- multixoR:::.mxo_slice_layout(3L, 2L),
    "flat layout"
  )
  expect_named(layout, c("idx", "panel_x", "panel_y", "facet"))
  expect_equal(nrow(layout), 9L)
})

test_that(".mxo_cube_coords decodes a linear index to (x, y, z)", {
  cc <- multixoR:::.mxo_cube_coords(42L, 4L)
  expect_equal(cc, list(x = 2L, y = 2L, z = 2L))
})

test_that("player colour and label maps cover empty / X / O", {
  cols <- multixoR:::.mxo_player_colours()
  labs <- multixoR:::.mxo_player_labels()
  expect_named(cols, c("0", "1", "2"))
  expect_equal(unname(labs[c("0", "1", "2")]), c(".", "X", "O"))
})

test_that(".mxo_theme returns a ggplot theme", {
  th <- multixoR:::.mxo_theme()
  expect_s3_class(th, "theme")
})
