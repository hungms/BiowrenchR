#' Build a gene-symbol conversion dictionary
#'
#' Returns source-to-target gene symbol mappings between human and mouse using
#' the joint BioMart dictionary from [load_biomart()].
#'
#' @param org.from Source organism (`"human"` or `"mouse"`).
#' @param org.to Target organism (`"human"` or `"mouse"`).
#' @return A data frame with source and target gene symbol columns.
#'
#' @examples
#' \dontrun{
#' dict <- get_conversion_dict("mouse", "human")
#' head(dict)
#' }
#'
#' @export
get_conversion_dict <- function(org.from, org.to) {
  validate_org(org.from)
  validate_org(org.to)
  if (identical(org.from, org.to)) {
    stop("org.from and org.to must differ", call. = FALSE)
  }

  biodict <- if (exists("biodict", envir = .biowrenchR_env, inherits = FALSE)) {
    get("biodict", envir = .biowrenchR_env, inherits = FALSE)
  } else {
    load_biomart()
  }

  source_col <- .symbol_col(org.from)
  target_col <- .symbol_col(org.to)
  biodict <- biodict[!is.na(biodict[[target_col]]) & grepl("[A-Za-z]", biodict[[target_col]]),
                     c(source_col, target_col),
                     drop = FALSE]
  biodict
}

#' Convert gene symbols between human and mouse
#'
#' @param genes Character vector of gene symbols to convert.
#' @param org.from Source organism (`"human"` or `"mouse"`).
#' @param org.to Target organism (`"human"` or `"mouse"`).
#' @param one.to.many If `TRUE`, return all unique target symbols. If `FALSE`
#'   (default), keep the first mapping per source gene.
#' @return Character vector of converted gene symbols.
#'
#' @examples
#' \dontrun{
#' convert_genes(c("Trp53", "Cd4"), org.from = "mouse", org.to = "human")
#' }
#'
#' @export
convert_genes <- function(genes,
                          org.from = "human",
                          org.to = "mouse",
                          one.to.many = FALSE) {
  validate_org(org.from, genes = genes)
  validate_org(org.to)
  if (identical(org.from, org.to)) {
    stop("org.from and org.to must differ", call. = FALSE)
  }

  biodict <- get_conversion_dict(org.from, org.to)
  source_col <- .symbol_col(org.from)
  target_col <- .symbol_col(org.to)

  genes_df <- data.frame(source_gene = genes, stringsAsFactors = FALSE)
  result <- dplyr::inner_join(
    genes_df,
    biodict,
    by = c("source_gene" = source_col)
  )

  if (isTRUE(one.to.many)) {
    return(unique(result[[target_col]]))
  }

  result |>
    dplyr::group_by(.data$source_gene) |>
    dplyr::slice(1L) |>
    dplyr::pull(!!rlang::sym(target_col))
}

#' Convert gene symbols in a data frame between species
#'
#' Joins ortholog mappings onto `df` and adds a target-organism gene column.
#'
#' @param df Data frame containing gene symbols.
#' @param gene_column Column name containing gene symbols.
#' @param org.from Source organism (`"human"` or `"mouse"`).
#' @param org.to Target organism (`"human"` or `"mouse"`).
#' @param one.to.many If `TRUE`, collapse multiple targets with `", "`. If
#'   `FALSE` (default), keep only the first target.
#' @return A data frame with an added target gene-symbol column.
#'
#' @examples
#' \dontrun{
#' convert_df(df, gene_column = "gene", org.from = "human", org.to = "mouse")
#' }
#'
#' @export
convert_df <- function(df,
                       gene_column,
                       org.from = "human",
                       org.to = "mouse",
                       one.to.many = FALSE) {
  df <- validate_df(df, gene_column)
  validate_org(org.from, genes = df[[gene_column]])
  validate_org(org.to)
  if (identical(org.from, org.to)) {
    stop("org.from and org.to must differ", call. = FALSE)
  }

  biodict <- get_conversion_dict(org.from, org.to)
  source_col <- .symbol_col(org.from)
  target_col <- .symbol_col(org.to)

  dict_summary <- biodict |>
    dplyr::group_by(!!rlang::sym(source_col)) |>
    dplyr::summarise(
      !!rlang::sym(target_col) := paste(!!rlang::sym(target_col), collapse = ", "),
      .groups = "drop"
    )

  converted_df <- dplyr::left_join(
    df,
    dict_summary,
    by = stats::setNames(source_col, gene_column)
  )

  if (!isTRUE(one.to.many)) {
    converted_df[[target_col]] <- sub(",.*", "", converted_df[[target_col]])
  }
  converted_df
}

