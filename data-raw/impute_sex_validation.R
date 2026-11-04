# Build inst/extdata/impute_sex_validation.rds for vignettes/impute-sex.Rmd.
#
# Downloads sex-labelled public GEO expression data (human + mouse, microarray
# + RNA-seq), log-normalises it, keeps only sex-marker genes and saves the
# result. Raw downloads are cached in data-raw/geo/ (git- and build-ignored).
#
# Run from the package root:
#   Rscript data-raw/impute_sex_validation.R
#
# Requires: GEOquery, Biobase, AnnotationDbi, org.Hs.eg.db, data.table.

suppressPackageStartupMessages({
  library(GEOquery)
  library(Biobase)
})
pkgload::load_all(".", quiet = TRUE)

geo_dir <- file.path("data-raw", "geo")
dir.create(geo_dir, recursive = TRUE, showWarnings = FALSE)
out_file <- file.path("inst", "extdata", "impute_sex_validation.rds")
options(timeout = 1200)

# ---- download helpers ------------------------------------------------------

geo_ftp <- function(acc, sub, file) {
  stub <- sub("\\d{1,3}$", "nnn", acc)
  type <- if (startsWith(acc, "GPL")) "platforms" else "series"
  sprintf("https://ftp.ncbi.nlm.nih.gov/geo/%s/%s/%s/%s/%s", type, stub, acc, sub, file)
}

fetch <- function(url, file) {
  dest <- file.path(geo_dir, file)
  if (!file.exists(dest)) {
    message("Downloading ", file)
    utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  }
  dest
}

read_series <- function(gse) {
  f <- paste0(gse, "_series_matrix.txt.gz")
  getGEO(filename = fetch(geo_ftp(gse, "matrix", f), f), getGPL = FALSE)
}

read_gpl <- function(gpl) {
  f <- paste0(gpl, ".soft.gz")
  dest <- file.path(geo_dir, f)
  if (!file.exists(dest)) getGEO(gpl, destdir = geo_dir) # writes GPLxxx.soft.gz
  Table(getGEO(filename = dest))
}

ncbi_counts <- function(gse) {
  f <- paste0(gse, "_raw_counts_GRCh38.p13_NCBI.tsv.gz")
  url <- sprintf(
    "https://www.ncbi.nlm.nih.gov/geo/download/?type=rnaseq_counts&acc=%s&format=file&file=%s",
    gse, f
  )
  dest <- fetch(url, f)
  m <- data.table::fread(dest, data.table = FALSE)
  ids <- as.character(m[[1]])
  m <- as.matrix(m[-1])
  map <- AnnotationDbi::select(org.Hs.eg.db::org.Hs.eg.db, unique(ids), "SYMBOL", "ENTREZID")
  map <- map[!duplicated(map$ENTREZID), ]
  list(counts = m, symbol = map$SYMBOL[match(ids, map$ENTREZID)])
}

# ---- processing helpers ----------------------------------------------------

# Parse "sex: F", "gender: Female", "GENDER_female,AGE_..", "'sex:male', ..."
parse_sex <- function(pd) {
  ch <- grep("^characteristics", names(pd), value = TRUE)
  txt <- do.call(paste, c(lapply(pd[ch], as.character), sep = " | "))
  hit <- regmatches(txt, regexpr("(?i)(sex|gender)\\s*[:_]\\s*[A-Za-z]+", txt, perl = TRUE))
  val <- rep(NA_character_, nrow(pd))
  has <- grepl("(?i)(sex|gender)\\s*[:_]\\s*[A-Za-z]+", txt, perl = TRUE)
  val[has] <- tolower(sub("(?i).*[:_]\\s*", "", hit, perl = TRUE))
  out <- ifelse(val %in% c("f", "female"), "female",
                ifelse(val %in% c("m", "male"), "male", NA_character_))
  stats::setNames(out, rownames(pd))
}

# One row per symbol: the probe/gene with the highest mean expression.
collapse_by_symbol <- function(m, sym) {
  ok <- !is.na(sym) & nzchar(sym) & !grepl("///", sym, fixed = TRUE)
  m <- m[ok, , drop = FALSE]
  sym <- sym[ok]
  o <- order(sym, -rowMeans(m, na.rm = TRUE))
  m <- m[o, , drop = FALSE]
  sym <- sym[o]
  keep <- !duplicated(sym)
  m <- m[keep, , drop = FALSE]
  rownames(m) <- sym[keep]
  m
}

log_array <- function(m) if (max(m, na.rm = TRUE) > 100) log2(pmax(m, 1)) else m
log_cpm <- function(counts) log2(t(t(counts) / colSums(counts)) * 1e6 + 1)

# Keep only genes impute_sex() or the vignette's checks look at.
marker_subset <- function(m, org) {
  mk <- sex_marker_genes(org)
  extra <- if (org == "human") {
    c("XIST", "RPS4X", "KDM5C", "KDM6A", "ZFX", "DDX3X")
  } else {
    c("Xist", "Kdm5c", "Kdm6a", "Eif2s3x", "Ddx3x")
  }
  m[intersect(rownames(m), unique(c(mk$female, mk$male, extra))), , drop = FALSE]
}

