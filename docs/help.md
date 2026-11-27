taf-bioconductor-bioviz 3.24-r1

Plot a Newick tree or run an R visualization script.

Usage:
  taf-bioconductor-bioviz [-h | --help]
  taf-bioconductor-bioviz [-v | --version]
  taf-bioconductor-bioviz --compile [COMMAND] [ARGS...]
  taf-bioconductor-bioviz COMMAND [ARGS...]

Start here:
  taf-bioconductor-bioviz bioviz-runtime-info
  taf-bioconductor-bioviz bioviz-tree --help
  taf-bioconductor-bioviz bioviz-tree --tree tree.nwk --outdir plots
  taf-bioconductor-bioviz Rscript plot.R
  taf-bioconductor-bioviz Rscript --version

Wrapper options:
  -h, --help       Show this usage guide without starting a container.
  -v, --version    Show the TAFFISH app version, not the R version.
  --compile        Print generated shell code without running it.
  --               End wrapper options; use explicit Rscript for script files.

Tree input and annotation:
  --tree FILE      One Newick tree; the input is not modified.
  --metadata FILE Optional TSV/CSV keyed by original tip IDs.
  --label-map FILE Optional table mapping tip IDs to display labels.
  --color-by COL   A metadata column used for tip colors.
  --outdir DIR    Required output directory; nonempty directories are refused.
  --force         Overwrite helper outputs in DIR; unrelated files are retained.

Example:
  taf-bioconductor-bioviz bioviz-tree --tree tree.nwk \
    --metadata metadata.tsv --color-by group --label-map labels.tsv \
    --layout rectangular --formats pdf,png,svg --outdir plots

Appearance:
  Layouts: rectangular (default), circular, fan.
  Formats: pdf,png,svg (default); use --formats png for a single format.
  Styles: journal (default), classic, minimal.
  --label-align guide adds dotted guides; default: none.
  --label-transform pretty changes underscores/pipes; default: none.
  --scale-bar none disables the rectangular branch-length scale.
  --width, --height, --dpi and --tip-label-size override automatic sizing.
  For all options and column overrides, run bioviz-tree --help above.

Paths and shell quoting:
  Run from a writable working directory. Keep literal shell quotes for spaces:
    taf-bioconductor-bioviz Rscript '"my plot.R"'
    taf-bioconductor-bioviz bioviz-tree --tree '"input tree.nwk"' \
      --title '"Example tree"' --outdir '"tree plots"'
  Prefer script files over inline R expressions. A bare script path is treated
  as a command name; always put Rscript before it.

Results:
  tree.pdf/png/svg plus tree_plot_summary.tsv, tree_tip_annotations.tsv,
  versions.tsv, run.manifest.json and sessionInfo.txt in the chosen directory.
  Open figures with a host viewer. Existing figures are not a completed-run
  marker after failure; use a fresh directory when retrying interrupted runs.

Runtime:
  R 4.6.2 and the required plotting packages are included. Normal plotting is
  offline; no database, model, service, browser port or package download is needed.
  Select a backend with TAFFISH_CONTAINER_BACKEND=docker, podman or apptainer.
  Stop with Ctrl-C. A nonzero exit requires checking the error and output files.
  Installation, shared input mounts, font limitations and citations: README.md.
