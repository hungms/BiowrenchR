# biowrenchR — manifest

Project state, decisions and next steps. Newest log entries first.

## Layout

| File | Contents |
|---|---|
| `R/formats.R` | GMT / GCT read & write; list ↔ data frame |
| `R/biomart.R` | Ensembl BioMart loaders (results cached in `.biowrenchR_env`) |
| `R/convert.R` | human ↔ mouse conversion for vectors, data frames, expression matrices |
| `R/genesets.R` | gene-family regexes, `xy_genes`, `mt_genes`, `cell_cycle_genes`, `genes_by_pattern` |
| `R/annotate.R` | OmniPath annotation join |
| `R/summarize.R` | isoform → gene aggregation |
| `R/sex.R` | `impute_sex()`, `sex_marker_genes()` |
| `R/crick.R` | Crick sample-sheet / FASTQ templates |
| `R/plot-*.R` | palettes, PDF export, facet strip colours |
| `R/internal.R` | non-exported helpers (cache, extdata reader, validators, `%||%`) |

- MIT licence, R >= 4.1, native pipe `|>` throughout (no magrittr).
- Extdata: all files present — `biodict_*` (added 2026-11-03), `cellcycle_{human,mouse}_genes.tsv`
  and `omnipathdb_{human,mouse}_release-105.tsv` (added 2026-11-04). See `inst/extdata/README.md`.
  Installed size ~15 MB (OmniPath human table is 8.8 MB), so `R CMD check` may NOTE package size.
- Dev on CAMP: `module load R/4.5.1-gfbf-2025a`, then `roxygen2::roxygenise()`, `R CMD build` + `R CMD check`.

## Log

### 2026-11-04 — cell-cycle + OmniPath extdata
- Added `cellcycle_{human,mouse}_genes.tsv` (Seurat S/G2M + Macosko phase sets) and
  `omnipathdb_{human,mouse}_release-105.tsv`; `cell_cycle_genes()` / `annotate_genes()` verified.
- Trimmed a stray leading space (`" AGFG1"`, Macosko_M.G1) in the human cell-cycle table;
  `df_to_list()` now `trimws()`s entries.
- `.read_extdata_tsv()`: `quote = ""`, `comment.char = ""`, `strip.white = TRUE`; optional
  `cache = TRUE` (used for cell-cycle and OmniPath tables). OmniPath tables have no duplicate
  source symbols, so the left join cannot multiply rows.

### 2026-11-04 — v0.1.1
- Bumped version 0.1.0 → 0.1.1; added `NEWS.md` summarising the changes below.

### 2026-11-03 — `impute_sex()` uses extdata Y genes
- Male markers = all Y-chromosome genes from `biodict_<org>_release-105.tsv`
  (430 human, 1,554 mouse) via `.genes_on_chromosomes()`.
- Female markers stay curated X-escape genes: most of the 1,848 human X genes are
  dosage-compensated (X-inactivation), so they are not female-biased.
- `scale` default changed `TRUE` → `FALSE`. Simulation with cross-mapped Y pseudogenes:
  scaled + full Y list dropped to ~60% accuracy at n = 8; unscaled stayed at 100%
  (as did the old curated list). Unscaled also matches MetaIntegrator.
- Extdata only loaded when `male_genes`/`female_genes` are not supplied.

### 2026-11-03 — cleanup pass
- Removed: `icon.png` (byte-identical to `man/figures/logo.png`), `.DS_Store`,
  built tarball, local `.Rlib/` install, `color_palettes` doc stub.
- DESCRIPTION: dropped unused `magrittr`, `STRINGdb`, `knitr`, `rmarkdown`,
  `LazyData` (no `data/`), stray `YEAR`/`COPYRIGHT HOLDER` fields; added `stats`;
  real `URL`/`BugReports`.
- Trimmed `.Rbuildignore` / `.gitignore` to entries that apply.
- Deduplicated code: shared `.load_org_biomart()` / `.lds_dict()` in biomart.R;
  `.as_df()` for validators; org checks only in `get_conversion_dict()`;
  `.check_sheet_cols()` and empty-FASTQ-dir check in crick.R helpers;
  `save_jupyter_plot()` delegates to `save_plot()`.
- Behaviour change: `convert_genes()` now returns results in input order
  (previously alphabetical by source gene).
- `impute_sex()`: removed `seed` arg (use `set.seed()`).
- `R CMD check --no-manual`: Status OK (0 errors / warnings / notes).

### 2026-11-03 — added `impute_sex()`
- Ported from MetaIntegrator `imputeSex()` (https://rdrr.io/cran/MetaIntegrator/src/R/imputeSex.R).
- MetaIntegrator is **LGPL**; to keep biowrenchR MIT this is an independent
  reimplementation (method + published gene lists, no copied code), credited in docs.
- Differences: plain matrix input, mouse defaults, optional per-gene scaling,
  `nstart = 25`, drops zero-variance genes, returns `NA` (not `NULL`) on failure.

## TODO
- [ ] `tests/testthat/` (start with `impute_sex`, GMT/GCT round-trip, `convert_genes`)
- [ ] Validate `impute_sex()` on a real cohort with known sex (esp. full Y list on scRNA pseudobulk / arrays)
- [ ] Single-sex-cohort check for `impute_sex()` (k = 2 assumes both sexes)
- [ ] API tidy-ups (breaking, not yet done): `extract_fastq(format=)` is unused;
      `cat_content(dir=)` takes a file path; `prepare_crick_10x(str=)` name is vague
- [ ] `.get_org_biomart()` cache ignores `...` (e.g. a different `release` returns the cached one)
- [x] `git config core.fileMode false` to hide 644→755 mode noise (done 2026-11-04)

## Notes
<!-- Free-form context -->