#' Convert an expression matrix between species
#'
#' Maps rownames (gene symbols) from one organism to another. When
#' `many.to.one = TRUE`, multi-mapped genes are aggregated with
#' [summarize_genes()].
#'
#' @param exprs Expression matrix, data frame, or data.table (genes as rownames).
#' @param org.from Source organism (`"human"` or `"mouse"`).
#' @param org.to Target organism (`"human"` or `"mouse"`).
#' @param many.to.one If `TRUE` (default), allow many-to-one mappings and
#'   aggregate. If `FALSE`, keep only unique one-to-one mappings.
#' @param normalized Passed to [summarize_genes()] when aggregating (`mean` vs `sum`).
#' @return Converted expression data; aggregation path returns the same class
#'   conventions as [summarize_genes()].
#'
#' @examples
#' \dontrun{
#' convert_exprs(exprs, org.from = "human", org.to = "mouse")
#' }
#'
#' @export
convert_exprs <- function(exprs,
                          org.from = "human",
                          org.to = "mouse",
                          many.to.one = TRUE,
                          normalized = FALSE) {
  exprs <- validate_exprs(exprs)
  validate_org(org.from, genes = rownames(exprs))
  validate_org(org.to)
  if (identical(org.from, org.to)) {
    stop("org.from and org.to must differ", call. = FALSE)
  }

  biodict <- get_conversion_dict(org.from, org.to)
  source_col <- .symbol_col(org.from)
  target_col <- .symbol_col(org.to)

  if (isTRUE(many.to.one)) {
    converted <- exprs |>
      tibble::rownames_to_column("gene") |>
      tidyr::pivot_longer(-"gene", names_to = "sample", values_to = "exprs") |>
      dplyr::left_join(
        dplyr::distinct(biodict, !!rlang::sym(source_col), .keep_all = TRUE),
        by = c("gene" = source_col)
      ) |>
      dplyr::filter(!is.na(!!rlang::sym(target_col)), !!rlang::sym(target_col) != "NA") |>
      tidyr::pivot_wider(names_from = "sample", values_from = "exprs") |>
      dplyr::select(-"gene")

    gene_vec <- converted[[target_col]]
    converted[[target_col]] <- NULL
    return(summarize_genes(converted, gene_sym_vec = gene_vec, normalized = normalized))
  }

  dict_1to1 <- biodict |>
    dplyr::group_by(!!rlang::sym(source_col)) |>
    dplyr::mutate(n_source = dplyr::n()) |>
    dplyr::group_by(!!rlang::sym(target_col)) |>
    dplyr::mutate(n_target = dplyr::n()) |>
    dplyr::ungroup() |>
    dplyr::filter(.data$n_source == 1L, .data$n_target == 1L) |>
    dplyr::select(!!rlang::sym(source_col), !!rlang::sym(target_col))

  keep <- rownames(exprs) %in% dict_1to1[[source_col]]
  converted <- exprs[keep, , drop = FALSE]
  converted <- converted |>
    tibble::rownames_to_column("gene") |>
    dplyr::left_join(dict_1to1, by = c("gene" = source_col)) |>
    dplyr::select(-"gene") |>
    tibble::column_to_rownames(target_col)
  converted
}
