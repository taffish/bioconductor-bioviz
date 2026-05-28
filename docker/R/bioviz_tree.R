suppressPackageStartupMessages({
  library(optparse)
  library(ape)
  library(treeio)
  library(ggtree)
  library(tidytree)
  library(ggplot2)
  library(svglite)
  library(ragg)
  source("/opt/bioconductor-bioviz/R/bioviz_common.R")
})

option_list <- list(
  make_option("--tree", type = "character",
              help = "Input Newick tree file."),
  make_option("--metadata", type = "character", default = NULL,
              help = "Optional tip metadata TSV/CSV table."),
  make_option("--label-map", type = "character", default = NULL,
              help = "Optional two-column tip id to display label table."),
  make_option("--outdir", type = "character",
              help = "Output directory."),
  make_option("--layout", type = "character", default = "rectangular",
              help = "Tree layout: rectangular, circular, or fan [default %default]."),
  make_option("--formats", type = "character", default = "pdf,png,svg",
              help = "Comma-separated output formats: pdf,png,svg [default %default]."),
  make_option("--style", type = "character", default = "journal",
              help = "Plot style: journal, classic, or minimal [default %default]."),
  make_option("--label-align", type = "character", default = "none",
              help = "Tip-label alignment guides: none or guide [default %default]."),
  make_option("--label-transform", type = "character", default = "none",
              help = "Display-label transform: none or pretty [default %default]."),
  make_option("--metadata-id-column", type = "character", default = NULL,
              help = "Metadata column matching original tree tip labels."),
  make_option("--label-map-from", type = "character", default = NULL,
              help = "Label-map source id column."),
  make_option("--label-map-to", type = "character", default = NULL,
              help = "Label-map display label column."),
  make_option("--label-column", type = "character", default = NULL,
              help = "Metadata column to use as display labels."),
  make_option("--color-by", type = "character", default = NULL,
              help = "Metadata column used to color tip points."),
  make_option("--title", type = "character", default = NULL,
              help = "Optional plot title."),
  make_option("--width", type = "double", default = NA,
              help = "Plot width in inches [default auto]."),
  make_option("--height", type = "double", default = NA,
              help = "Plot height in inches [default auto]."),
  make_option("--dpi", type = "integer", default = 300,
              help = "PNG resolution [default %default]."),
  make_option("--tip-label-size", type = "double", default = NA,
              help = "Tip label text size [default auto]."),
  make_option("--point-size", type = "double", default = NA,
              help = "Tip point size [default style-dependent]."),
  make_option("--label-offset", type = "double", default = NA,
              help = "Tip label offset in tree branch-length units [default auto]."),
  make_option("--right-padding", type = "double", default = NA,
              help = "Extra right-side x-axis padding in tree units [default auto]."),
  make_option("--scale-bar", type = "character", default = "auto",
              help = "Scale bar: auto or none [default %default]."),
  make_option("--scale-bar-width", type = "double", default = NA,
              help = "Scale bar width in branch-length units [default auto]."),
  make_option("--scale-bar-label", type = "character", default = NULL,
              help = "Scale bar label [default derived from width]."),
  make_option("--branch-line-width", type = "double", default = NA,
              help = "Branch line width [default style-dependent]."),
  make_option("--branch-color", type = "character", default = NULL,
              help = "Branch color [default style-dependent]."),
  make_option("--tip-label-color", type = "character", default = NULL,
              help = "Tip label color [default style-dependent]."),
  make_option("--hide-tip-labels", action = "store_true", default = FALSE,
              help = "Do not draw tip labels."),
  make_option("--force", action = "store_true", default = FALSE,
              help = "Allow writing into a non-empty output directory."),
  make_option("--version", action = "store_true", default = FALSE,
              help = "Print helper version and exit.")
)

parser <- OptionParser(
  option_list = option_list,
  usage = "bioviz-tree --tree tree.nwk --outdir plots [options]",
  description = "Tree plotting helper for Newick phylogenies."
)
parsed <- parse_args(parser, positional_arguments = TRUE)
opt <- normalize_options(parsed$options)
extra_args <- parsed$args
if (length(extra_args)) {
  # TAFFISH-generated shell scripts may lose quote grouping for titles with spaces.
  if (!is.null(opt$title)) {
    opt$title <- paste(c(opt$title, extra_args), collapse = " ")
  } else {
    stop("unexpected positional argument(s): ", paste(extra_args, collapse = " "),
         call. = FALSE)
  }
}

