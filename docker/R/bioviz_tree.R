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
  make_option("--width", type = "double", default = 8,
              help = "Plot width in inches [default %default]."),
  make_option("--height", type = "double", default = 6,
              help = "Plot height in inches [default %default]."),
  make_option("--dpi", type = "integer", default = 300,
              help = "PNG resolution [default %default]."),
  make_option("--tip-label-size", type = "double", default = 3,
              help = "Tip label text size [default %default]."),
  make_option("--point-size", type = "double", default = 2,
              help = "Tip point size [default %default]."),
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
opt <- normalize_options(parse_args(parser))

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
formats <- split_formats(opt$formats)
outdir <- prepare_outdir(opt$outdir, opt$force)

tree <- ape::read.tree(opt$tree)
if (inherits(tree, "multiPhylo")) {
  stop("--tree must contain exactly one tree; multiPhylo files are not supported by bioviz-tree r1",
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

if (!is.null(opt$color_by) && !opt$color_by %in% names(annot)) {
  stop("--color-by column not found in metadata/annotation: ", opt$color_by,
       call. = FALSE)
}

p <- ggtree::ggtree(tree, layout = opt$layout) %<+% annot
if (!is.null(opt$color_by)) {
  p <- p + ggtree::geom_tippoint(
    mapping = ggplot2::aes(color = .data[[opt$color_by]]),
    size = opt$point_size
  )
} else {
  p <- p + ggtree::geom_tippoint(size = opt$point_size)
}
if (!isTRUE(opt$hide_tip_labels)) {
  p <- p + ggtree::geom_tiplab(
    mapping = ggplot2::aes(label = display_label),
    size = opt$tip_label_size,
    align = identical(opt$layout, "rectangular")
  )
}
if (!is.null(opt$title) && nzchar(opt$title)) {
  p <- p + ggplot2::ggtitle(opt$title)
}
p <- p + ggplot2::theme(plot.title = ggplot2::element_text(hjust = 0.5))

outputs <- character()
for (fmt in formats) {
  out <- file.path(outdir, paste0("tree.", fmt))
  if (identical(fmt, "png")) {
    ggplot2::ggsave(out, p, device = ragg::agg_png,
                    width = opt$width, height = opt$height, dpi = opt$dpi)
  } else if (identical(fmt, "svg")) {
    ggplot2::ggsave(out, p, device = svglite::svglite,
                    width = opt$width, height = opt$height)
  } else {
    ggplot2::ggsave(out, p, width = opt$width, height = opt$height)
  }
  outputs <- c(outputs, out)
}

summary_df <- data.frame(
  metric = c(
    "tree_file", "tip_count", "internal_node_count", "metadata_file",
    "metadata_id_column", "metadata_rows", "metadata_matched_tips",
    "metadata_unmatched_tips", "label_map_file", "label_map_from",
    "label_map_to", "label_map_rows", "layout", "formats", "output_files"
  ),
  value = c(
    opt$tree, length(tip_labels), tree$Nnode, ifelse(is.null(opt$metadata), "NA", opt$metadata),
    metadata_id_column, metadata_rows, metadata_matched,
    paste(metadata_unmatched_tips, collapse = ","), ifelse(is.null(opt$label_map), "NA", opt$label_map),
    label_map_from, label_map_to, label_map_rows, opt$layout,
    paste(formats, collapse = ","), paste(basename(outputs), collapse = ",")
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
    formats = formats,
    metadata_id_column = metadata_id_column,
    label_map_from = label_map_from,
    label_map_to = label_map_to,
    label_column = opt$label_column,
    color_by = opt$color_by,
    width = opt$width,
    height = opt$height,
    dpi = opt$dpi,
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
