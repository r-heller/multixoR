test_that("present ply round-trip", {
  rec <- list(player = 1L, kind = "present", L_src = 0L,
              t_src = 0L, idx = 21L, L_new = NA_integer_)
  s <- mxo_format_ply(rec)
  expect_equal(s, "X present @ (0,0) [21]")
  parsed <- mxo_parse_ply(s)
  expect_equal(parsed$player, 1L)
  expect_equal(parsed$kind, "present")
  expect_equal(parsed$L_src, 0L)
  expect_equal(parsed$t_src, 0L)
  expect_equal(parsed$idx, 21L)
  expect_true(is.na(parsed$L_new))
})

test_that("branch ply round-trip preserves L_new", {
  rec <- list(player = 2L, kind = "branch", L_src = 1L,
              t_src = 2L, idx = 42L, L_new = 7L)
  s <- mxo_format_ply(rec)
  expect_equal(s, "O branch @ (1,2) [42] -> L7")
  parsed <- mxo_parse_ply(s)
  expect_equal(parsed$player, 2L)
  expect_equal(parsed$kind, "branch")
  expect_equal(parsed$L_new, 7L)
})

test_that("parser tolerates extra spaces around 'branch'", {
  parsed <- mxo_parse_ply("X branch  @ (0,0) [42] -> L1")
  expect_equal(parsed$kind, "branch")
  expect_equal(parsed$L_new, 1L)
})

test_that("malformed strings error", {
  expect_error(mxo_parse_ply("nope"), "Could not parse")
  expect_error(mxo_parse_ply("X branch @ (0,0) [42]"),
               "must include")
  expect_error(mxo_parse_ply("X present @ (0,0) [42] -> L1"),
               "must not include")
})

test_that("format rejects malformed records", {
  expect_error(
    mxo_format_ply(list(kind = "branch", L_src = 0L, t_src = 0L, idx = 0L)),
    "missing field"
  )
  expect_error(
    mxo_format_ply(list(player = 1L, kind = "branch", L_src = 0L,
                        t_src = 0L, idx = 0L, L_new = NA_integer_)),
    "non-NA"
  )
})
