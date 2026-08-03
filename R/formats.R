# Format I/O: list/data-frame helpers, GMT, GCT

#' Convert a list of vectors to a data frame
#'
#' Pads shorter vectors with empty strings so all columns share the same length.
#'
#' @param x A list of vectors (typically character).
#' @return A data frame with one column per list element.
#'
#' @examples
#' my_list <- list(a = c("A", "B", "C"), b = c("D", "E"))
#' list_to_df(my_list)
#'
#' @export
list_to_df <- function(x) {
  if (!is.list(x)) {
    stop("Input must be a list", call. = FALSE)
  }
  if (length(x) == 0L) {
    return(data.frame())
  }
  max_length <- max(vapply(x, length, integer(1L)))
  padded <- lapply(x, function(v) {
    c(as.character(v), rep("", max_length - length(v)))
  })
  as.data.frame(padded, stringsAsFactors = FALSE, check.names = FALSE)
}

#' Convert a data frame to a list of vectors
#'
#' Drops `NA`, empty strings, and the literal string `"NA"` from each column.
#'
#' @param df A data frame.
#' @return A named list of character vectors (one per column).
#'
#' @examples
#' my_df <- data.frame(a = c("A", "B", ""), b = c("D", "E", NA))
#' df_to_list(my_df)
#'
#' @export
df_to_list <- function(df) {
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  lapply(df, function(col) {
    col <- as.character(col)
    col[!is.na(col) & nzchar(col) & col != "NA"]
  })
}


#' Read a GMT gene-set file
#'
#' Reads a Gene Matrix Transposed (GMT) file into a wide data frame where each
#' column is a gene set and cells contain member gene symbols (padded with `NA`).
#'
#' @param gmt Path to a GMT file.
#' @return A data frame of gene membership by gene set.
#'
#' @examples
#' \dontrun{
#' gmt_data <- read_gmt("path/to/genesets.gmt")
#' head(gmt_data)
#' }
#'
#' @export
read_gmt <- function(gmt) {
  if (!file.exists(gmt)) {
    stop("GMT file not found: ", gmt, call. = FALSE)
  }
  lines <- readLines(gmt, warn = FALSE)
  if (length(lines) == 0L) {
    return(data.frame())
  }
  split_lines <- strsplit(lines, "\t", fixed = TRUE)
  max_cols <- max(lengths(split_lines))
  padded <- lapply(split_lines, function(row) {
    length(row) <- max_cols
    row
  })
  mat <- do.call(rbind, padded)
  gene_set_names <- mat[, 1L]
  mat_genes <- mat[, -c(1L, 2L), drop = FALSE]
  df <- as.data.frame(t(mat_genes), stringsAsFactors = FALSE)
  colnames(df) <- gene_set_names
  rownames(df) <- NULL
  df
}

#' Write a GMT gene-set file
#'
#' Writes a data frame (columns = gene sets) or a named list of character
#' vectors to GMT format. Description fields are set to the gene-set name.
#'
#' @param input A data frame of gene sets, or a named list of character vectors.
#' @param file Output file path.
#' @return The output path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_gmt(gene_sets_df, "my_genesets.gmt")
#' write_gmt(
#'   list(pathway1 = c("gene1", "gene2"), pathway2 = c("gene2", "gene4")),
#'   "my_genesets.gmt"
#' )
#' }
#'
#' @export
write_gmt <- function(input, file) {
  if (!is.character(file) || length(file) != 1L || !nzchar(file)) {
    stop("File path must be a non-empty character string", call. = FALSE)
  }
  out_dir <- dirname(file)
  if (!dir.exists(out_dir)) {
    stop("Directory does not exist: ", out_dir, call. = FALSE)
  }

  if (is.list(input) && !is.data.frame(input)) {
    if (is.null(names(input)) || any(!nzchar(names(input)))) {
      stop("List must have non-empty names", call. = FALSE)
    }
    if (!all(vapply(input, is.character, logical(1L)))) {
      stop("List must contain character vectors", call. = FALSE)
    }
    input <- list_to_df(input)
  }
  if (!is.data.frame(input)) {
    stop("Input must be a data frame or a named list of character vectors", call. = FALSE)
  }

  con <- file(file, open = "wt")
  on.exit(close(con), add = TRUE)

  for (gene_set_name in colnames(input)) {
    genes <- as.character(input[[gene_set_name]])
    genes <- genes[!is.na(genes) & nzchar(genes)]
    line <- c(gene_set_name, gene_set_name, genes)
    writeLines(paste(line, collapse = "\t"), con)
  }
  message("GMT file written to ", file)
  invisible(file)
}


#' Read a GCT expression file
#'
#' Reads a Gene Cluster Text (GCT) file into a gene-by-sample data frame.
#' The Description column is dropped when present.
#'
#' @param gct Path to a GCT file.
#' @return A data frame with genes as rows and samples as columns.
#'
#' @examples
#' \dontrun{
#' gct_data <- read_gct("path/to/expression.gct")
#' head(gct_data)
#' }
#'
#' @export
read_gct <- function(gct) {
  if (!file.exists(gct)) {
    stop("GCT file not found: ", gct, call. = FALSE)
  }
  gct_df <- utils::read.table(
    gct,
    sep = "\t",
    header = TRUE,
    row.names = 1L,
    skip = 2L,
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
  if (ncol(gct_df) < 1L) {
    stop("Invalid GCT file format", call. = FALSE)
  }
  if ("Description" %in% colnames(gct_df)) {
    gct_df[["Description"]] <- NULL
  } else {
    gct_df <- gct_df[, -1L, drop = FALSE]
  }
  gct_df
}

#' Write a GCT expression file
#'
#' Writes a gene-by-sample data frame as a GCT 1.3 file. Row names are used for
#' both Name and Description columns.
#'
#' @param df Data frame to save (genes as rows, samples as columns).
#' @param file Output file path.
#' @return The output path, invisibly.
#'
#' @examples
#' \dontrun{
#' write_gct(expression_df, "output/my_expression.gct")
#' }
#'
#' @export
write_gct <- function(df, file) {
  if (!is.data.frame(df)) {
    stop("Input must be a data frame", call. = FALSE)
  }
  if (!is.character(file) || length(file) != 1L || !nzchar(basename(file))) {
    stop("Output filename cannot be empty", call. = FALSE)
  }
  out_dir <- dirname(file)
  if (!dir.exists(out_dir)) {
    stop("Output directory does not exist: ", out_dir, call. = FALSE)
  }

  n_genes <- nrow(df)
  n_samples <- ncol(df)
  gct_mat <- matrix("", nrow = n_genes + 3L, ncol = n_samples + 2L)
  gct_mat[1L, 1L] <- "#1.3"
  gct_mat[2L, 1:2] <- c(as.character(n_genes), as.character(n_samples))
  gct_mat[3L, 1:2] <- c("Name", "Description")
  if (n_samples > 0L) {
    gct_mat[3L, 3:ncol(gct_mat)] <- colnames(df)
  }
  if (n_genes > 0L) {
    rn <- rownames(df)
    if (is.null(rn)) {
      rn <- as.character(seq_len(n_genes))
    }
    gct_mat[4:nrow(gct_mat), 1L] <- rn
    gct_mat[4:nrow(gct_mat), 2L] <- rn
    gct_mat[4:nrow(gct_mat), 3:ncol(gct_mat)] <- as.matrix(df)
  }

  utils::write.table(
    as.data.frame(gct_mat, stringsAsFactors = FALSE),
    file = file,
    col.names = FALSE,
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
  )
  invisible(file)
}
