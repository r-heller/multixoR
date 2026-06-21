# Win-probability calibration: data extraction, fitting, and serialisation.
#
# The package ships a *fitted* calibrator as internal data
# (`mxo_calibrator_default` in `R/sysdata.rda`, produced by the script at
# `data-raw/make_calibrator.R`). `mxo_win_prob(method = "heuristic")` uses
# it whenever it is present; otherwise it falls back to the legacy logistic
# placeholder constants in `R/mxo_win_prob.R`.

#' Extract calibration data from self-play
#'
#' For every ply in a batch of self-play games this records the heuristic
#' evaluation from the perspective of the position's player-to-move, plus the
#' eventual outcome for that player (`+1` win, `-1` loss, `0` draw). The
#' resulting tibble feeds [mxo_fit_calibration()].
#'
#' @param n_games Integer scalar, number of self-play games to run.
#' @param policy_x,policy_o `mxo_policy` objects. Default: two random
#'   policies.
#' @param config A config list (see [mxo_config_default()]).
#' @param seed Optional integer base seed.
#' @return A tibble with columns `score` (dbl, mover-perspective evaluation)
#'   and `outcome` (int, in `{-1, 0, 1}` for mover-loss / draw / mover-win).
#' @export
mxo_make_calibration_data <- function(n_games = 100L,
                                      policy_x = mxo_policy("random"),
                                      policy_o = mxo_policy("random"),
                                      config = mxo_config_default(),
                                      seed = NULL) {
  sim <- mxo_simulate(policy_x, policy_o, n_games = n_games,
                      config = config, seed = seed,
                      record_eval = TRUE, progress = FALSE)
  scores <- numeric(0L)
  outcomes <- integer(0L)
  for (rec in sim$records) {
    if (length(rec$evals) == 0L) next
    winner <- rec$winner
    is_draw <- identical(rec$outcome, "draw")
    for (i in seq_along(rec$evals)) {
      x_eval <- rec$evals[[i]]
      mover_after <- 3L - as.integer(rec$history$player[[i]])
      mover_score <- if (mover_after == 1L) x_eval else -x_eval
      out <- if (is_draw) 0L
        else if (identical(as.integer(mover_after), as.integer(winner))) 1L
        else -1L
      scores <- c(scores, mover_score)
      outcomes <- c(outcomes, out)
    }
  }
  tibble::tibble(score = scores, outcome = outcomes)
}

#' Fit a calibrator from calibration data
#'
#' Maps the heuristic evaluation score to a `[0, 1]` win probability for the
#' player-to-move. Logistic and isotonic fits are supported; both produce
#' compact, serialisable `mxo_calibrator` objects.
#'
#' @param data A tibble of the form produced by [mxo_make_calibration_data()].
#' @param type One of `"logistic"` (default) or `"isotonic"`.
#' @return An object of class `mxo_calibrator`.
#' @export
mxo_fit_calibration <- function(data, type = c("logistic", "isotonic")) {
  call <- rlang::current_env()
  type <- match.arg(type)
  if (!all(c("score", "outcome") %in% names(data))) {
    cli::cli_abort(
      "{.arg data} must have columns {.field score} and {.field outcome}.",
      call = call
    )
  }
  decisive <- data[data$outcome != 0L, , drop = FALSE]
  decisive$y <- as.integer(decisive$outcome == 1L)
  if (nrow(decisive) < 4L || length(unique(decisive$y)) < 2L) {
    cli::cli_warn(
      "Calibration data has too few decisive plies; returning a flat 0.5 calibrator."
    )
    fit <- structure(
      list(type = "logistic", a = 0, b = 0,
           n = as.integer(nrow(decisive)),
           brier = NA_real_, baseline_brier = NA_real_,
           reliability = .mxo_empty_reliability()),
      class = "mxo_calibrator"
    )
    return(fit)
  }
  if (type == "logistic") {
    glm_fit <- stats::glm(y ~ score, data = decisive, family = stats::binomial())
    cf <- stats::coef(glm_fit)
    cal <- list(type = "logistic",
                a = unname(cf[["score"]]),
                b = unname(cf[["(Intercept)"]]))
  } else {
    ord <- order(decisive$score)
    ir <- stats::isoreg(decisive$score[ord], decisive$y[ord])
    cal <- list(type = "isotonic",
                x = decisive$score[ord], y = ir$yf)
  }
  p <- .mxo_predict_calibrator(cal, decisive$score)
  cal$brier <- mean((p - decisive$y) ^ 2L)
  cal$baseline_brier <- mean((0.5 - decisive$y) ^ 2L)
  cal$n <- as.integer(nrow(decisive))
  cal$reliability <- .mxo_reliability_table(p, decisive$y)
  structure(cal, class = "mxo_calibrator")
}

.mxo_empty_reliability <- function() {
  tibble::tibble(
    bin = integer(0L), p_mean = numeric(0L),
    y_mean = numeric(0L), n = integer(0L)
  )
}

.mxo_reliability_table <- function(p, y, bins = 10L) {
  breaks <- seq(0, 1, length.out = bins + 1L)
  ix <- pmin(pmax(findInterval(p, breaks, rightmost.closed = TRUE), 1L), bins)
  tibble::tibble(
    bin = seq_len(bins),
    p_mean = vapply(seq_len(bins), function(i) {
      if (sum(ix == i) == 0L) NA_real_ else mean(p[ix == i])
    }, numeric(1L)),
    y_mean = vapply(seq_len(bins), function(i) {
      if (sum(ix == i) == 0L) NA_real_ else mean(y[ix == i])
    }, numeric(1L)),
    n = as.integer(vapply(seq_len(bins), function(i) sum(ix == i),
                          integer(1L)))
  )
}

# Predict win-probability from a calibrator + a numeric score vector.
.mxo_predict_calibrator <- function(cal, score) {
  if (identical(cal$type, "logistic")) {
    return(1 / (1 + exp(-(cal$a * score + cal$b))))
  }
  pred <- stats::approx(cal$x, cal$y, xout = score, rule = 2L)$y
  pmin(pmax(pred, 0), 1)
}

#' Apply a calibrator to a numeric score
#'
#' @param calibrator An `mxo_calibrator`.
#' @param score Numeric vector of heuristic scores.
#' @return Numeric vector of probabilities in `[0, 1]`.
#' @export
mxo_calibrator_predict <- function(calibrator, score) {
  call <- rlang::current_env()
  if (!inherits(calibrator, "mxo_calibrator")) {
    cli::cli_abort(
      "{.arg calibrator} must be an {.cls mxo_calibrator}.", call = call
    )
  }
  .mxo_predict_calibrator(calibrator, as.numeric(score))
}

#' Print a calibrator
#'
#' @param x An `mxo_calibrator`.
#' @param ... Unused.
#' @return Invisibly returns `x`.
#' @export
print.mxo_calibrator <- function(x, ...) {
  rlang::check_dots_empty()
  cli::cli_h1("mxo_calibrator")
  cli::cli_alert_info("Type: {x$type}")
  if (identical(x$type, "logistic")) {
    cli::cli_alert_info("a = {round(x$a, 6L)}, b = {round(x$b, 6L)}")
  }
  cli::cli_alert_info("n decisive plies: {x$n}")
  if (!is.na(x$brier)) {
    cli::cli_alert_info(
      "Brier: {round(x$brier, 4L)} (baseline {round(x$baseline_brier, 4L)})"
    )
  }
  invisible(x)
}