if (isTRUE(opt$version)) {
  cat(sprintf("bioviz-tree %s (Bioconductor %s)\n",
              bioviz_cli_version(), as.character(BiocManager::version())))
  quit(status = 0)
}

if (is.null(opt$tree) || is.null(opt$outdir)) {
  print_help(parser)
  quit(status = 2)
}

valid_layouts <- c("rectangular", "circular", "fan")
if (!opt$layout %in% valid_layouts) {
  stop("--layout must be one of: ", paste(valid_layouts, collapse = ", "),
       call. = FALSE)
}
valid_styles <- c("journal", "classic", "minimal")
if (!opt$style %in% valid_styles) {
  stop("--style must be one of: ", paste(valid_styles, collapse = ", "),
       call. = FALSE)
}
valid_label_align <- c("none", "guide")
if (!opt$label_align %in% valid_label_align) {
  stop("--label-align must be one of: ", paste(valid_label_align, collapse = ", "),
       call. = FALSE)
}
valid_label_transforms <- c("none", "pretty")
if (!opt$label_transform %in% valid_label_transforms) {
  stop("--label-transform must be one of: ",
       paste(valid_label_transforms, collapse = ", "), call. = FALSE)
}
valid_scale_bar <- c("auto", "none")
if (!opt$scale_bar %in% valid_scale_bar) {
  stop("--scale-bar must be one of: ", paste(valid_scale_bar, collapse = ", "),
       call. = FALSE)
}
formats <- split_formats(opt$formats)
outdir <- prepare_outdir(opt$outdir, opt$force)

plot_style <- function(style) {
  if (identical(style, "classic")) {
    return(list(
      branch_color = "#111111",
      tip_label_color = "#111111",
      guide_color = "#9CA3AF",
      branch_line_width = 0.55,
      title_size = 12,
      label_fontface = "plain"
    ))
  }
  if (identical(style, "minimal")) {
    return(list(
      branch_color = "#374151",
      tip_label_color = "#111827",
      guide_color = "#D1D5DB",
      branch_line_width = 0.35,
      title_size = 11,
      label_fontface = "plain"
    ))
  }
  list(
    branch_color = "#26323F",
    tip_label_color = "#111827",
    guide_color = "#CBD5E1",
    branch_line_width = 0.45,
    title_size = 12,
    label_fontface = "plain"
  )
}

pretty_labels <- function(x) {
  x <- gsub("_", " ", x, fixed = TRUE)
  x <- gsub("|", " / ", x, fixed = TRUE)
  gsub("[[:space:]]+", " ", x)
}

auto_tip_label_size <- function(layout, tip_count) {
  if (!identical(layout, "rectangular")) {
    if (tip_count > 90) {
      0.9
    } else if (tip_count > 60) {
      1.1
    } else if (tip_count > 35) {
      1.3
    } else {
      1.6
    }
  } else if (tip_count > 90) {
    1.5
  } else if (tip_count > 60) {
    1.8
  } else if (tip_count > 35) {
    2.2
  } else {
    2.8
  }
}

auto_dimensions <- function(layout, tip_count, max_label_chars, width, height) {
  if (is.na(width)) {
    width <- if (identical(layout, "rectangular")) {
      max(8, min(18, 5.8 + max_label_chars * 0.12))
    } else {
      max(8.5, min(18, 7 + max_label_chars * 0.12))
    }
  }
  if (is.na(height)) {
    height <- if (identical(layout, "rectangular")) {
      max(4.8, min(18, 1.5 + tip_count * 0.24))
    } else {
      max(8.5, min(18, width))
    }
  }
  list(width = width, height = height)
}

nice_scale_width <- function(x_range) {
  raw <- x_range / 5
  if (!is.finite(raw) || raw <= 0) {
    return(NA_real_)
  }
  pow <- 10 ^ floor(log10(raw))
  candidates <- c(1, 2, 5, 10) * pow
  candidates[which.min(abs(candidates - raw))]
}

tree <- ape::read.tree(opt$tree)
if (inherits(tree, "multiPhylo")) {
  stop("--tree must contain exactly one tree; multiPhylo files are not supported by bioviz-tree",
       call. = FALSE)
}
tip_labels <- as.character(tree$tip.label)
if (!length(tip_labels)) {
  stop("tree has no tip labels", call. = FALSE)
}

