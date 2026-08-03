#' biowrenchR: Data Structure Pipelines for Genomic Analysis
#'
#' Helpers for genomic file formatting, human-mouse gene mapping, gene-set
#' filtering, isoform summarization, annotation joins, and plotting utilities.
#'
#' @section Source layout:
#' \describe{
#'   \item{`R/formats.R`}{List/data-frame helpers; GMT and GCT I/O}
#'   \item{`R/biomart.R`}{Load human/mouse/joint BioMart dictionaries}
#'   \item{`R/convert.R`}{Ortholog conversion for vectors, data frames, expression}
#'   \item{`R/genesets.R`}{Gene-set helpers and family regex patterns}
#'   \item{`R/annotate.R`}{Annotation joins}
#'   \item{`R/summarize.R`}{Isoform-to-gene expression aggregation}
#'   \item{`R/plot-palette.R`}{Color palettes and `get_palette()`}
#'   \item{`R/plot-export.R`}{PDF plot export helpers}
#'   \item{`R/plot-strips.R`}{Facet strip recoloring}
#'   \item{`R/internal.R`}{Cache, extdata readers, validators}
#' }
#'
#' @section Format I/O:
#' `read_gmt()`, `write_gmt()`, `read_gct()`, `write_gct()`,
#' `list_to_df()`, `df_to_list()`
#'
#' @section Conversion:
#' `get_conversion_dict()`, `convert_genes()`, `convert_df()`, `convert_exprs()`
#'
#' @section BioMart loaders:
#' `load_biomart()`, `load_biomart_human()`, `load_biomart_mouse()`
#'
#' @section Gene-set helpers:
#' `xy_genes()`, `mt_genes()`, `cell_cycle_genes()`, `genes_by_pattern()`,
#' and pattern constants (`bcr_pattern`, `tcr_pattern`, ...)
#'
#' @section Annotation and summarization:
#' `annotate_genes()`, `summarize_genes()`
#'
#' @section Plotting helpers:
#' `get_palette()`, `palette_list()`, `display_palettes()`,
#' `save_plot()`, `save_jupyter_plot()`, `add_strip_pal()`
#'
#' @keywords internal
"_PACKAGE"

#' @importFrom rlang .data
#' @importFrom magrittr %>%
NULL
