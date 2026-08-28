# Plotting: color palettes

#' Built-in color palettes
#'
#' Static hex palettes (Scanpy, Wes Anderson–inspired, colorblind-friendly,
#' Vega, ColorBrewer-like). Retrieve with [get_palette()] or [palette_list()].
#'
#' @name color_palettes
#' @keywords internal
NULL

.palettes <- list(
  pal_godsnot102 = c(
    "#000000", "#FFFF00", "#1CE6FF", "#FF34FF", "#FF4A46", "#008941", "#006FA6",
    "#A30059", "#FFDBE5", "#7A4900", "#0000A6", "#63FFAC", "#B79762", "#004D43",
    "#8FB0FF", "#997D87", "#5A0007", "#809693", "#6A3A4C", "#1B4400", "#4FC601",
    "#3B5DFF", "#4A3B53", "#FF2F80", "#61615A", "#BA0900", "#6B7900", "#00C2A0",
    "#FFAA92", "#FF90C9", "#B903AA", "#D16100", "#DDEFFF", "#000035", "#7B4F4B",
    "#A1C299", "#300018", "#0AA6D8", "#013349", "#00846F", "#372101", "#FFB500",
    "#C2FFED", "#A079BF", "#CC0744", "#C0B9B2", "#C2FF99", "#001E09", "#00489C",
    "#6F0062", "#0CBD66", "#EEC3FF", "#456D75", "#B77B68", "#7A87A1", "#788D66",
    "#885578", "#FAD09F", "#FF8A9A", "#D157A0", "#BEC459", "#456648", "#0086ED",
    "#886F4C", "#34362D", "#B4A8BD", "#00A6AA", "#452C2C", "#636375", "#A3C8C9",
    "#FF913F", "#938A81", "#575329", "#00FECF", "#B05B6F", "#8CD0FF", "#3B9700",
    "#04F757", "#C8A1A1", "#1E6E00", "#7900D7", "#A77500", "#6367A9", "#A05837",
    "#6B002C", "#772600", "#D790FF", "#9B9700", "#549E79", "#FFF69F", "#201625",
    "#72418F", "#BC23FF", "#99ADC0", "#3A2465", "#922329", "#5B4534", "#FDE8DC",
    "#404E55", "#0089A3", "#CB7E98", "#A4E804", "#324E72"
  ),
  pal_zeileis28 = c(
    "#023fa5", "#7d87b9", "#bec1d4", "#d6bcc0", "#bb7784", "#8e063b", "#4a6fe3",
    "#8595e1", "#b5bbe3", "#e6afb9", "#e07b91", "#d33f6a", "#11c638", "#8dd593",
    "#c6dec7", "#ead3c6", "#f0b98d", "#ef9708", "#0fcfc0", "#9cded6", "#d5eae7",
    "#f3e1eb", "#f6c4e1", "#f79cd4", "#7f7f7f", "#c7c7c7", "#1CE6FF", "#336600"
  ),
  pal_royal4 = c("#899DA4", "#C93312", "#FAEFD1", "#DC863B"),
  pal_asteroid5 = c("#FBA72A", "#D3D4D8", "#CB7A5C", "#5785C1"),
  pal_darjeeling5 = c("#ECCBAE", "#046C9A", "#D69C4E", "#ABDDDE", "#000000"),
  pal_zissou5 = c("#3B9AB2", "#78B7C5", "#EBCC2A", "#E1AF00", "#F21A00"),
  pal_kelly20 = c(
    "#f3c300", "#875692", "#f38400", "#a1caf1", "#be0032", "#c2b280",
    "#848482", "#008856", "#e68fac", "#0067a5", "#f99379", "#604e97",
    "#f6a600", "#b3446c", "#dcd300", "#882d17", "#8db600", "#654522",
    "#e25822", "#2b3d26"
  ),
  pal_greenarmytage25 = c(
    "#F0A3FF", "#0075DC", "#993F00", "#4C005C", "#005C31", "#2BCE48",
    "#FFCC99", "#808080", "#94FFB5", "#8F7C00", "#9DCC00", "#C20088",
    "#003380", "#19A405", "#FFA8BB", "#426600", "#FF0010", "#5EF1F2",
    "#00998F", "#E0FF66", "#100AFF", "#990000", "#FFFF80", "#FFE100",
    "#FF5000"
  ),
  pal_brewerplus41 = c(
    "#A6CEE3", "#1F78B4", "#B2DF8A", "#33A02C", "#FB9A99", "#E31A1C",
    "#FDBF6F", "#FF7F00", "#CAB2D6", "#6A3D9A", "#FFFF99", "#B15928",
    "#1ff8ff", "#1B9E77", "#D95F02", "#7570B3", "#E7298A", "#66A61E",
    "#E6AB02", "#A6761D", "#666666", "#4b6a53", "#b249d5", "#7edc45",
    "#5c47b8", "#cfd251", "#ff69b4", "#69c86c", "#cd3e50", "#83d5af",
    "#da6130", "#5e79b2", "#c29545", "#532a5a", "#5f7b35", "#c497cf",
    "#773a27", "#7cb9cb", "#594e50", "#d3c4a8", "#c17e7f"
  ),
  pal_calc11 = c(
    "#004586", "#FF420E", "#FFD320", "#579D1C", "#7E0021", "#83CAFF",
    "#314004", "#AECF00", "#4B1F6F", "#C5000B", "#0084D1"
  ),
  pal_piyg11 = c(
    "#8E0152", "#C51B7D", "#DE77AE", "#F1B6DA", "#FDE0EF", "#F7F7F7",
    "#E6F5D0", "#B8E186", "#7FBC41", "#4D9221", "#276419"
  ),
  pal_brbg11 = c(
    "#543005", "#8C510A", "#BF812D", "#DFC27D", "#F6E8C3", "#F5F5F5",
    "#C7EAE5", "#80CDC1", "#35978F", "#01665E", "#003C30"
  ),
  pal_prgn11 = c(
    "#40004B", "#762A83", "#9970AB", "#C2A5CF", "#E7D4E8", "#F7F7F7",
    "#D9F0D3", "#A6DBA0", "#5AAE61", "#1B7837", "#00441B"
  ),
  pal_blackpink6 = c("#000000", "#EE8D46", "#B03270", "#C0C0C0", "#F5C383", "#D798B7"),
  pal_vega10 = c(
    "#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd",
    "#8c564b", "#e377c2", "#7f7f7f", "#bcbd22", "#17becf"
  ),
  pal_vega20 = c(
    "#1f77b4", "#aec7e8", "#ff7f0e", "#ffbb78", "#2ca02c", "#98df8a",
    "#d62728", "#ff9896", "#9467bd", "#c5b0d5", "#8c564b", "#c49c49",
    "#e377c2", "#f7b6d2", "#7f7f7f", "#c7c7c7", "#bcbd22", "#dbdb8d",
    "#17becf", "#9edae6"
  ),
  pal_vega20c = c(
    "#3182bd", "#6baed6", "#9ecae1", "#c6dbef", "#e6550d", "#fd8d3c",
    "#fdae6b", "#fdd0a2", "#31a354", "#74c476", "#a1d99b", "#c7e9c0",
    "#756bb1", "#9e9ae8", "#bcbddc", "#dadaeb", "#636363", "#969696",
    "#bdbdbd", "#d9d9d9"
  )
)

