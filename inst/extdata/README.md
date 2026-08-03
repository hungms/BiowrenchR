# Packaged data (extdata)

Place these TSVs here before installing for offline BioMart / annotation use
(default `release = "105"`):

| File | Used by |
|------|---------|
| `biodict_release-<release>.tsv` | `load_biomart()` |
| `biodict_human_release-<release>.tsv` | `load_biomart_human()` |
| `biodict_mouse_release-<release>.tsv` | `load_biomart_mouse()` |
| `cellcycle_<org>_genes.tsv` | `cell_cycle_genes()` |
| `omnipathdb_<org>_release-<release>.tsv` | `annotate_genes()` |

Or call BioMart loaders with `local = FALSE` to query Ensembl over the network.
