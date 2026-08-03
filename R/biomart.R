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
  if (isTRUE(local)) {
    dict <- .read_extdata_tsv(paste0("biodict_mouse_release-", release, ".tsv"))
    assign("biodict_mouse", dict, envir = .biowrenchR_env)
    return(dict)
  }

  mouse_biomart <- biomaRt::useMart(
    "ensembl",
    host = host,
    dataset = "mmusculus_gene_ensembl"
  )
  dict <- biomaRt::getBM(
    attributes = c("mgi_symbol", "chromosome_name"),
    mart = mouse_biomart
  )
  colnames(dict) <- c("mouse_gene_symbol", "mouse_chromosome")
  assign("biodict_mouse", dict, envir = .biowrenchR_env)
  dict
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
  if (isTRUE(local)) {
    dict <- .read_extdata_tsv(paste0("biodict_human_release-", release, ".tsv"))
    assign("biodict_human", dict, envir = .biowrenchR_env)
    return(dict)
  }

  human_biomart <- biomaRt::useMart(
    "ensembl",
    host = host,
    dataset = "hsapiens_gene_ensembl"
  )
  dict <- biomaRt::getBM(
    attributes = c("hgnc_symbol", "chromosome_name"),
    mart = human_biomart
  )
  colnames(dict) <- c("human_gene_symbol", "human_chromosome")
  assign("biodict_human", dict, envir = .biowrenchR_env)
  dict
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
    dict <- tryCatch(
      .read_extdata_tsv(paste0("biodict_release-", release, ".tsv")),
      error = function(e) {
        stop("Error reading biomart dictionary: ", conditionMessage(e), call. = FALSE)
      }
    )
    if (nrow(dict) == 0L) {
      stop("Biomart dictionary file is empty", call. = FALSE)
    }
    assign("biodict", dict, envir = .biowrenchR_env)
    return(dict)
  }

  human_biomart <- biomaRt::useMart(
    "ensembl",
    host = host,
    dataset = "hsapiens_gene_ensembl"
  )
  mouse_biomart <- biomaRt::useMart(
    "ensembl",
    host = host,
    dataset = "mmusculus_gene_ensembl"
  )

  biodict_mouse <- biomaRt::getLDS(
    attributes = c("mgi_symbol", "chromosome_name"),
    filters = "",
    values = NULL,
    mart = mouse_biomart,
    attributesL = c("hgnc_symbol", "chromosome_name"),
    martL = human_biomart,
    uniqueRows = FALSE
  )
  biodict_human <- biomaRt::getLDS(
    attributes = c("hgnc_symbol", "chromosome_name"),
    filters = "",
    values = NULL,
    mart = human_biomart,
    attributesL = c("mgi_symbol", "chromosome_name"),
    martL = mouse_biomart,
    uniqueRows = FALSE
  )

  biodict_mouse <- biodict_mouse |>
    dplyr::mutate(
      mouse_gene_symbol = .data$MGI.symbol,
      human_gene_symbol = .data$HGNC.symbol,
      mouse_chromosome = .data$Chromosome.scaffold.name,
      human_chromosome = .data$Chromosome.scaffold.name.1
    ) |>
    dplyr::select(
      "mouse_gene_symbol", "mouse_chromosome",
      "human_gene_symbol", "human_chromosome"
    ) |>
    dplyr::filter(
      stringr::str_detect(.data$mouse_gene_symbol, "[a-z]") |
        stringr::str_detect(.data$human_gene_symbol, "[A-Z]")
    )

  biodict_human <- biodict_human |>
    dplyr::mutate(
      human_gene_symbol = .data$HGNC.symbol,
      mouse_gene_symbol = .data$MGI.symbol,
      human_chromosome = .data$Chromosome.scaffold.name,
      mouse_chromosome = .data$Chromosome.scaffold.name.1
    ) |>
    dplyr::select(
      "mouse_gene_symbol", "mouse_chromosome",
      "human_gene_symbol", "human_chromosome"
    ) |>
    dplyr::filter(
      stringr::str_detect(.data$mouse_gene_symbol, "[a-z]") |
        stringr::str_detect(.data$human_gene_symbol, "[A-Z]")
    )

  dict <- dplyr::bind_rows(biodict_mouse, biodict_human) |>
    dplyr::distinct(
      .data$mouse_gene_symbol, .data$mouse_chromosome,
      .data$human_gene_symbol, .data$human_chromosome
    )
  assign("biodict", dict, envir = .biowrenchR_env)
  dict
}