.viridis_names <- c(
  "viridis", "magma", "plasma", "inferno", "cividis", "mako", "rocket", "turbo"
)

.hex_re <- "^#([0-9A-Fa-f]{6}|[0-9A-Fa-f]{3}|[0-9A-Fa-f]{8})$"

#' Resolve a palette specification to a character vector of hex colors
#'
#' @param palette Palette name, hex vector, or function (see [get_palette()]).
#' @param n Number of colors requested (used for viridis / ColorBrewer / functions).
#' @return Character vector of hex colors (not yet truncated / expanded to `n`).
#' @noRd
.resolve_palette <- function(palette, n) {
  if (is.function(palette)) {
    formals_n <- names(formals(palette))
    cols <- if ("n" %in% formals_n) palette(n = n) else palette()
    return(cols)
  }

  if (!is.character(palette) || length(palette) < 1L) {
    return(NULL)
  }

  # Already a vector of colors
  if (length(palette) > 1L) {
    return(palette)
  }

  name <- palette[[1L]]

  # Built-in static palettes (incl. legacy "pal_kelly_20" -> "pal_kelly20")
  if (name %in% names(.palettes)) {
    return(.palettes[[name]])
  }
  if (grepl("^pal_.+_\\d+$", name)) {
    legacy <- sub("_(\\d+)$", "\\1", name)
    if (legacy %in% names(.palettes)) {
      return(.palettes[[legacy]])
    }
  }

  # viridis family
  if (name %in% .viridis_names) {
    if (!requireNamespace("viridis", quietly = TRUE)) {
      stop("Package 'viridis' is required for palette '", name, "'", call. = FALSE)
    }
    return(get(name, envir = asNamespace("viridis"))(n))
  }

  # ColorBrewer
  if (requireNamespace("RColorBrewer", quietly = TRUE) &&
      name %in% rownames(RColorBrewer::brewer.pal.info)) {
    max_colors <- RColorBrewer::brewer.pal.info[name, "maxcolors"]
    cols <- RColorBrewer::brewer.pal(min(n, max_colors), name)
    if (n > max_colors) {
      cols <- grDevices::colorRampPalette(cols)(n)
    }
    return(cols)
  }

  # Single hex string, or unknown name (validated later)
  palette
}

