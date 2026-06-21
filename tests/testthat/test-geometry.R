test_that("default config has exactly 121 canonical directions", {
  dirs <- multixoR:::.mxo_directions(3L)
  expect_equal(nrow(dirs), 121L)
  expect_equal(multixoR:::.mxo_n_directions(3L), 121L)
  expect_equal(ncol(dirs), 5L)
  expect_equal(colnames(dirs), c("dL", "dt", "ds0", "ds1", "ds2"))
})

test_that("n_directions matches (3^(d+2) - 1)/2 for several configs", {
  for (d in 1:4) {
    expected <- as.integer((3L ^ (d + 2L) - 1L) %/% 2L)
    expect_equal(multixoR:::.mxo_n_directions(d), expected)
    expect_equal(nrow(multixoR:::.mxo_directions(d)), expected)
  }
})

test_that("directions are canonical: first non-zero component is positive", {
  dirs <- multixoR:::.mxo_directions(3L)
  for (i in seq_len(nrow(dirs))) {
    row <- dirs[i, ]
    nz <- row[row != 0L]
    expect_gt(nz[[1L]], 0L)
  }
})

test_that("no direction and its negation both appear", {
  dirs <- multixoR:::.mxo_directions(3L)
  fwd <- apply(dirs, 1L, paste, collapse = ",")
  neg <- apply(-dirs, 1L, paste, collapse = ",")
  expect_length(intersect(fwd, neg), 0L)
})

test_that("idx <-> coord round-trip on the default config", {
  for (idx in c(0L, 1L, 4L, 16L, 21L, 42L, 63L)) {
    coord <- multixoR:::.mxo_idx_to_coord(idx, 4L, 3L)
    expect_length(coord, 3L)
    expect_equal(multixoR:::.mxo_coord_to_idx(coord, 4L, 3L), idx)
  }
})

test_that("idx <-> coord uses the documented mapping x + n*y + n^2*z", {
  expect_equal(multixoR:::.mxo_coord_to_idx(c(1L, 2L, 3L), 4L, 3L),
               1L + 4L * 2L + 16L * 3L)
  expect_equal(multixoR:::.mxo_idx_to_coord(42L, 4L, 3L),
               c(2L, 2L, 2L))
})
