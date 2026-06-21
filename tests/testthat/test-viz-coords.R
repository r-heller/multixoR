test_that("slice_layout covers every cell of the default cube", {
  layout <- multixoR:::.mxo_slice_layout(4L, 3L)
  expect_equal(nrow(layout), 64L)
  expect_equal(sort(unique(layout$idx)), 0:63)
  expect_named(layout, c("idx", "x", "y", "z", "panel_x", "panel_y", "facet"))
})

test_that("slice_layout idx -> (x, y, z) round-trips through the spatial map", {
  layout <- multixoR:::.mxo_slice_layout(4L, 3L)
  recovered <- layout$x + 4L * layout$y + 16L * layout$z
  expect_equal(recovered, layout$idx)
})

test_that("grid_origin gives unique positions per (L, t)", {
  origins <- expand.grid(L = 0:2, t = 0:2)
  origins$x <- vapply(seq_len(nrow(origins)), function(i)
    multixoR:::.mxo_grid_origin(origins$L[i], origins$t[i])$x, numeric(1L))
  origins$y <- vapply(seq_len(nrow(origins)), function(i)
    multixoR:::.mxo_grid_origin(origins$L[i], origins$t[i])$y, numeric(1L))
  keys <- paste0(origins$x, ":", origins$y)
  expect_equal(length(unique(keys)), nrow(origins))
})
