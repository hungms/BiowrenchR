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
#' @param filename File name under `inst/extdata`
#' @return data.frame
#' @keywords internal
#' @noRd
.read_extdata_tsv <- function(filename) {
  utils::read.table(
    .extdata_path(filename),
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
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
  dict <- if (identical(org, "human")) {
    load_biomart_human(...)
  } else {
    load_biomart_mouse(...)
  }
  assign(key, dict, envir = .biowrenchR_env)
  dict
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

#' Validate a data frame or matrix with an optional gene column
#'
#' @param df A data frame or matrix.
#' @param gene_column Column name with gene symbols, or `NULL`.
#' @return A data frame.
#' @keywords internal
#' @noRd
validate_df <- function(df, gene_column = NULL) {
  if (!(is.data.frame(df) || is.matrix(df))) {
    stop("Input must be a data frame or matrix", call. = FALSE)
  }
  if (is.matrix(df)) {
    genes <- rownames(df)
    df <- as.data.frame(df, stringsAsFactors = FALSE)
    rownames(df) <- genes
  }
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
  if (!(is.data.frame(exprs) || is.matrix(exprs))) {
    stop("Input must be a data frame or matrix", call. = FALSE)
  }
  if (is.matrix(exprs)) {
    genes <- rownames(exprs)
    exprs <- as.data.frame(exprs, stringsAsFactors = FALSE)
    rownames(exprs) <- genes
  }
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
