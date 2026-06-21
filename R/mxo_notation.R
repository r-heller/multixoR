# Ply notation per rules §8.
#
#   X present @ (0,0) [21]
#   O present @ (0,1) [37]
#   X branch  @ (0,0) [42] -> L1

# Regex parses the two notation forms. The `\\s+` after "branch" tolerates the
# extra space used to align columns in the worked example.
.mxo_ply_regex <- paste0(
  "^([XO])\\s+(present|branch)\\s*@\\s*\\(",
  "(-?\\d+),(-?\\d+)\\)\\s*\\[(-?\\d+)\\]",
  "(?:\\s*->\\s*L(-?\\d+))?\\s*$"
)

#' Serialize a ply record to canonical notation
#'
#' @param record A ply record (a named list with `player`, `kind`, `L_src`,
#'   `t_src`, `idx`, and, for branch plies, `L_new`).
#' @return A character scalar in the canonical notation.
#' @export
#' @examples
#' rec <- list(player = 1L, kind = "present", L_src = 0L,
#'             t_src = 0L, idx = 21L, L_new = NA_integer_)
#' mxo_format_ply(rec)
mxo_format_ply <- function(record) {
  call <- rlang::current_env()
  needed <- c("player", "kind", "L_src", "t_src", "idx")
  missing <- setdiff(needed, names(record))
  if (length(missing) > 0L) {
    cli::cli_abort(
      "{.arg record} is missing field{?s}: {.field {missing}}.",
      call = call
    )
  }
  player <- as.integer(record$player)
  if (!player %in% c(1L, 2L)) {
    cli::cli_abort(
      "{.field player} must be {.val 1} or {.val 2}.",
      call = call
    )
  }
  who <- if (player == 1L) "X" else "O"
  if (!record$kind %in% c("present", "branch")) {
    cli::cli_abort(
      "{.field kind} must be {.val present} or {.val branch}.",
      call = call
    )
  }
  base <- sprintf("%s %s @ (%d,%d) [%d]", who, record$kind,
                  as.integer(record$L_src), as.integer(record$t_src),
                  as.integer(record$idx))
  if (record$kind == "branch") {
    L_new <- record$L_new
    if (is.null(L_new) || is.na(L_new)) {
      cli::cli_abort(
        "Branch ply {.field record} must include a non-NA {.field L_new}.",
        call = call
      )
    }
    return(sprintf("%s -> L%d", base, as.integer(L_new)))
  }
  base
}

#' Parse a ply notation string into a record
#'
#' Inverse of [mxo_format_ply()]. Branch plies populate `L_new`; present plies
#' set it to `NA_integer_`.
#'
#' @param string A character scalar.
#' @return A list with components `player`, `kind`, `L_src`, `t_src`, `idx`,
#'   and `L_new` (NA for present plies).
#' @export
#' @examples
#' mxo_parse_ply("X present @ (0,0) [21]")
#' mxo_parse_ply("X branch  @ (0,0) [42] -> L1")
mxo_parse_ply <- function(string) {
  call <- rlang::current_env()
  if (!is.character(string) || length(string) != 1L) {
    cli::cli_abort(
      "{.arg string} must be a character scalar.",
      call = call
    )
  }
  m <- regmatches(string, regexec(.mxo_ply_regex, string, perl = TRUE))[[1L]]
  if (length(m) == 0L) {
    cli::cli_abort(
      "Could not parse {.val {string}} as a multixoR ply.",
      call = call
    )
  }
  player <- if (m[[2L]] == "X") 1L else 2L
  kind <- m[[3L]]
  L_src <- as.integer(m[[4L]])
  t_src <- as.integer(m[[5L]])
  idx <- as.integer(m[[6L]])
  L_new_raw <- m[[7L]]
  L_new <- if (nzchar(L_new_raw)) as.integer(L_new_raw) else NA_integer_
  if (kind == "branch" && is.na(L_new)) {
    cli::cli_abort(
      "Branch ply notation must include {.code -> L<new>}; got {.val {string}}.",
      call = call
    )
  }
  if (kind == "present" && !is.na(L_new)) {
    cli::cli_abort(
      "Present ply notation must not include {.code -> L<new>}; got {.val {string}}.",
      call = call
    )
  }
  list(player = player, kind = kind, L_src = L_src,
       t_src = t_src, idx = idx, L_new = L_new)
}