#' List built-in palettes
#'
#' @return Named list of character vectors of hex colors.
#' @export
palette_list <- function() {
  .palettes
}

#' Get a color palette
#'
#' @param palette A built-in palette name (see [palette_list()]), a character
#'   vector of hex colors, a ColorBrewer name, a viridis option name, or a
#'   zero-arg function returning colors.
#' @param n Number of colors to return. Default `9`.
#' @param direction `1` for forward, `-1` to reverse.
#' @return Character vector of hex colors.
#'
#' @examples
#' get_palette("pal_kelly20", n = 5)
#' get_palette("viridis", n = 10)
#' get_palette("Blues", n = 7)
#'
#' @export
get_palette <- function(palette, n = 9, direction = 1) {
  if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
    stop("`n` must be a positive number", call. = FALSE)
  }
  n <- as.integer(n)

  cols <- .resolve_palette(palette, n)
  if (!is.character(cols) || length(cols) < 1L) {
    stop(
      "`palette` must be a built-in name, hex vector, ColorBrewer/viridis name, or function",
      call. = FALSE
    )
  }

  valid_hex <- grepl(.hex_re, cols)
  if (!all(valid_hex)) {
    bad <- unique(cols[!valid_hex])
    # Prefer a clearer message when a single unknown palette name was passed
    if (is.character(palette) && length(palette) == 1L && identical(cols, palette)) {
      stop(
        "Unknown palette '", palette, "'. See names(palette_list()), ",
        "ColorBrewer, or viridis names.",
        call. = FALSE
      )
    }
    stop(
      "Invalid hex color code(s): ", paste(bad, collapse = ", "),
      call. = FALSE
    )
  }

  n_cols <- length(cols)
  if (n < n_cols) {
    cols <- cols[seq_len(n)]
  } else if (n > n_cols) {
    cols <- grDevices::colorRampPalette(cols)(n)
  }

  if (direction < 0) {
    rev(cols)
  } else {
    cols
  }
}

#' Display built-in palettes
#'
#' @param n Optional max colors to show per palette. Default shows all.
#' @return A ggplot2 object.
#'
#' @examples
#' \dontrun{
#' display_palettes()
#' display_palettes(n = 5)
#' }
#'
#' @export
display_palettes <- function(n = NULL) {
  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required for display_palettes()", call. = FALSE)
  }

  pals <- palette_list()
  lens <- lengths(pals)
  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
      stop("`n` must be a positive number or NULL", call. = FALSE)
    }
    n <- as.integer(n)
    lens <- pmin(lens, n)
  }

  palette_data <- data.frame(
    palette = factor(
      rep(names(pals), lens),
      levels = names(pals)
    ),
    color = unlist(
      Map(function(cols, len) cols[seq_len(len)], pals, lens),
      use.names = FALSE
    ),
    position = unlist(lapply(lens, seq_len), use.names = FALSE),
    stringsAsFactors = FALSE
  )

  ggplot2::ggplot(
    palette_data,
    ggplot2::aes(x = .data$position, y = .data$palette, fill = .data$color)
  ) +
    ggplot2::geom_tile(color = "white", linewidth = 0.5) +
    ggplot2::scale_fill_identity() +
    ggplot2::theme_minimal() +
    ggplot2::labs(
      title = "Available color palettes",
      x = "Color position",
      y = "Palette"
    ) +
    ggplot2::theme(
      panel.grid = ggplot2::element_blank(),
      axis.text.x = ggplot2::element_text(size = 8),
      axis.text.y = ggplot2::element_text(size = 10)
    )
}
