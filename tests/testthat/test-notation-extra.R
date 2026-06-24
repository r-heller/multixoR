# Extra coverage for R/mxo_notation.R: remaining format/parse guards.

test_that("mxo_format_ply rejects an out-of-domain player", {
  expect_error(
    mxo_format_ply(list(player = 3L, kind = "present", L_src = 0L,
                        t_src = 0L, idx = 0L)),
    "must be"
  )
})

test_that("mxo_format_ply rejects an invalid kind", {
  expect_error(
    mxo_format_ply(list(player = 1L, kind = "teleport", L_src = 0L,
                        t_src = 0L, idx = 0L)),
    "must be"
  )
})

test_that("mxo_parse_ply rejects a non-scalar-character input", {
  expect_error(mxo_parse_ply(c("a", "b")), "character scalar")
  expect_error(mxo_parse_ply(42L), "character scalar")
})

test_that("format then parse is an exact round-trip for present and branch", {
  pres <- list(player = 1L, kind = "present", L_src = 2L, t_src = 3L,
               idx = 11L, L_new = NA_integer_)
  expect_equal(mxo_parse_ply(mxo_format_ply(pres))[c("player", "kind",
               "L_src", "t_src", "idx")],
               pres[c("player", "kind", "L_src", "t_src", "idx")])
  br <- list(player = 2L, kind = "branch", L_src = 1L, t_src = 0L,
             idx = 5L, L_new = 4L)
  rt <- mxo_parse_ply(mxo_format_ply(br))
  expect_equal(rt$L_new, 4L)
})
