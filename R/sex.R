# Independent reimplementation of MetaIntegrator::imputeSex() (LGPL; method by
# E. Bongen). No MetaIntegrator code is copied; see impute_sex() @details.

#' Default sex-marker genes
#'
#' Genes used by [impute_sex()] when `female_genes` / `male_genes` are not
#' supplied.
#'
#' * `male`: all Y-chromosome genes in the packaged BioMart dictionary
#'   (see [xy_genes()]). Y genes are male-specific, so the full set is usable.
#' * `female`: a curated list of X-inactivation escape genes. Most X genes are
#'   dosage-compensated and *not* female-biased, so the full X set is not used.
#'   Human genes are the X-escape subset of the immune Sex Expression Signature
#'   (iSEXS; Bongen et al.; Tukiainen et al. 2017); mouse genes are
#'   well-established escapees.
#'
#' @param org `"human"` or `"mouse"`.
#' @param ... Passed to [load_biomart_human()] / [load_biomart_mouse()].
#' @return A list with character vectors `female` and `male`.
#' @examples
#' str(sex_marker_genes("human"))
#' @export
sex_marker_genes <- function(org = c("human", "mouse"), ...) {
  org <- match.arg(org)
  female <- switch(
    org,
    human = c(
      "XIST", "RPS4X", "CD40LG", "ZRSR2", "EFHC2", "CA5B", "ZFX", "EIF1AX",
      "CA5BP1", "UBA1", "SYAP1", "DDX3X", "FUNDC1", "USP9X", "SMC1A",
      "NUP62CL", "NAA10"
    ),
    mouse = c("Xist", "Tsix", "Kdm6a", "Kdm5c", "Eif2s3x", "Ddx3x")
  )
  list(female = female, male = .genes_on_chromosomes(org, "Y", ...))
}

#' Impute biological sex of samples from gene expression
#'
#' Clusters samples into two groups with k-means on sex-chromosome marker
#' genes, then labels the cluster with higher female-gene and lower
#' male-gene expression as `"female"`.
#'
#' @param exprs Numeric matrix or data frame of expression values with gene
#'   symbols as row names and samples as columns. Log-scale values (e.g.
#'   log2 CPM / normalised array intensities) are recommended.
#' @param female_genes Genes expressed higher in females. Defaults to
#'   `sex_marker_genes(org)$female`.
#' @param male_genes Genes expressed higher in males. Defaults to
#'   `sex_marker_genes(org)$male`.
#' @param org `"human"` or `"mouse"`; selects default marker genes.
#' @param scale If `TRUE`, z-score each gene across samples before
#'   clustering. Default `FALSE`: with the full Y-gene set, scaling amplifies
#'   noise from lowly expressed / cross-mapped Y pseudogenes, while unscaled
#'   clustering is driven by strongly expressed markers (*XIST*, *RPS4Y1*, ...).
#' @param nstart Number of random starts for [stats::kmeans()]. Call
#'   [set.seed()] beforehand for reproducible results.
#'
#' @return Named character vector (`"female"` / `"male"`) with one entry per
#'   sample. Returns all `NA` with a warning if no marker genes are found or
#'   female and male genes disagree on cluster assignment.
#'
#' @details
#' Method after Bongen et al. (iSEXS) as implemented in
#' `MetaIntegrator::imputeSex()`. Differences: accepts a plain matrix rather
#' than a MetaIntegrator `datasetObject`; male markers are all Y-chromosome
#' genes from the packaged BioMart dictionary rather than a fixed list;
#' optional per-gene scaling; multiple k-means starts; returns `NA` rather
#' than `NULL` on failure. With only two
#' clusters the method assumes both sexes are present — check results on
#' single-sex cohorts.
#'
#' @references
#' Tukiainen T. et al. (2017) Landscape of X chromosome inactivation across
#' human tissues. *Nature* 550, 244–248.
#'
#' Haynes W.A. et al. MetaIntegrator: Meta-Analysis of Gene Expression Data.
#' CRAN. <https://CRAN.R-project.org/package=MetaIntegrator>
#'
#' @examples
#' set.seed(1)
#' genes <- c("XIST", "RPS4X", "RPS4Y1", "DDX3Y", "GAPDH")
#' sex <- rep(c("female", "male"), each = 5)
#' m <- matrix(rnorm(50, 5), nrow = 5, dimnames = list(genes, paste0("s", 1:10)))
#' m[c("XIST", "RPS4X"), sex == "female"] <- m[c("XIST", "RPS4X"), sex == "female"] + 4
#' m[c("RPS4Y1", "DDX3Y"), sex == "male"] <- m[c("RPS4Y1", "DDX3Y"), sex == "male"] + 4
#' impute_sex(m)
#'
#' @export
impute_sex <- function(exprs,
                       female_genes = NULL,
                       male_genes = NULL,
                       org = c("human", "mouse"),
                       scale = FALSE,
                       nstart = 25L) {
  org <- match.arg(org)
  exprs <- as.matrix(exprs)
  if (!is.numeric(exprs)) {
    stop("`exprs` must be numeric.", call. = FALSE)
  }
  if (is.null(rownames(exprs))) {
    stop("`exprs` must have gene symbols as row names.", call. = FALSE)
  }
  if (ncol(exprs) < 2L) {
    stop("`exprs` must contain at least two samples.", call. = FALSE)
  }

  if (is.null(female_genes) || is.null(male_genes)) {
    defaults <- sex_marker_genes(org)
    female_genes <- female_genes %||% defaults$female
    male_genes <- male_genes %||% defaults$male
  }
  female_genes <- intersect(female_genes, rownames(exprs))
  male_genes <- intersect(male_genes, rownames(exprs))

  samples <- colnames(exprs) %||% as.character(seq_len(ncol(exprs)))
  fail <- function(msg) {
    warning(msg, call. = FALSE)
    stats::setNames(rep(NA_character_, length(samples)), samples)
  }

  marker_genes <- c(female_genes, male_genes)
  if (length(marker_genes) == 0L) {
    return(fail("None of the sex marker genes are present in `exprs`."))
  }

  # samples x genes; drop constant / non-finite genes
  x <- t(exprs[marker_genes, , drop = FALSE])
  keep <- apply(x, 2, function(v) all(is.finite(v)) && stats::var(v) > 0)
  x <- x[, keep, drop = FALSE]
  female_genes <- intersect(female_genes, colnames(x))
  male_genes <- intersect(male_genes, colnames(x))
  if (ncol(x) == 0L) {
    return(fail("Sex marker genes have no variance across samples."))
  }
  if (scale) x <- base::scale(x)

  km <- stats::kmeans(x, centers = 2L, nstart = nstart)

  centre_mean <- function(genes) {
    if (length(genes) == 0L) return(NULL)
    rowMeans(km$centers[, genes, drop = FALSE])
  }
  fem <- centre_mean(female_genes)
  mal <- centre_mean(male_genes)

  female_cluster <- if (!is.null(fem) && !is.null(mal)) {
    if (which.max(fem) != which.min(mal)) {
      return(fail(
        "Female and male marker genes disagree on cluster assignment; try different genes."
      ))
    }
    which.max(fem)
  } else if (!is.null(fem)) {
    which.max(fem)
  } else {
    which.min(mal)
  }

  out <- ifelse(km$cluster == female_cluster, "female", "male")
  stats::setNames(out, samples)
}
