taf-bioconductor-bioviz 3.23-r1

TAFFISH-maintained R/Bioconductor 3.23 bioinformatics visualization
runtime. It provides Rscript plus stable helper CLIs for downstream plotting
flows. The r1 helper surface focuses on Newick tree visualization.

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

bioviz-tree inputs:
  --tree is a single Newick file. --metadata is an optional TSV/CSV table
  keyed by original tree tip labels. --label-map is an optional two-column
  table from original tree tip labels to display labels.

bioviz-tree outputs:
  tree.pdf, tree.png, tree.svg, tree_plot_summary.tsv,
  tree_tip_annotations.tsv, versions.tsv, run.manifest.json, sessionInfo.txt.

bioviz-tree layouts and formats:
  Layouts: rectangular, circular, fan.
  Formats: pdf, png, svg.

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
  This app is a visualization runtime and helper CLI app. r1 provides Rscript
  and bioviz-tree. It does not infer trees, align sequences, install packages
  at runtime, download project metadata, or provide every common biological
  plot helper yet. Add future helpers such as volcano, heatmap, PCA, or dotplot
  only when a flow needs a stable reusable CLI.
