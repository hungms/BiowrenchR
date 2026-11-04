# biowrenchR 0.1.1

## New features

* `impute_sex()` infers sample sex from an expression matrix by k-means
  clustering on Y-chromosome and X-escape marker genes (human and mouse).
  An independent reimplementation of the MetaIntegrator `imputeSex()` method.
  Male markers default to all Y-chromosome genes from the bundled BioMart
  dictionary; `scale` defaults to `FALSE`.
* `sex_marker_genes()` returns the default male/female marker genes per organism.
* New vignette "impute-sex" with validation on public GEO cohorts.
* Bundled Ensembl release-105 BioMart dictionaries
  (`biodict_release-105.tsv`, `biodict_{human,mouse}_release-105.tsv`) in
  `inst/extdata`.

## Behaviour changes

* `convert_genes()` now returns results in the order of the input `genes`
  (previously sorted alphabetically by source gene).

## Internal

* Refactored BioMart loaders (`.load_org_biomart()`, `.lds_dict()`), validators
  and Crick template helpers to remove duplicated code.
* `save_jupyter_plot()` now delegates to `save_plot()`.
* Dropped `magrittr` (native `|>` throughout) and unused `STRINGdb`; added
  `stats` to Imports; real `URL` / `BugReports`; removed `LazyData`.
* Removed duplicate `icon.png` and the `color_palettes` doc stub.
* Added `renv` lockfile for reproducible development.

# biowrenchR 0.1.0

* Initial release.