display_labels <- tip_labels
label_map_rows <- 0L
label_map_from <- NA_character_
label_map_to <- NA_character_
if (!is.null(opt$label_map)) {
  label_map <- read_table_auto(opt$label_map)
  label_map_from <- choose_column(
    label_map, opt$label_map_from,
    c("sequence_id", "id", "tip", "tip_label", "old_id", "from"),
    "label-map source", fallback_position = 1
  )
  label_map_to <- choose_column(
    label_map, opt$label_map_to,
    c("label", "display_label", "name", "sample", "new_id", "to"),
    "label-map target", fallback_position = 2
  )
  label_map[[label_map_from]] <- as.character(label_map[[label_map_from]])
  label_map[[label_map_to]] <- as.character(label_map[[label_map_to]])
  ensure_unique(label_map[[label_map_from]], "label-map source column")
  mapped <- setNames(label_map[[label_map_to]], label_map[[label_map_from]])
  hit <- !is.na(mapped[tip_labels])
  display_labels[hit] <- unname(mapped[tip_labels[hit]])
  label_map_rows <- nrow(label_map)
}

annot <- data.frame(
  label = tip_labels,
  display_label = display_labels,
  stringsAsFactors = FALSE,
  check.names = FALSE
)

metadata_rows <- 0L
metadata_matched <- 0L
metadata_id_column <- NA_character_
metadata_unmatched_tips <- tip_labels
if (!is.null(opt$metadata)) {
  metadata <- read_table_auto(opt$metadata)
  metadata_id_column <- choose_column(
    metadata, opt$metadata_id_column,
    c("sample", "sample_id", "id", "sequence_id", "tip", "tip_label", "label"),
    "metadata id", fallback_position = 1
  )
  metadata[[metadata_id_column]] <- as.character(metadata[[metadata_id_column]])
  ensure_unique(metadata[[metadata_id_column]], "metadata id column")
  metadata_rows <- nrow(metadata)
  row_idx <- match(tip_labels, metadata[[metadata_id_column]])
  metadata_matched <- sum(!is.na(row_idx))
  metadata_unmatched_tips <- tip_labels[is.na(row_idx)]
  for (col in setdiff(names(metadata), metadata_id_column)) {
    out_col <- col
    if (out_col %in% names(annot)) {
      out_col <- paste0("metadata_", out_col)
    }
    annot[[out_col]] <- metadata[[col]][row_idx]
  }
}

if (!is.null(opt$label_column)) {
  if (!opt$label_column %in% names(annot)) {
    stop("--label-column not found in metadata/annotation: ", opt$label_column,
         call. = FALSE)
  }
  replacement <- as.character(annot[[opt$label_column]])
  keep <- !is.na(replacement) & nzchar(replacement)
  annot$display_label[keep] <- replacement[keep]
}
if (identical(opt$label_transform, "pretty")) {
  annot$display_label <- pretty_labels(annot$display_label)
}

if (!is.null(opt$color_by) && !opt$color_by %in% names(annot)) {
  stop("--color-by column not found in metadata/annotation: ", opt$color_by,
       call. = FALSE)
}

style <- plot_style(opt$style)
branch_color <- if (is.null(opt$branch_color)) style$branch_color else opt$branch_color
tip_label_color <- if (is.null(opt$tip_label_color)) style$tip_label_color else opt$tip_label_color
branch_line_width <- if (is.na(opt$branch_line_width)) {
  style$branch_line_width
} else {
  opt$branch_line_width
}
tip_label_size <- if (is.na(opt$tip_label_size)) {
  auto_tip_label_size(opt$layout, length(tip_labels))
} else {
  opt$tip_label_size
}
point_size <- if (is.na(opt$point_size)) {
  if (identical(opt$style, "classic")) {
    1.25
  } else if (!is.null(opt$color_by)) {
    1.7
  } else {
    0
  }
} else {
  opt$point_size
}
max_label_chars <- max(nchar(annot$display_label, type = "width"), 1)
dimensions <- auto_dimensions(
  opt$layout, length(tip_labels), max_label_chars, opt$width, opt$height
)

p <- ggtree::ggtree(tree, layout = opt$layout, color = branch_color,
                   linewidth = branch_line_width) %<+% annot
