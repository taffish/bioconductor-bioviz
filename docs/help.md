taf-bioconductor-bioviz 3.23-r2

TAFFISH-maintained R/Bioconductor 3.23 bioinformatics visualization
runtime. It provides Rscript plus stable helper CLIs for downstream plotting
flows. The current stable helper surface focuses on Newick tree visualization.

Usage:
  taf-bioconductor-bioviz [-h | --help]
  taf-bioconductor-bioviz [-v | --version]
  taf-bioconductor-bioviz -- [RSCRIPT_ARGS...]
  taf-bioconductor-bioviz COMMAND [ARGS...]
  taf-bioconductor-bioviz --compile [ARGS...]

Wrapper options:
  -h, --help       Show this TAFFISH app help
  -v, --version    Show TAFFISH package version
  --compile        Print generated shell code instead of running it
  --               Stop wrapper option parsing and pass following args to
                   the default Rscript command

Default upstream command:
  taf-bioconductor-bioviz -- --version
  taf-bioconductor-bioviz -- -e 'cat(R.version.string, "\n")'
  taf-bioconductor-bioviz -- plot.R

Command mode:
  taf-bioconductor-bioviz Rscript plot.R
  taf-bioconductor-bioviz bioviz-runtime-info
  taf-bioconductor-bioviz bioviz-tree --help

Common tree plot:
  taf-bioconductor-bioviz bioviz-tree \
    --tree tree.nwk \
    --metadata sample_metadata.tsv \
    --label-map sequence_id_map.tsv \
    --color-by group \
    --layout rectangular \
    --formats pdf,png,svg \
    --outdir plots

Tree style:
  bioviz-tree defaults to --style journal, --label-align none, automatic
  width/height, and extra right-side padding so long labels are not clipped.
  Use --label-align guide only when aligned dotted tip guides are wanted.
  Use --style classic or --style minimal for heavier or quieter alternatives.
  Use --label-transform pretty for review figures where underscores and pipe
  separators should be rendered more readably.
  Use --scale-bar none for branchless cladograms or compact thumbnails.
  The default --scale-bar auto draws a scale bar for rectangular trees with
  branch lengths.
  Titles with spaces are tolerated when TAFFISH-generated shell code splits
  the title words, and the final title is recorded in the summary/manifest.

bioviz-tree inputs:
  --tree is a single Newick file. --metadata is an optional TSV/CSV table
  keyed by original tree tip labels. --label-map is an optional two-column
  table from original tree tip labels to display labels.

bioviz-tree outputs:
  Depending on --formats, tree.pdf, tree.png, and/or tree.svg.
  Every run also writes tree_plot_summary.tsv, tree_tip_annotations.tsv,
  versions.tsv, run.manifest.json, and sessionInfo.txt.

bioviz-tree layouts and formats:
  Layouts: rectangular, circular, fan.
  Formats: pdf, png, svg.
  Output size can be overridden with --width, --height, --dpi,
  --tip-label-size, --label-offset, --right-padding, and scale-bar options.

Packaged commands:
  R, Rscript, bioviz-runtime-info, bioviz-tree.

Major R packages:
  Bioconductor 3.23 with ape, treeio, ggtree, tidytree, ggplot2, svglite,
  ragg, optparse, jsonlite, readr, data.table, ggrepel, patchwork, cowplot,
  scales, viridis, and RColorBrewer.

Command-mode note:
  Use explicit Rscript for script paths:
    taf-bioconductor-bioviz Rscript plot.R
  A bare positional script path may be interpreted as a container command name.

Platform:
  Built from the official Bioconductor RELEASE_3_23 container. Native image
  builds are linux/amd64 and linux/arm64 when the upstream base image supports
  both platforms.

Boundaries:
  This app is a visualization runtime and helper CLI app. It provides Rscript
  and bioviz-tree. It does not infer trees, align sequences, install packages
  at runtime, download project metadata, or provide every common biological
  plot helper yet. Add future helpers such as volcano, heatmap, PCA, or dotplot
  only when a flow needs a stable reusable CLI.
