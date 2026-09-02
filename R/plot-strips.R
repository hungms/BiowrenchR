# Plotting: facet strip recoloring

#' Recolor facet strip backgrounds
#'
#' Sets strip rectangle fills for a faceted ggplot using colors from `pal`
#' (recycled if there are more strips than colors).
#'
#' @param plot A ggplot object with facet strips.
#' @param pal Character vector of colors (e.g. from [get_palette()]).
#' @return A ggplotified gtable (requires **ggplotify**).
#'
#' @examples
#' \dontrun{
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   facet_wrap(~cyl)
#' add_strip_pal(p, get_palette("kelly20", n = 3))
#' }
#'
#' @export
add_strip_pal <- function(plot, pal) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for add_strip_pal()", call. = FALSE)
  }
  if (!requireNamespace("ggplotify", quietly = TRUE)) {
    stop("Package 'ggplotify' is required for add_strip_pal()", call. = FALSE)
  }
  if (!is.character(pal) || length(pal) < 1L) {
    stop("`pal` must be a non-empty character vector of colors", call. = FALSE)
  }

  g <- ggplot2::ggplot_gtable(ggplot2::ggplot_build(plot))
  strip_idx <- which(grepl("^strip-(t|r|l|b)", g$layout$name))
  if (length(strip_idx) == 0L) {
    warning("No facet strips found on plot", call. = FALSE)
    return(plot)
  }

  pal <- rep_len(pal, length(strip_idx))

  for (k in seq_along(strip_idx)) {
    i <- strip_idx[[k]]
    grob <- g$grobs[[i]]
    if (is.null(grob) || is.null(grob$grobs) || length(grob$grobs) < 1L) {
      next
    }
    inner <- grob$grobs[[1L]]
    if (is.null(inner$childrenOrder)) {
      next
    }
    rect_idx <- which(grepl("rect", inner$childrenOrder))
    if (length(rect_idx) == 0L) {
      next
    }
    g$grobs[[i]]$grobs[[1L]]$children[[rect_idx[[1L]]]]$gp$fill <- pal[[k]]
  }

  ggplotify::as.ggplot(g)
}
