# Build the package-internal default win-probability calibrator.
#
# Run from the package root:
#   Rscript data-raw/make_calibrator.R
#
# The script self-plays a small batch of games with two random policies on
# a tiny 3^3 config, fits a logistic calibrator from the per-ply
# (mover-perspective score, eventual outcome) pairs, and writes it to
# `R/sysdata.rda` via `usethis::use_data(..., internal = TRUE)`.
#
# The batch is intentionally small so this script terminates quickly under
# the pure-R engine; refit with a larger batch (and stronger policies) when
# the engine's hot loops are ported to Rcpp.

suppressPackageStartupMessages({
  devtools::load_all(quiet = TRUE)
})

set.seed(20260621L)

cfg <- mxo_config_default(n = 3L, d_spatial = 3L, k = 3L,
                          ply_cap = 12L, max_timelines = 6L)
data <- mxo_make_calibration_data(
  n_games = 40L,
  policy_x = mxo_policy("random", branch_policy = "all"),
  policy_o = mxo_policy("random", branch_policy = "all"),
  config = cfg,
  seed = 1L
)
message("Calibration rows: ", nrow(data),
        " (decisive: ", sum(data$outcome != 0L), ")")

mxo_calibrator_default <- mxo_fit_calibration(data, type = "logistic")
print(mxo_calibrator_default)

usethis::use_data(mxo_calibrator_default,
                  internal = TRUE, overwrite = TRUE)