if (!is.null(opt$color_by)) {
  p <- p + ggtree::geom_tippoint(
    mapping = ggplot2::aes(color = .data[[opt$color_by]]),
    size = point_size
  )
  if (is.numeric(annot[[opt$color_by]])) {
    p <- p + ggplot2::scale_color_viridis_c(option = "D", na.value = "#B8C0CC")
  } else {
    p <- p + ggplot2::scale_color_brewer(palette = "Dark2", na.value = "#B8C0CC")
  }
} else if (point_size > 0) {
  p <- p + ggtree::geom_tippoint(size = point_size, color = branch_color)
}
if (!isTRUE(opt$hide_tip_labels)) {
  built_x <- p$data$x[is.finite(p$data$x)]
  x_range <- diff(range(built_x))
  if (!is.finite(x_range) || x_range <= 0) {
    x_range <- 1
  }
  label_offset <- if (is.na(opt$label_offset)) {
    x_range * ifelse(identical(opt$layout, "rectangular"), 0.012, 0.018)
  } else {
    opt$label_offset
  }
  right_padding <- if (is.na(opt$right_padding)) {
    if (identical(opt$layout, "rectangular")) {
      max(x_range * 0.08, x_range * max_label_chars * 0.007)
    } else {
      x_range * 0.08
    }
  } else {
    opt$right_padding
  }
  align_labels <- identical(opt$label_align, "guide")
  p <- p + ggtree::geom_tiplab(
    mapping = ggplot2::aes(label = display_label),
    size = tip_label_size,
    offset = label_offset,
    align = align_labels,
    color = tip_label_color,
    fontface = style$label_fontface,
    linetype = if (align_labels) "dotted" else "solid"
  )
  p <- p + ggplot2::expand_limits(x = max(built_x) + right_padding)
} else {
  label_offset <- NA_real_
  right_padding <- NA_real_
}
scale_bar_drawn <- FALSE
scale_bar_width <- NA_real_
scale_bar_label <- NA_character_
if (identical(opt$scale_bar, "auto") &&
    identical(opt$layout, "rectangular") &&
    !is.null(tree$edge.length)) {
  built_x <- p$data$x[is.finite(p$data$x)]
  built_y <- p$data$y[is.finite(p$data$y)]
  x_range <- diff(range(built_x))
  if (!is.finite(x_range) || x_range <= 0) {
    x_range <- 1
  }
  scale_bar_width <- if (is.na(opt$scale_bar_width)) {
    nice_scale_width(x_range)
  } else {
    opt$scale_bar_width
  }
  if (is.finite(scale_bar_width) && scale_bar_width > 0 && length(built_y)) {
    scale_bar_label <- if (is.null(opt$scale_bar_label)) {
      format(signif(scale_bar_width, 2), trim = TRUE)
    } else {
      opt$scale_bar_label
    }
    scale_x <- min(built_x) + x_range * 0.02
    scale_y <- max(built_y) + 0.85
    tick <- 0.16
    scale_df <- data.frame(
      x = scale_x,
      xend = scale_x + scale_bar_width,
      y = scale_y,
      yend = scale_y,
      label = scale_bar_label,
      stringsAsFactors = FALSE
    )
    tick_df <- data.frame(
      x = c(scale_x, scale_x + scale_bar_width),
      xend = c(scale_x, scale_x + scale_bar_width),
      y = c(scale_y - tick, scale_y - tick),
      yend = c(scale_y + tick, scale_y + tick)
    )
    p <- p +
      ggplot2::geom_segment(
        data = scale_df,
        ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
        inherit.aes = FALSE,
        linewidth = 0.35,
        color = "#4B5563"
      ) +
      ggplot2::geom_segment(
        data = tick_df,
        ggplot2::aes(x = x, xend = xend, y = y, yend = yend),
        inherit.aes = FALSE,
        linewidth = 0.35,
        color = "#4B5563"
      ) +
      ggplot2::geom_text(
        data = scale_df,
        ggplot2::aes(x = (x + xend) / 2, y = y, label = label),
        inherit.aes = FALSE,
        vjust = -0.55,
        size = max(2.3, tip_label_size * 0.8),
        color = "#4B5563"
      )
    scale_bar_drawn <- TRUE
  }
}
if (!is.null(opt$title) && nzchar(opt$title)) {
  p <- p + ggplot2::ggtitle(opt$title)
}
right_margin <- if (isTRUE(opt$hide_tip_labels)) {
  12
} else {
  max(24, min(150, max_label_chars * tip_label_size * 0.75))
}
plot_margin <- if (identical(opt$layout, "rectangular")) {
  ggplot2::margin(if (scale_bar_drawn) 18 else 8, right_margin, 8, 8)
} else {
  radial_margin <- max(18, min(180, max_label_chars * tip_label_size * 0.85))
  ggplot2::margin(radial_margin, radial_margin, radial_margin, radial_margin)
}
plot_theme <- ggplot2::theme(
  plot.background = ggplot2::element_rect(fill = "white", color = NA),
  panel.background = ggplot2::element_rect(fill = "white", color = NA),
  plot.title = ggplot2::element_text(
    hjust = 0.5, face = "bold", size = style$title_size,
    margin = ggplot2::margin(b = 7), color = "#111827"
  ),
  plot.margin = plot_margin,
  legend.title = ggplot2::element_text(size = 8, color = "#374151"),
  legend.text = ggplot2::element_text(size = 7, color = "#374151"),
  legend.key = ggplot2::element_rect(fill = "white", color = NA),
  legend.background = ggplot2::element_rect(fill = "white", color = NA)
)
if (identical(opt$layout, "rectangular")) {
  p <- p + ggplot2::coord_cartesian(clip = "off") + plot_theme
} else {
  p <- p + plot_theme
}

