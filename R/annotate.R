#' Join OmniPath gene annotations
#'
#' Adds precomputed OmniPath annotation columns to a data frame of gene
#' symbols. Requires packaged extdata file
#' `omnipathdb_<org.from>_release-<release>.tsv`.
#'
#' @param df Data frame containing gene symbols.
#' @param gene_column Name of the column containing gene symbols. Default `"gene"`.
#' @param org.from Organism of the input symbols (`"human"` or `"mouse"`).
#' @param org.to Target organism column retained from the annotation table
#'   (`"human"` or `"mouse"`).
#' @param release Ensembl/annotation release tag for the extdata file. Default `"105"`.
#' @param one.to.many If `FALSE` (default), keep only the first target ortholog
#'   when multiple are present (comma-separated). If `TRUE`, keep the full string.
#' @return A data frame with annotation columns left-joined onto `df`.
#'
#' @examples
#' \dontrun{
#' annotate_genes(df, gene_column = "gene", org.from = "human", org.to = "mouse")
#' }
#'
#' @export
annotate_genes <- function(df,
                           gene_column = "gene",
                           org.from = "human",
                           org.to = "mouse",
                           release = "105",
                           one.to.many = FALSE) {
  df <- validate_df(df, gene_column)
  validate_org(org.from, genes = df[[gene_column]])
  validate_org(org.to)

  annot <- .read_extdata_tsv(
    paste0("omnipathdb_", org.from, "_release-", release, ".tsv")
  )

  source_sym <- .symbol_col(org.from)
  if (!source_sym %in% names(annot)) {
    stop("Annotation table is missing column: ", source_sym, call. = FALSE)
  }
  names(annot)[names(annot) == source_sym] <- gene_column

  result <- dplyr::left_join(df, annot, by = gene_column)

  if (!isTRUE(one.to.many)) {
    target_col <- .symbol_col(org.to)
    if (target_col %in% names(result)) {
      result[[target_col]] <- sub(",.*", "", result[[target_col]])
    }
  }
  result
}
