#' Load mouse BioMart gene dictionary
#'
#' Returns mouse gene symbols and chromosome names, either from packaged
#' extdata (`local = TRUE`) or live Ensembl BioMart (`local = FALSE`).
#'
#' @param host Ensembl archive host URL used when `local = FALSE`.
#' @param local If `TRUE`, read `biodict_mouse_release-<release>.tsv` from
#'   package extdata. If `FALSE`, query Ensembl.
#' @param release Ensembl release tag used for the local file name. Default `"105"`.
#' @return A data frame with columns `mouse_gene_symbol` and `mouse_chromosome`.
#'
#' @examples
#' \dontrun{
#' biodict_mouse <- load_biomart_mouse()
#' head(biodict_mouse)
#' }
#'
#' @export
load_biomart_mouse <- function(host = "https://dec2021.archive.ensembl.org",
                               local = TRUE,
                               release = "105") {
  .load_org_biomart("mouse", host, local, release)
}

#' Load human BioMart gene dictionary
#'
#' Returns human gene symbols and chromosome names, either from packaged
#' extdata (`local = TRUE`) or live Ensembl BioMart (`local = FALSE`).
#'
#' @param host Ensembl archive host URL used when `local = FALSE`.
#' @param local If `TRUE`, read `biodict_human_release-<release>.tsv` from
#'   package extdata. If `FALSE`, query Ensembl.
#' @param release Ensembl release tag used for the local file name. Default `"105"`.
#' @return A data frame with columns `human_gene_symbol` and `human_chromosome`.
#'
#' @examples
#' \dontrun{
#' biodict_human <- load_biomart_human()
#' head(biodict_human)
#' }
#'
#' @export
load_biomart_human <- function(host = "https://dec2021.archive.ensembl.org",
                               local = TRUE,
                               release = "105") {
  .load_org_biomart("human", host, local, release)
}

#' Load human-mouse BioMart ortholog dictionary
#'
#' Returns a joint mapping between mouse and human gene symbols (and chromosomes),
#' either from packaged extdata or via linked Ensembl datasets.
#'
#' @param host Ensembl archive host URL used when `local = FALSE`.
#' @param local If `TRUE`, read `biodict_release-<release>.tsv` from package
#'   extdata. If `FALSE`, query Ensembl with `biomaRt::getLDS()`.
#' @param release Ensembl release tag used for the local file name. Default `"105"`.
#' @return A data frame with columns `mouse_gene_symbol`, `mouse_chromosome`,
#'   `human_gene_symbol`, and `human_chromosome`.
#'
#' @examples
#' \dontrun{
#' biodict <- load_biomart()
#' head(biodict)
#' }
#'
#' @export
load_biomart <- function(host = "https://dec2021.archive.ensembl.org",
                         local = TRUE,
                         release = "105") {
  if (isTRUE(local)) {
    dict <- .read_extdata_tsv(paste0("biodict_release-", release, ".tsv"))
    if (nrow(dict) == 0L) {
      stop("Biomart dictionary file is empty", call. = FALSE)
    }
  } else {
    human <- .ensembl_mart("human", host)
    mouse <- .ensembl_mart("mouse", host)
    dict <- dplyr::bind_rows(
      .lds_dict(mouse, human, first = "mouse"),
      .lds_dict(human, mouse, first = "human")
    ) |>
      dplyr::filter(
        stringr::str_detect(.data$mouse_gene_symbol, "[a-z]") |
          stringr::str_detect(.data$human_gene_symbol, "[A-Z]")
      ) |>
      dplyr::distinct()
  }
  assign("biodict", dict, envir = .biowrenchR_env)
  dict
}

# Internal ----------------------------------------------------------------

.mart_info <- list(
  human = list(dataset = "hsapiens_gene_ensembl", symbol = "hgnc_symbol"),
  mouse = list(dataset = "mmusculus_gene_ensembl", symbol = "mgi_symbol")
)

#' @noRd
.ensembl_mart <- function(org, host) {
  biomaRt::useMart("ensembl", host = host, dataset = .mart_info[[org]]$dataset)
}

#' Load (and cache) a single-organism symbol/chromosome dictionary
#' @noRd
.load_org_biomart <- function(org, host, local, release) {
  dict <- if (isTRUE(local)) {
    .read_extdata_tsv(paste0("biodict_", org, "_release-", release, ".tsv"))
  } else {
    stats::setNames(
      biomaRt::getBM(
        attributes = c(.mart_info[[org]]$symbol, "chromosome_name"),
        mart = .ensembl_mart(org, host)
      ),
      c(.symbol_col(org), .chrom_col(org))
    )
  }
  assign(paste0("biodict_", org), dict, envir = .biowrenchR_env)
  dict
}

#' Linked-dataset query `mart` -> `martL`, returned with standard column names
#' @noRd
.lds_dict <- function(mart, martL, first) {
  second <- setdiff(c("human", "mouse"), first)
  res <- biomaRt::getLDS(
    attributes = c(.mart_info[[first]]$symbol, "chromosome_name"),
    filters = "",
    values = NULL,
    mart = mart,
    attributesL = c(.mart_info[[second]]$symbol, "chromosome_name"),
    martL = martL,
    uniqueRows = FALSE
  )
  # getLDS returns columns in order: symbol, chrom, symbolL, chromL
  res <- stats::setNames(
    res[, 1:4],
    c(.symbol_col(first), .chrom_col(first), .symbol_col(second), .chrom_col(second))
  )
  res[, c("mouse_gene_symbol", "mouse_chromosome", "human_gene_symbol", "human_chromosome")]
}