outputs <- character()
for (fmt in formats) {
  out <- file.path(outdir, paste0("tree.", fmt))
  if (identical(fmt, "png")) {
    ggplot2::ggsave(out, p, device = ragg::agg_png,
                    width = dimensions$width, height = dimensions$height,
                    dpi = opt$dpi, bg = "white", limitsize = FALSE)
  } else if (identical(fmt, "svg")) {
    ggplot2::ggsave(out, p, device = svglite::svglite,
                    width = dimensions$width, height = dimensions$height,
                    bg = "white", limitsize = FALSE)
  } else {
    ggplot2::ggsave(out, p, width = dimensions$width,
                    height = dimensions$height, bg = "white",
                    limitsize = FALSE)
  }
  outputs <- c(outputs, out)
}

summary_df <- data.frame(
  metric = c(
    "tree_file", "tip_count", "internal_node_count", "metadata_file",
    "metadata_id_column", "metadata_rows", "metadata_matched_tips",
    "metadata_unmatched_tips", "label_map_file", "label_map_from",
    "label_map_to", "label_map_rows", "layout", "style", "label_align",
    "label_transform", "scale_bar", "scale_bar_width", "scale_bar_label",
    "title", "formats", "plot_width", "plot_height", "output_files"
  ),
  value = c(
    opt$tree, length(tip_labels), tree$Nnode, ifelse(is.null(opt$metadata), "NA", opt$metadata),
    metadata_id_column, metadata_rows, metadata_matched,
    paste(metadata_unmatched_tips, collapse = ","), ifelse(is.null(opt$label_map), "NA", opt$label_map),
    label_map_from, label_map_to, label_map_rows, opt$layout, opt$style,
    opt$label_align, opt$label_transform, opt$scale_bar,
    ifelse(scale_bar_drawn, scale_bar_width, "NA"),
    ifelse(scale_bar_drawn, scale_bar_label, "NA"),
    ifelse(is.null(opt$title), "NA", opt$title),
    paste(formats, collapse = ","),
    dimensions$width, dimensions$height, paste(basename(outputs), collapse = ",")
  ),
  stringsAsFactors = FALSE
)
write_tsv(summary_df, file.path(outdir, "tree_plot_summary.tsv"))
write_tsv(annot, file.path(outdir, "tree_tip_annotations.tsv"))
write_versions(outdir)
write_manifest(
  outdir,
  tool = "bioviz-tree",
  inputs = list(tree = opt$tree, metadata = opt$metadata, label_map = opt$label_map),
  outputs = list(
    tree_plots = basename(outputs),
    summary = "tree_plot_summary.tsv",
    annotations = "tree_tip_annotations.tsv",
    versions = "versions.tsv",
    manifest = "run.manifest.json",
    session_info = "sessionInfo.txt"
  ),
  parameters = list(
    layout = opt$layout,
    style = opt$style,
    label_align = opt$label_align,
    label_transform = opt$label_transform,
    scale_bar = opt$scale_bar,
    scale_bar_width = if (scale_bar_drawn) scale_bar_width else NULL,
    scale_bar_label = if (scale_bar_drawn) scale_bar_label else NULL,
    formats = formats,
    metadata_id_column = metadata_id_column,
    label_map_from = label_map_from,
    label_map_to = label_map_to,
    label_column = opt$label_column,
    color_by = opt$color_by,
    title = opt$title,
    width = dimensions$width,
    height = dimensions$height,
    dpi = opt$dpi,
    branch_line_width = branch_line_width,
    point_size = point_size,
    tip_label_size = tip_label_size,
    label_offset = label_offset,
    right_padding = right_padding,
    hide_tip_labels = opt$hide_tip_labels
  ),
  summary = list(
    tip_count = length(tip_labels),
    internal_node_count = tree$Nnode,
    metadata_matched_tips = metadata_matched,
    metadata_unmatched_tips = metadata_unmatched_tips
  )
)
write_session_info(outdir)
