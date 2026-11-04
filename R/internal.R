# Internal helpers: cache, extdata I/O, validation, BioMart accessors.
# Not exported.

#' Package-level cache environment
#'
#' Stores BioMart dictionaries between calls without polluting the global
#' environment.
#'
#' @keywords internal
#' @noRd
.biowrenchR_env <- new.env(parent = emptyenv())

#' Resolve path to a packaged extdata file
#'
#' @param filename File name under `inst/extdata`
#' @return Absolute path
#' @keywords internal
#' @noRd
.extdata_path <- function(filename) {
  pkg_dir <- system.file("extdata", package = "biowrenchR")
  if (!nzchar(pkg_dir)) {
    stop("Package directory not found. Is biowrenchR installed correctly?", call. = FALSE)
  }
  path <- file.path(pkg_dir, filename)
  if (!file.exists(path)) {
    stop("Required extdata file not found: ", path, call. = FALSE)
  }
  path
}

#' Read a TSV from package extdata
#'
#' Quote and comment characters are disabled so that `'`, `"` or `#` inside
#' annotation text cannot silently truncate or merge rows.
#'
#' @param filename File name under `inst/extdata`
#' @param cache If `TRUE`, keep the parsed table in `.biowrenchR_env` and
#'   reuse it on later calls (keyed by `filename`).
#' @return data.frame
#' @keywords internal
#' @noRd
.read_extdata_tsv <- function(filename, cache = FALSE) {
  key <- paste0("extdata:", filename)
  if (cache && exists(key, envir = .biowrenchR_env, inherits = FALSE)) {
    return(get(key, envir = .biowrenchR_env, inherits = FALSE))
  }
  df <- utils::read.table(
    .extdata_path(filename),
    header = TRUE,
    sep = "\t",
    quote = "",
    comment.char = "",
    strip.white = TRUE,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if (cache) assign(key, df, envir = .biowrenchR_env)
  df
}

#' Column name helpers for organism dictionaries
#' @keywords internal
#' @noRd
.symbol_col <- function(org) paste0(org, "_gene_symbol")

#' @keywords internal
#' @noRd
.chrom_col <- function(org) paste0(org, "_chromosome")

#' Load and cache an organism BioMart dictionary
#'
#' @param org `"human"` or `"mouse"`
#' @param ... Passed to [load_biomart_human()] / [load_biomart_mouse()]
#' @return data.frame
#' @keywords internal
#' @noRd
.get_org_biomart <- function(org, ...) {
  validate_org(org)
  key <- paste0("biodict_", org)
  if (exists(key, envir = .biowrenchR_env, inherits = FALSE)) {
    return(get(key, envir = .biowrenchR_env, inherits = FALSE))
  }
  # loaders cache their result in .biowrenchR_env
  if (identical(org, "human")) load_biomart_human(...) else load_biomart_mouse(...)
}

#' Validate organism parameter
#'
#' @param org Organism, either `"human"` or `"mouse"`.
#' @param genes Optional gene symbols to sanity-check against organism casing.
#' @return Invisibly returns `TRUE` on success.
#' @keywords internal
#' @noRd
validate_org <- function(org, genes = NULL) {
  if (!org %in% c("human", "mouse")) {
    stop("org must be either 'human' or 'mouse'", call. = FALSE)
  }
  if (!is.null(genes)) {
    genes <- genes[!is.na(genes)]
    if (length(genes) == 0L) {
      return(invisible(TRUE))
    }
    has_lower <- grepl("[a-z]", genes)
    if (identical(org, "mouse") && !any(has_lower)) {
      stop("Mouse gene symbols are expected to contain lowercase letters", call. = FALSE)
    }
    if (identical(org, "human") && all(has_lower)) {
      stop("Human gene symbols are not expected to be all-lowercase", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Coerce a matrix to a data frame (keeping rownames); error on other types
#' @keywords internal
#' @noRd
.as_df <- function(x) {
  if (is.matrix(x)) x <- as.data.frame(x, stringsAsFactors = FALSE)
  if (!is.data.frame(x)) stop("Input must be a data frame or matrix", call. = FALSE)
  x
}

#' Validate a data frame or matrix with an optional gene column
#'
#' @param df A data frame or matrix.
#' @param gene_column Column name with gene symbols, or `NULL`.
#' @return A data frame.
#' @keywords internal
#' @noRd
validate_df <- function(df, gene_column = NULL) {
  df <- .as_df(df)
  if (!is.null(gene_column)) {
    if (!gene_column %in% names(df)) {
      stop("Gene column '", gene_column, "' not found in data frame", call. = FALSE)
    }
    orig_rows <- nrow(df)
    keep <- !is.na(df[[gene_column]]) & grepl("[A-Za-z]", df[[gene_column]])
    df <- df[keep, , drop = FALSE]
    removed <- orig_rows - nrow(df)
    if (removed > 0L) {
      message("Removed ", removed, " rows with NA or invalid gene symbols")
    }
  }
  df
}

#' Validate expression data with gene symbols as rownames
#'
#' @param exprs Expression matrix or data frame.
#' @return A data frame with valid gene rownames.
#' @keywords internal
#' @noRd
validate_exprs <- function(exprs) {
  exprs <- .as_df(exprs)
  rn <- rownames(exprs)
  valid_idx <- !is.na(rn) &
    !grepl("^NA(\\.[0-9]+)?$", rn) &
    grepl("[A-Za-z]", rn)
  removed <- sum(!valid_idx)
  if (removed > 0L) {
    message("Removed ", removed, " rows with NA or invalid gene symbols")
  }
  exprs[valid_idx, , drop = FALSE]
}

#' Null-default operator (base R only provides this from 4.4)
#'
#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x
