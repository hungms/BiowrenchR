# biowrenchR <img src="man/figures/logo.png" align="right" height="139" alt="logo" />

R helpers for genomic file formatting, gene-symbol conversion, gene-set
filtering, isoform summarization, annotation joins, Crick sample-sheet
formatting, and lightweight plotting utilities (palettes, PDF export, facet
strip colors).

## Install

```r
# install.packages("devtools")
devtools::install_github("hungms/biowrenchR")
```

Or from a local clone:

```r
devtools::install(".")
```

Offline BioMart / cell-cycle helpers expect TSV files under `inst/extdata/`
(see [Extdata](#extdata)).

## Features / source layout

| Area | Functions | Source |
|------|-----------|--------|
| Format I/O | `read_gmt`, `write_gmt`, `read_gct`, `write_gct`, `list_to_df`, `df_to_list` | `R/formats.R` |
| BioMart | `load_biomart`, `load_biomart_human`, `load_biomart_mouse` | `R/biomart.R` |
| Conversion | `get_conversion_dict`, `convert_genes`, `convert_df`, `convert_exprs` | `R/convert.R` |
| Gene sets | `xy_genes`, `mt_genes`, `cell_cycle_genes`, `genes_by_pattern`, `*_pattern` | `R/genesets.R` |
| Annotation | `annotate_genes` | `R/annotate.R` |
| Summarize | `summarize_genes` | `R/summarize.R` |
| Crick templates | `prepare_crick_rnaseq`, `prepare_crick_atacseq`, `prepare_crick_10x`, `prepare_crick_cellranger`, `extract_fastq`, `cat_content` | `R/crick.R` |
| Palettes | `get_palette`, `palette_list`, `display_palettes` | `R/plot-palette.R` |
| Plot export | `save_plot`, `save_jupyter_plot` | `R/plot-export.R` |
| Facet strips | `add_strip_pal` | `R/plot-strips.R` |
| Internals | validators, extdata helpers, caches | `R/internal.R` |

## Quick examples

### GMT / GCT and list ↔ data frame

```r
library(biowrenchR)

sets <- list(
  pathway1 = c("TP53", "MDM2", "CDKN1A"),
  pathway2 = c("CD4", "CD8A")
)
df <- list_to_df(sets)
write_gmt(df, tempfile(fileext = ".gmt"))

expr <- data.frame(sample1 = c(1, 2), sample2 = c(3, 4), row.names = c("TP53", "CD4"))
write_gct(expr, tempfile(fileext = ".gct"))
```

### Species conversion

```r
# Requires inst/extdata biodict files (or local = FALSE on loaders)
convert_genes(c("Trp53", "Cd4"), org.from = "mouse", org.to = "human")
convert_df(my_df, gene_column = "gene", org.from = "human", org.to = "mouse")
convert_exprs(expr_mat, org.from = "human", org.to = "mouse")
```

### Gene-set helpers

```r
xy_genes("human")
mt_genes("mouse")
cell_cycle_genes("human")
genes_by_pattern("human", c("rb", "mt"))
```

### Palettes and plots

```r
get_palette("pal_kelly20", n = 5)
save_plot(p, "figures", file = "myplot.pdf")
```

### Crick sample sheets

```r
# sheet <- read.csv("crick_sample_sheet.csv")
# prepare_crick_rnaseq("/path/to/sequencing", sheet)
# prepare_crick_atacseq("/path/to/sequencing", sheet)
# lib <- prepare_crick_10x("/path/to/sequencing", sheet, str = "/path/to/sequencing/")
# prepare_crick_cellranger(lib)
```

### Annotation and isoform summarization

```r
mat <- matrix(1:6, nrow = 3, dimnames = list(NULL, c("s1", "s2")))
summarize_genes(mat, gene_sym_vec = c("A", "A", "B"))
```

## Extdata

When `local = TRUE` (default), these files are expected in `inst/extdata/`:

- `biodict_release-<release>.tsv` — joint human–mouse dictionary
- `biodict_human_release-<release>.tsv` — human symbols + chromosomes
- `biodict_mouse_release-<release>.tsv` — mouse symbols + chromosomes
- `cellcycle_<org>_genes.tsv` — cell-cycle gene sets

Default `release` is `"105"`. Set `local = FALSE` on BioMart loaders to query
Ensembl instead (requires network and **biomaRt**).

## Dependencies

**Imports:** dplyr, tidyr, tibble, stringr, magrittr, rlang, data.table, biomaRt, grDevices, utils

**Suggests:** ggplot2, ggplotify, Cairo, viridis, RColorBrewer, STRINGdb

## License

MIT
