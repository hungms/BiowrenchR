# Gene-set helpers and family regex patterns

#' Regular expression for BCR genes
#'
#' @format Character string regex.
#' @export
bcr_pattern <- "^I[Gg][HKLhkl][VDJCAEMGLvdjcaemgl]|^AC233755"

#' Regular expression for TCR genes
#'
#' @format Character string regex.
#' @export
tcr_pattern <- "^T[Rr][ABCDGabcdg][VDJCvdjc]"

#' Regular expression for hemoglobin genes
#'
#' @format Character string regex.
#' @export
hb_pattern <- "^H[B][ABDEGMPQZ]?\\d*$|^H[b][abdegmpqz]?\\d*"

#' Regular expression for MHC genes
#'
#' @format Character string regex.
#' @export
mhc_pattern <- "^HLA-|^H2-"

#' Regular expression for ribosomal protein genes
#'
#' @format Character string regex.
#' @export
rb_pattern <- "^R[Pp][SsLl]"

#' Regular expression for mitochondrially encoded gene symbols (`MT-` / `mt-`)
#'
#' @format Character string regex.
#' @export
mt_pattern <- "^[Mm][Tt]-"


#' Unique gene symbols on given chromosomes
#'
#' @param org `"human"` or `"mouse"`
#' @param chromosomes Character vector of chromosome names
#' @param ... Passed to `.get_org_biomart`
#' @return Character vector of gene symbols
#' @keywords internal
#' @noRd
.genes_on_chromosomes <- function(org, chromosomes, ...) {
  dict <- .get_org_biomart(org, ...)
  sym <- .symbol_col(org)
  chr <- .chrom_col(org)
  genes <- unique(dict[[sym]][dict[[chr]] %in% chromosomes])
  genes <- genes[!is.na(genes) & nzchar(genes)]
  if (length(genes) == 0L) {
    warning(
      "No genes found on chromosome(s) ",
      paste(chromosomes, collapse = ", "),
      " for organism: ", org,
      call. = FALSE
    )
  }
  genes
}

#' Genes on X and Y chromosomes
#'
#' @param org Organism to query (`"human"` or `"mouse"`).
#' @param ... Additional arguments passed to [load_biomart_human()] /
#'   [load_biomart_mouse()].
#' @return Character vector of gene symbols on chromosomes X and Y.
#'
#' @examples
#' \dontrun{
#' xy_genes("human")
#' }
#'
#' @export
xy_genes <- function(org, ...) {
  .genes_on_chromosomes(org, chromosomes = c("X", "Y"), ...)
}

#' Mitochondrial genes
#'
#' @param org Organism to query (`"human"` or `"mouse"`).
#' @param ... Additional arguments passed to [load_biomart_human()] /
#'   [load_biomart_mouse()].
#' @return Character vector of mitochondrial gene symbols.
#'
#' @examples
#' \dontrun{
#' mt_genes("human")
#' }
#'
#' @export
mt_genes <- function(org, ...) {
  .genes_on_chromosomes(org, chromosomes = "MT", ...)
}

#' Cell-cycle gene sets
#'
#' Reads packaged cell-cycle gene tables for the requested organism.
#'
#' @param org Organism (`"human"` or `"mouse"`).
#' @return A named list of character vectors (one per cell-cycle gene set).
#'
#' @examples
#' \dontrun{
#' cell_cycle_genes("human")
#' }
#'
#' @export
cell_cycle_genes <- function(org) {
  validate_org(org)
  cc_df <- .read_extdata_tsv(paste0("cellcycle_", org, "_genes.tsv"))
  df_to_list(cc_df)
}

#' Genes matching predefined family patterns
#'
#' Filters BioMart gene symbols with regex patterns for BCR, TCR, MHC,
#' hemoglobin, ribosomal, or mitochondrially encoded (`MT-`) genes.
#' Pattern constants such as [bcr_pattern] are defined in this file.
#'
#' @param org Organism to query (`"human"` or `"mouse"`).
#' @param patterns Character vector of pattern keys. Valid values:
#'   `"bcr"`, `"tcr"`, `"mhc"`, `"hb"`, `"rb"`, `"mt"`.
#' @param ... Additional arguments passed to [load_biomart_human()] /
#'   [load_biomart_mouse()].
#' @return Character vector of matching gene symbols.
#'
#' @examples
#' \dontrun{
#' genes_by_pattern("human", "rb")
#' genes_by_pattern("mouse", c("bcr", "tcr"))
#' }
#'
#' @export
genes_by_pattern <- function(org, patterns, ...) {
  validate_org(org)

  valid_patterns <- c("bcr", "tcr", "mhc", "hb", "rb", "mt")
  if (!all(patterns %in% valid_patterns)) {
    invalid <- unique(patterns[!patterns %in% valid_patterns])
    stop(
      "Invalid pattern(s): ", paste(invalid, collapse = ", "),
      ". Valid patterns are: ", paste(valid_patterns, collapse = ", "),
      call. = FALSE
    )
  }

  pattern_map <- list(
    bcr = bcr_pattern,
    tcr = tcr_pattern,
    mhc = mhc_pattern,
    hb = hb_pattern,
    rb = rb_pattern,
    mt = mt_pattern
  )
  pattern_string <- paste(unlist(pattern_map[patterns], use.names = FALSE), collapse = "|")

  dict <- .get_org_biomart(org, ...)
  sym <- .symbol_col(org)
  genes <- unique(dict[[sym]][stringr::str_detect(dict[[sym]], pattern_string)])
  genes <- genes[!is.na(genes) & nzchar(genes)]

  if (length(genes) == 0L) {
    warning(
      "No genes found matching patterns: ", paste(patterns, collapse = ", "),
      " for organism: ", org,
      call. = FALSE
    )
  }
  genes
}
