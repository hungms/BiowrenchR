# Crick Institute sample-sheet / FASTQ formatting helpers
#
# These helpers reshape lab sample sheets and sequencing drop folders into
# templates used by common nf-core / Cell Ranger pipelines at the Crick.

#' Print file contents to the console
#'
#' Thin wrapper around [readLines()] + [cat()] for quick inspection of text
#' files (sample sheets, configs, logs).
#'
#' @param dir Path to a text file.
#' @param n Maximum number of lines to print. Default `-1L` prints all lines.
#' @return Invisibly returns the character vector of lines.
#'
#' @examples
#' \dontrun{
#' cat_content("samplesheet.csv", n = 20)
#' }
#'
#' @export
cat_content <- function(dir, n = -1L) {
  if (!file.exists(dir)) {
    stop("File not found: ", dir, call. = FALSE)
  }
  content <- readLines(dir, n = n, warn = FALSE)
  cat(content, sep = "\n")
  invisible(content)
}

#' List dated FASTQ drop folders under a Crick sequencing directory
#'
#' Expects `dir` to contain dated subdirectories, each with a `fastq/` folder.
#'
#' @param dir Path to the parent sequencing directory.
#' @return Character vector of absolute `.../fastq/` paths that exist.
#' @noRd
.crick_fastq_dirs <- function(dir) {
  if (!dir.exists(dir)) {
    stop("Directory not found: ", dir, call. = FALSE)
  }
  dates <- list.files(dir, full.names = TRUE)
  fastq_dirs <- file.path(dates, "fastq")
  fastq_dirs[dir.exists(fastq_dirs)]
}