make_dataset <- function(id, org, platform, tissue, exprs, sex, group = NULL) {
  keep <- colnames(exprs)[!is.na(sex[colnames(exprs)])]
  list(
    id = id, org = org, platform = platform, tissue = tissue,
    exprs = marker_subset(exprs[, keep, drop = FALSE], org),
    sex = sex[keep],
    group = if (!is.null(group)) group[keep]
  )
}

# ---- human -----------------------------------------------------------------

human_array <- function(gse, symbol_from, platform, tissue) {
  es <- read_series(gse)
  gpl <- read_gpl(annotation(es))
  fd <- gpl[match(featureNames(es), gpl$ID), ]
  sym <- if (symbol_from == "refseq") {
    acc <- sub("\\..*", "", as.character(fd$GB_ACC))
    map <- AnnotationDbi::select(org.Hs.eg.db::org.Hs.eg.db,
                                 unique(acc[nzchar(acc)]), "SYMBOL", "REFSEQ")
    map <- map[!duplicated(map$REFSEQ), ]
    map$SYMBOL[match(acc, map$REFSEQ)]
  } else {
    as.character(fd[[symbol_from]])
  }
  m <- collapse_by_symbol(log_array(exprs(es)), sym)
  make_dataset(gse, "human", platform, tissue, m, parse_sex(pData(es)))
}

human_rnaseq <- function(gse, platform, tissue, group_field = NULL) {
  es <- read_series(gse)
  cn <- ncbi_counts(gse)
  m <- collapse_by_symbol(log_cpm(cn$counts), cn$symbol)
  pd <- pData(es)
  grp <- if (!is.null(group_field)) stats::setNames(as.character(pd[[group_field]]), rownames(pd))
  make_dataset(gse, "human", platform, tissue, m, parse_sex(pd), grp)
}

# ---- mouse -----------------------------------------------------------------

mouse_array <- function(gse, symbol_col, platform, tissue, group_fun = NULL) {
  es <- read_series(gse)
  gpl <- read_gpl(annotation(es))
  fd <- gpl[match(featureNames(es), gpl$ID), ]
  m <- collapse_by_symbol(log_array(exprs(es)), as.character(fd[[symbol_col]]))
  pd <- pData(es)
  grp <- if (!is.null(group_fun)) stats::setNames(group_fun(pd), rownames(pd))
  make_dataset(gse, "mouse", platform, tissue, m, parse_sex(pd), grp)
}

# Supplementary count tables: map their column labels to GSM accessions via
# the series-matrix field that holds the same label.
mouse_suppl_rnaseq <- function(gse, file, sym_col, drop_cols, label_field,
                               platform, tissue, label_fun = identity) {
  es <- read_series(gse)
  dest <- fetch(geo_ftp(gse, "suppl", file), file)
  tab <- data.table::fread(dest, data.table = FALSE)
  sym <- as.character(tab[[sym_col]])
  cnt <- as.matrix(tab[setdiff(names(tab), c(sym_col, drop_cols))])
  pd <- pData(es)
  lab <- label_fun(as.character(pd[[label_field]]))
  colnames(cnt) <- rownames(pd)[match(colnames(cnt), lab)]
  cnt <- cnt[, !is.na(colnames(cnt)), drop = FALSE]
  m <- collapse_by_symbol(log_cpm(cnt), sym)
  make_dataset(gse, "mouse", platform, tissue, m, parse_sex(pd))
}

# ---- build -----------------------------------------------------------------

datasets <- list(
  human_array("GSE19151", "Gene Symbol", "Affymetrix HG-U133A 2.0", "Whole blood"),
  human_array("GSE15222", "refseq", "Illumina HumanRef-8", "Brain cortex"),
  human_rnaseq("GSE107011", "RNA-seq", "PBMC + sorted immune cell subsets",
               group_field = "cell type:ch1"),
  human_rnaseq("GSE60424", "RNA-seq", "Blood cell subsets"),
  mouse_array("GSE4324", "Gene Symbol", "Affymetrix MOE430A", "Spleen white blood cells",
              group_fun = function(pd) {
                ch <- do.call(paste, pd[grep("^characteristics", names(pd))])
                ifelse(grepl("treatment:intact", ch), "intact", "gonadectomised")
              }),
  mouse_array("GSE240873", "GENE_SYMBOL", "Agilent 4x44K", "Hippocampus"),
  mouse_suppl_rnaseq("GSE266332", "GSE266332_Counts.csv.gz",
                     sym_col = "Gene ID", drop_cols = character(),
                     label_field = "description", platform = "RNA-seq", tissue = "Eye"),
  mouse_suppl_rnaseq("GSE199722", "GSE199722_all.gene_counts.tsv.gz",
                     sym_col = "external_gene_name",
                     drop_cols = c("ensembl_gene_id", "entrezgene", "gene_biotype",
                                   "external_gene_source", "transcript_count", "description"),
                     label_field = "title", platform = "RNA-seq", tissue = "Hippocampus")
)
names(datasets) <- vapply(datasets, `[[`, "", "id")

for (d in datasets) {
  message(sprintf("%-10s %-6s n=%3d (F=%d, M=%d) genes=%d", d$id, d$org, ncol(d$exprs),
                  sum(d$sex == "female"), sum(d$sex == "male"), nrow(d$exprs)))
}
saveRDS(datasets, out_file, compress = "xz")
message("Saved ", out_file, " (", round(file.size(out_file) / 1024), " KB)")
