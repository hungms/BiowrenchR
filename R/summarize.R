#' Summarize isoform-level expression to genes
#'
#' Aggregates rows that share the same gene symbol by sum (default) or mean.
#'
#' @param input Gene expression data with isoforms/peaks in rows and samples in
#'   columns. Accepts a data frame, data.table, or matrix.
#' @param gene_sym_vec Gene symbols corresponding to each row of `input`.
#' @param normalized If `TRUE`, aggregate with mean; if `FALSE` (default), sum.
#' @return Object of the same broad class as `input` (matrix / data.table /
#'   data.frame) with unique gene rownames.
#'
#' @examples
#' mat <- matrix(1:6, nrow = 3, dimnames = list(NULL, c("s1", "s2")))
#' summarize_genes(mat, gene_sym_vec = c("A", "A", "B"))
#'
#' @importFrom data.table := .SD
#' @export
summarize_genes <- function(input, gene_sym_vec, normalized = FALSE) {
  if (nrow(input) == 0L || ncol(input) == 0L) {
    stop("Input cannot be empty", call. = FALSE)
  }
  if (length(gene_sym_vec) != nrow(input)) {
    stop("gene_sym_vec must have the same length as the number of rows", call. = FALSE)
  }
  if (anyNA(gene_sym_vec)) {
    stop("gene_sym_vec cannot contain NA values", call. = FALSE)
  }

  is_matrix <- is.matrix(input)
  is_dt <- data.table::is.data.table(input)
  orig_colnames <- colnames(input)

  dt <- if (is_dt) {
    data.table::copy(input)
  } else {
    data.table::as.data.table(input)
  }

  dt[, "Gene.Name" := gene_sym_vec]
  data.table::setkeyv(dt, "Gene.Name")

  result <- if (isTRUE(normalized)) {
    dt[, lapply(.SD, mean, na.rm = TRUE), by = "Gene.Name"]
  } else {
    dt[, lapply(.SD, sum, na.rm = TRUE), by = "Gene.Name"]
  }

  gene_col <- result[["Gene.Name"]]
  result[, "Gene.Name" := NULL]

  if (is_matrix) {
    result_mat <- as.matrix(result)
    if (!is.null(orig_colnames)) {
      result_mat <- result_mat[, orig_colnames, drop = FALSE]
    }
    rownames(result_mat) <- gene_col
    return(result_mat)
  }

  if (is_dt) {
    data.table::setattr(result, "row.names", gene_col)
    return(result[])
  }

  out <- as.data.frame(result)
  rownames(out) <- gene_col
  out
}