#' Match sample-sheet rows to paired FASTQ files in Crick drop folders
#'
#' Shared backend for [prepare_crick_rnaseq()] and [prepare_crick_atacseq()].
#'
#' @param dir Parent sequencing directory (dated subfolders with `fastq/`).
#' @param sheet Sample sheet with at least `Sample Name` and `Sample limsid`.
#' @param keep_cols Column names to retain from `sheet` (in order).
#' @return Data frame with sample columns plus `fastq_1` and `fastq_2`.
#' @noRd
.prepare_crick_paired <- function(dir, sheet, keep_cols) {
  required <- unique(c("Sample Name", "Sample limsid", keep_cols))
  missing <- setdiff(required, colnames(sheet))
  if (length(missing) > 0L) {
    stop(
      "Sample sheet missing column(s): ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  fastq_dirs <- .crick_fastq_dirs(dir)
  if (length(fastq_dirs) == 0L) {
    stop("No dated */fastq/ directories found under: ", dir, call. = FALSE)
  }

  sheet_list <- vector("list", length(fastq_dirs))
  fastq_1 <- vector("list", length(fastq_dirs))
  fastq_2 <- vector("list", length(fastq_dirs))

  for (i in seq_along(fastq_dirs)) {
    files_full <- sort(list.files(fastq_dirs[[i]], full.names = TRUE))
    files_base <- basename(files_full)
    lims_ids <- sub("_.*", "", files_base)

    fastq_1[[i]] <- files_full[grepl("_R1_", files_base, fixed = TRUE)]
    fastq_2[[i]] <- files_full[grepl("_R2_", files_base, fixed = TRUE)]

    hit <- sheet[["Sample limsid"]] %in% unique(lims_ids)
    sheet_list[[i]] <- as.data.frame(sheet[hit, keep_cols, drop = FALSE])
    sheet_list[[i]] <- sheet_list[[i]][
      order(sheet_list[[i]][["Sample limsid"]]),
      ,
      drop = FALSE
    ]
  }

  output <- dplyr::bind_rows(sheet_list)
  output$fastq_1 <- unlist(fastq_1, use.names = FALSE)
  output$fastq_2 <- unlist(fastq_2, use.names = FALSE)

  if (nrow(output) == 0L) {
    stop("No samples matched between sheet and FASTQ folders", call. = FALSE)
  }
  if (length(output$fastq_1) != nrow(output) ||
      length(output$fastq_2) != nrow(output)) {
    stop("FASTQ path count does not match sample-sheet rows", call. = FALSE)
  }

  ok <- vapply(seq_len(nrow(output)), function(i) {
    id <- as.character(output[["Sample limsid"]][[i]])
    grepl(id, output$fastq_1[[i]], fixed = TRUE) &&
      grepl(id, output$fastq_2[[i]], fixed = TRUE)
  }, logical(1L))
  if (!all(ok)) {
    stop(
      "Sample limsid did not match FASTQ paths for row(s): ",
      paste(which(!ok), collapse = ", "),
      call. = FALSE
    )
  }

  output[["Sample limsid"]] <- NULL
  names(output)[names(output) == "Sample Name"] <- "sample"
  output
}

#' Prepare a Crick RNA-seq samplesheet for nf-core/rnaseq
#'
#' Matches `Sample limsid` values in `sheet` to paired `_R1_` / `_R2_` FASTQs
#' under dated `*/fastq/` folders and returns an nf-core-style samplesheet
#' (`sample`, `fastq_1`, `fastq_2`, `strandedness`).
#'
#' @param dir Path to the parent sequencing directory (dated subfolders).
#' @param sheet Sample sheet / data frame with columns `Sample Name` and
#'   `Sample limsid`.
#' @return A data frame with columns `sample`, `fastq_1`, `fastq_2`, and
#'   `strandedness` (always `"auto"`).
#'
#' @examples
#' \dontrun{
#' sheet <- read.csv("crick_sample_sheet.csv")
#' prepare_crick_rnaseq("/path/to/sequencing", sheet)
#' }
#'
#' @export
prepare_crick_rnaseq <- function(dir, sheet) {
  output <- .prepare_crick_paired(
    dir = dir,
    sheet = sheet,
    keep_cols = c("Sample Name", "Sample limsid")
  )
  output$strandedness <- "auto"
  output
}

#' Prepare a Crick ATAC-seq samplesheet for nf-core/atacseq
#'
#' Same matching logic as [prepare_crick_rnaseq()], but retains a `replicate`
#' column required by the ATAC-seq template.
#'
#' @param dir Path to the parent sequencing directory (dated subfolders).
#' @param sheet Sample sheet / data frame with columns `Sample Name`,
#'   `Sample limsid`, and `replicate`.
#' @return A data frame with columns `sample`, `fastq_1`, `fastq_2`, and
#'   `replicate`.
#'
#' @examples
#' \dontrun{
#' sheet <- read.csv("crick_atac_sheet.csv")
#' prepare_crick_atacseq("/path/to/sequencing", sheet)
#' }
#'
#' @export
prepare_crick_atacseq <- function(dir, sheet) {
  output <- .prepare_crick_paired(
    dir = dir,
    sheet = sheet,
    keep_cols = c("Sample Name", "Sample limsid", "replicate")
  )
  output[, c("sample", "fastq_1", "fastq_2", "replicate"), drop = FALSE]
}

#' Infer 10x feature type from a Crick sample name
#'
#' @param sample_name Character vector of sample names.
#' @return Character vector of Cell Ranger feature types (`NA` if unmatched).
#' @noRd
.crick_10x_feature_type <- function(sample_name) {
  dplyr::case_when(
    stringr::str_detect(sample_name, "GEX") ~ "Gene Expression",
    stringr::str_detect(sample_name, "BCR") ~ "VDJ-B",
    stringr::str_detect(sample_name, "TCR") ~ "VDJ-T",
    stringr::str_detect(sample_name, "TSC") ~ "Antibody Capture",
    TRUE ~ NA_character_
  )
}

#' Prepare a Crick 10x multi library table
#'
#' Builds a library CSV-ready table by joining FASTQ folders to sample-sheet
#' LIMS IDs and inferring Cell Ranger `feature_type` from sample-name tags
#' (`GEX`, `BCR`, `TCR`, `TSC`).
#'
#' @param dir Path to the parent sequencing directory (dated subfolders).
#' @param sheet Sample sheet with columns `Sample limsid` and `Sample Name`.
#' @param str Path prefix string stripped from FASTQ paths (typically the
#'   shared parent path above sample-specific folders).
#' @return A data frame with columns `fastq_id`, `fastqs`, `lanes`,
#'   `feature_type`, and `samples`.
#'
#' @examples
#' \dontrun{
#' sheet <- read.csv("crick_10x_sheet.csv")
#' prepare_crick_10x("/path/to/sequencing", sheet, str = "/path/to/sequencing/")
#' }
#'
#' @export
prepare_crick_10x <- function(dir, sheet, str) {
  required <- c("Sample Name", "Sample limsid")
  missing <- setdiff(required, colnames(sheet))
  if (length(missing) > 0L) {
    stop(
      "Sample sheet missing column(s): ", paste(missing, collapse = ", "),
      call. = FALSE
    )
  }

  sheet <- sheet %>%
    dplyr::mutate(feature_type = .crick_10x_feature_type(.data[["Sample Name"]])) %>%
    dplyr::select("Sample limsid", "feature_type", "Sample Name")

  fastq_dirs <- .crick_fastq_dirs(dir)
  if (length(fastq_dirs) == 0L) {
    stop("No dated */fastq/ directories found under: ", dir, call. = FALSE)
  }

  fastqs <- unlist(
    lapply(fastq_dirs, list.files, full.names = TRUE),
    use.names = FALSE
  )

  output <- data.frame(fastqs = fastqs, lanes = "any", stringsAsFactors = FALSE) %>%
    dplyr::mutate(
      fastq_id = sub("_S.*", "", .data$fastqs),
      fastq_id = sub(".*/", "", .data$fastq_id),
      fastqs = sub(paste0(str, ".*"), "", .data$fastqs)
    ) %>%
    dplyr::distinct(.data$fastqs, .data$fastq_id, .keep_all = TRUE) %>%
    merge(
      sheet,
      by.x = "fastq_id",
      by.y = "Sample limsid",
      all.x = TRUE
    )

  names(output)[names(output) == "Sample Name"] <- "samples"
  output
}

#' Write Cell Ranger library CSVs and a batch ID list
#'
#' Splits a [prepare_crick_10x()] table by `samples`, writing one
#' `*_library.csv` per sample under `config_dir`, plus a `batch_id.txt` of
#' unique sample names under `sample_dir`.
#'
#' @param sheet Library table with a `samples` column (typically from
#'   [prepare_crick_10x()]).
#' @param config_dir Directory for per-sample `*_library.csv` files.
#'   Created if missing. Default `logs/input/` under the working directory.
#' @param sample_dir Directory for `batch_id.txt`. Created if missing.
#' @return Invisibly returns the unique sample names written.
#'
#' @examples
#' \dontrun{
#' lib <- prepare_crick_10x(dir, sheet, str)
#' prepare_crick_cellranger(lib, config_dir = "logs/input", sample_dir = "batch")
#' }
#'
#' @export
prepare_crick_cellranger <- function(sheet,
                                     config_dir = file.path(getwd(), "logs", "input"),
                                     sample_dir = file.path(getwd(), "batch")) {
  if (!is.data.frame(sheet) || !"samples" %in% colnames(sheet)) {
    stop("`sheet` must be a data frame with a 'samples' column", call. = FALSE)
  }

  dir.create(config_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(sample_dir, recursive = TRUE, showWarnings = FALSE)

  samples <- unique(sheet$samples)
  samples <- samples[!is.na(samples) & nzchar(as.character(samples))]
  if (length(samples) == 0L) {
    stop("No non-missing sample names in `sheet$samples`", call. = FALSE)
  }

  utils::write.table(
    samples,
    file.path(sample_dir, "batch_id.txt"),
    col.names = FALSE,
    row.names = FALSE,
    quote = FALSE,
    sep = "\t"
  )

  for (sample in samples) {
    csv <- sheet %>%
      dplyr::filter(.data$samples == sample) %>%
      dplyr::select(-"samples")
    utils::write.table(
      csv,
      file.path(config_dir, paste0(sample, "_library.csv")),
      col.names = FALSE,
      row.names = FALSE,
      quote = FALSE,
      sep = ","
    )
  }

  invisible(samples)
}

#' Build a paired-FASTQ sample table from an SRA download directory
#'
#' Filters FASTQ files whose name prefix matches `run_id`, pairs read 1 / read 2
#' by pattern, and returns a samplesheet-like data frame for ATAC or RNA
#' pipelines.
#'
#' @param dir Directory containing FASTQ files.
#' @param sample Sample name(s) to assign.
#' @param run_id Run / accession ID prefix(es) used to filter files
#'   (matched against the substring before the first `_`).
#' @param replicate Replicate ID(s) to assign.
#' @param fastq1_pattern Regex for read-1 files. Default `"1.fastq.gz$"`.
#' @param fastq2_pattern Regex for read-2 files. Default `"2.fastq.gz$"`.
#' @param format Either `"atac"` or `"rna"` (currently used for validation only).
#' @return A data frame with columns `sample`, `fastq_1`, `fastq_2`, and
#'   `replicate`.
#'
#' @examples
#' \dontrun{
#' extract_fastq(
#'   dir = "sra_fastqs",
#'   sample = "sampleA",
#'   run_id = "SRR123",
#'   replicate = 1,
#'   format = "rna"
#' )
#' }
#'
#' @export
extract_fastq <- function(dir,
                          sample,
                          run_id,
                          replicate,
                          fastq1_pattern = "1.fastq.gz$",
                          fastq2_pattern = "2.fastq.gz$",
                          format) {
  if (!format %in% c("atac", "rna")) {
    stop("`format` must be 'atac' or 'rna'", call. = FALSE)
  }
  if (!dir.exists(dir)) {
    stop("Directory not found: ", dir, call. = FALSE)
  }

  fastq_names <- list.files(dir)
  keep <- sub("_.*", "", fastq_names) %in% run_id
  fastq_names <- fastq_names[keep]

  fastq_1 <- fastq_names[grepl(fastq1_pattern, fastq_names)]
  fastq_2 <- fastq_names[grepl(fastq2_pattern, fastq_names)]

  data.frame(
    sample = sample,
    fastq_1 = file.path(dir, fastq_1),
    fastq_2 = file.path(dir, fastq_2),
    replicate = replicate,
    stringsAsFactors = FALSE
  )
}
