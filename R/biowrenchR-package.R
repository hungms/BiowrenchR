#' biowrenchR: Data Structure Pipelines for Genomic Analysis
#'
#' @section Format I/O:
#' `read_gmt()`, `write_gmt()`, `read_gct()`, `write_gct()`,
#' `list_to_df()`, `df_to_list()`
#'
#' @section BioMart and conversion:
#' `load_biomart()`, `load_biomart_human()`, `load_biomart_mouse()`,
#' `get_conversion_dict()`, `convert_genes()`, `convert_df()`, `convert_exprs()`
#'
#' @section Gene sets:
#' `xy_genes()`, `mt_genes()`, `cell_cycle_genes()`, `genes_by_pattern()`,
#' and pattern constants (`bcr_pattern`, `tcr_pattern`, ...)
#'
#' @section Expression utilities:
#' `annotate_genes()`, `summarize_genes()`, `impute_sex()`, `sex_marker_genes()`
#'
#' @section Crick templates:
#' `prepare_crick_rnaseq()`, `prepare_crick_atacseq()`, `prepare_crick_10x()`,
#' `prepare_crick_cellranger()`, `extract_fastq()`, `cat_content()`
#'
#' @section Plotting:
#' `get_palette()`, `palette_list()`, `display_palettes()`,
#' `save_plot()`, `save_jupyter_plot()`, `add_strip_pal()`
#'
#' @keywords internal
#' @importFrom rlang .data
"_PACKAGE"
