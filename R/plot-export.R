# Plotting: PDF export

#' Save a plot to PDF
#'
#' Writes `plot` as a PDF. Uses Cairo when available.
#'
#' @param plot A plot object printable with `print()` (e.g. ggplot).
#' @param save_dir Output directory (created if missing).
#' @param file Optional file name or path. If a bare name without directory,
#'   it is placed under `save_dir`. If `NULL`, uses the unevaluated `plot`
#'   argument name (only reliable when calling `save_plot()` directly).
#' @param width Plot width in inches. Defaults to `getOption("repr.plot.width", 7)`.
#' @param height Plot height in inches. Defaults to `getOption("repr.plot.height", 7)`.
#' @return The output file path, invisibly.
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' save_plot(p, tempdir(), file = "mtcars_scatter.pdf")
#' }
#'
#' @export
save_plot <- function(plot,
                      save_dir = ".",
                      file = NULL,
                      width = getOption("repr.plot.width", 7),
                      height = getOption("repr.plot.height", 7)) {
  if (!dir.exists(save_dir)) {
    dir.create(save_dir, recursive = TRUE, showWarnings = FALSE)
  }
  if (!dir.exists(save_dir)) {
    stop("Could not create directory: ", save_dir, call. = FALSE)
  }

  if (is.null(file)) {
    nm <- substitute(plot)
    if (!is.name(nm)) {
      stop("Could not infer a file name; pass `file` explicitly", call. = FALSE)
    }
    file <- paste0(as.character(nm), ".pdf")
  }
  if (!grepl("\\.pdf$", file, ignore.case = TRUE)) {
    file <- paste0(file, ".pdf")
  }

  file_path <- if (dirname(file) %in% c(".", "")) {
    file.path(save_dir, basename(file))
  } else {
    file
  }

  if (requireNamespace("Cairo", quietly = TRUE)) {
    Cairo::CairoPDF(file = file_path, width = width, height = height)
  } else {
    grDevices::pdf(file = file_path, width = width, height = height)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  print(plot)

  invisible(file_path)
}

#' Save a plot from a Jupyter / notebook session
#'
#' Convenience wrapper around [save_plot()]. By default names the PDF after the
#' unevaluated `plot` argument; override with `name` if needed. A `.pdf`
#' extension is added automatically when missing.
#'
#' @inheritParams save_plot
#' @param name Optional output file name (with or without `.pdf`). Default
#'   `NULL` uses the unevaluated `plot` variable name.
#' @return The output file path, invisibly.
#'
#' @examples
#' \dontrun{
#' save_jupyter_plot(my_plot, "figures")
#' save_jupyter_plot(my_plot, "figures", name = "fig1_scatter")
#' }
#'
#' @export
save_jupyter_plot <- function(plot,
                              save_dir,
                              name = NULL,
                              width = getOption("repr.plot.width", 7),
                              height = getOption("repr.plot.height", 7)) {
  if (is.null(name)) {
    nm <- substitute(plot)
    if (!is.name(nm)) {
      stop("Pass a plot object by name, or set `name` explicitly", call. = FALSE)
    }
    name <- as.character(nm)
  }
  if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
    stop("`name` must be a non-empty string", call. = FALSE)
  }
  if (!grepl("\\.pdf$", name, ignore.case = TRUE)) {
    name <- paste0(name, ".pdf")
  }

  save_plot(
    plot = plot,
    save_dir = save_dir,
    file = name,
    width = width,
    height = height
  )
}
