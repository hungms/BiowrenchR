"""Convert vignettes/impute-sex.Rmd into a runnable Jupyter (IRkernel) notebook.

Usage (from the package root):
    python3 data-raw/rmd_to_ipynb.py vignettes/impute-sex.Rmd vignettes/impute-sex.ipynb
"""
import json
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()

# drop YAML header
text = re.sub(r"\A---\n.*?\n---\n", "", text, flags=re.S)

SETUP = '''# Run this notebook from vignettes/ (or the package root) with the "R" (ir) kernel.
pkg_root <- normalizePath(if (file.exists("DESCRIPTION")) "." else "..")

# Use the project's renv library (copied from the seurat5 env).
# Set to FALSE to use whatever library the kernel already has.
use_renv <- TRUE
if (use_renv) {
  Sys.setenv(RENV_PATHS_LIBRARY = file.path(pkg_root, "renv", "library"))
  renv::load(pkg_root)
}

# Load biowrenchR from source (no install needed)
pkgload::load_all(pkg_root, quiet = TRUE)

# Notebook equivalent of knitr::kable(): return a data frame for rich display
show_table <- function(x, row.names = FALSE, digits = NULL) {
  if (!is.null(digits)) {
    num <- vapply(x, is.numeric, logical(1))
    x[num] <- lapply(x[num], round, digits)
  }
  if (!row.names) rownames(x) <- NULL
  x
}

options(repr.plot.width = 12, repr.plot.height = 8, repr.plot.res = 110,
        repr.matrix.max.rows = 50)'''

cells = []


def md(s):
    s = s.strip("\n")
    if s.strip():
        cells.append({"cell_type": "markdown", "metadata": {}, "source": s.splitlines(True)})


def code(s):
    s = s.strip("\n")
    if s.strip():
        cells.append({"cell_type": "code", "metadata": {}, "execution_count": None,
                      "outputs": [], "source": s.splitlines(True)})


md("# Validating impute_sex() on public human and mouse data\n\n"
   "Notebook version of `vignettes/impute-sex.Rmd`.")
code(SETUP)

parts = re.split(r"```\{r([^}]*)\}\n(.*?)```\n", text, flags=re.S)
# parts: [md, opts, code, md, opts, code, ..., md]
for i in range(0, len(parts), 3):
    prose = parts[i]

    # Inline R: the GSE107011 cell-type count
    prose = prose.replace(
        "`r length(unique(datasets$GSE107011$group))` sorted immune cell subsets",
        "many sorted immune cell subsets")

    # Inline R: the overall-accuracy sentence becomes a code cell
    m = re.search(r"Across all `r nrow\(calls\)`.*?`r sum\(calls\$pred == calls\$y_call\)`\.",
                  prose, flags=re.S)
    if m:
        md(prose[:m.start()])
        code('cat(sprintf(\n'
             '  "Across all %d samples, impute_sex() agrees with the GEO label for %d\\n'
             'and with the independent Y-score call for %d.\\n",\n'
             '  nrow(calls), sum(calls$pred == calls$label), sum(calls$pred == calls$y_call)))')
        md(prose[m.end():])
    else:
        md(prose)

    if i + 2 >= len(parts):
        break
    opts, body = parts[i + 1], parts[i + 2]
    if "include = FALSE" in opts:  # knitr setup chunk
        continue
    body = body.replace("library(biowrenchR)\n", "")
    body = body.replace("knitr::kable(", "show_table(")
    fh = re.search(r"fig\.height\s*=\s*(\d+)", opts)
    if fh:
        body = f"options(repr.plot.height = {fh.group(1)})\n" + body
    code(body)

nb = {
    "cells": cells,
    "metadata": {
        "kernelspec": {"name": "ir", "display_name": "R", "language": "R"},
        "language_info": {"name": "R"},
    },
    "nbformat": 4,
    "nbformat_minor": 5,
}
for k, c in enumerate(nb["cells"]):
    c["id"] = f"cell-{k:02d}"
json.dump(nb, open(dst, "w"), indent=1)
print(f"wrote {dst}: {len(cells)} cells")
