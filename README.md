# taf-bioconductor-bioviz

TAFFISH-maintained R/Bioconductor bioinformatics visualization runtime for
tree plots and future flow-facing biological visual summaries. It is not a
wrapper around a single upstream package; it is a curated R/Bioconductor
environment plus stable helper CLIs.

## Package Identity

- name: `bioconductor-bioviz`
- command: `taf-bioconductor-bioviz`
- TAFFISH version: `3.23-r2`
- kind: `tool`
- container image: `ghcr.io/taffish/bioconductor-bioviz:3.23-r2`
- upstream runtime: Bioconductor `3.23` on R `4.6.0`
- default command: `Rscript`
- helper commands: `bioviz-runtime-info`, `bioviz-tree`
- upstream/base license boundary: multiple open-source licenses across R, Bioconductor, CRAN, and system packages
- TAFFISH wrapper/helper license: Apache-2.0

## Installation

```bash
taf install bioconductor-bioviz
taf-bioconductor-bioviz --help
```

The app uses a thin TAFFISH container wrapper:

```taf
<taf-app:container:ghcr.io/taffish/bioconductor-bioviz:3.23-r2>
Rscript ::*ARGV*::
```

Wrapper-level help and version are separate from the R runtime:

```bash
taf-bioconductor-bioviz --help
taf-bioconductor-bioviz --version
taf-bioconductor-bioviz -- --version
taf-bioconductor-bioviz Rscript --version
taf-bioconductor-bioviz bioviz-runtime-info
```

Because `command_mode = true`, use explicit commands for the second layer:

```bash
taf-bioconductor-bioviz Rscript plot_custom.R
taf-bioconductor-bioviz bioviz-tree --help
taf-bioconductor-bioviz bioviz-runtime-info
```

## Included Runtime

The image is based on the official Bioconductor Docker release image:

```text
bioconductor/bioconductor_docker:RELEASE_3_23
```

The Dockerfile verifies R `4.6.0`, Bioconductor `3.23`, and required package
availability during the image build. It installs or retains these main packages:

- tree and phylogeny packages: `ape`, `treeio`, `ggtree`, `tidytree`
- plotting and output packages: `ggplot2`, `svglite`, `ragg`, `ggrepel`, `patchwork`, `cowplot`, `scales`, `viridis`, `RColorBrewer`
- CLI/table/provenance packages: `optparse`, `jsonlite`, `readr`, `data.table`
- system/runtime helpers: `bash`, `pandoc`, font and image libraries needed by `ragg` and `svglite`

Package patch versions are recorded in the built image at
`/opt/bioconductor-bioviz/runtime-versions.tsv` and can be printed with:

```bash
taf-bioconductor-bioviz bioviz-runtime-info
```

If a future rebuild changes package patch versions within the same
Bioconductor release, the public TAFFISH app release should be advanced rather
than silently replacing the old image.

## Helper CLIs

### `bioviz-tree`

Plots a Newick phylogenetic tree with optional metadata and display-label map.
This is the stable helper intended for phylogeny flows. The r2 release changes
the default tree rendering to a cleaner publication-oriented style and adds
automatic plot dimensions, right-side label padding, and unclipped output
rendering for long tip labels.

```bash
taf-bioconductor-bioviz bioviz-tree \
  --tree tree.nwk \
  --metadata sample_metadata.tsv \
  --label-map sequence_id_map.tsv \
  --color-by group \
  --layout rectangular \
  --formats pdf,png,svg \
  --outdir plots
```

Expected inputs:

- `--tree`: a single Newick tree file readable by `ape::read.tree`.
- `--metadata`: optional TSV/CSV table keyed by original tree tip labels.
- `--label-map`: optional two-column table mapping original tree tip labels to display labels.

Column detection is intentionally simple and flow-friendly:

- metadata id column is inferred from `sample`, `sample_id`, `id`, `sequence_id`, `tip`, `tip_label`, or `label`; override with `--metadata-id-column`.
- label-map source column is inferred from `sequence_id`, `id`, `tip`, `tip_label`, `old_id`, or `from`; override with `--label-map-from`.
- label-map target column is inferred from `label`, `display_label`, `name`, `sample`, `new_id`, or `to`; override with `--label-map-to`.

Style and canvas behavior:

- `--style journal` is the default and uses lighter branches, no default tip dots without metadata, automatic dimensions, and extra label-safe plot margins.
- `--style classic` keeps a heavier traditional tree look.
- `--style minimal` is a quieter compact style.
- `--label-align none` is the default. Use `--label-align guide` only when aligned dotted tip guides are desired.
- `--label-transform pretty` can turn underscores into spaces and `|` into readable separators for review figures; the default `none` preserves labels exactly.
- `--scale-bar auto` is the default and draws a scale bar for rectangular trees with branch lengths; use `--scale-bar none` for branchless cladograms or compact thumbnails.
- `--width`, `--height`, `--tip-label-size`, `--point-size`, `--label-offset`, and `--right-padding` can override the automatic choices.
- `--title` is recorded in the summary and manifest; titles with spaces are tolerated when TAFFISH-generated shell code splits the words.

Main outputs:

- `tree.pdf`, `tree.png`, and/or `tree.svg`, depending on `--formats`
- `tree_plot_summary.tsv`
- `tree_tip_annotations.tsv`
- `versions.tsv`
- `run.manifest.json`
- `sessionInfo.txt`

Supported layouts are `rectangular`, `circular`, and `fan`. Supported
output formats are `pdf`, `png`, and `svg`.

## Custom R Scripts

Users can run custom visualization scripts through the same pinned runtime:

```bash
taf-bioconductor-bioviz Rscript custom_plot.R
taf-bioconductor-bioviz -- -e 'library(ggtree); packageVersion("ggtree")'
```

For script paths, prefer explicit `Rscript`. A bare positional path such as
`taf-bioconductor-bioviz custom_plot.R` is interpreted by TAFFISH command mode
as a container command name, not as an argument to the default `Rscript`.

## Boundaries

This app deliberately starts with `Rscript` plus `bioviz-tree`. It is a
general visualization runtime, but this release does not yet promise helper CLIs for
volcano plots, PCA, heatmaps, enrichment dotplots, or report assembly. Those
should be added as named helpers only when a flow needs a stable reusable
interface and the helper has its own smoke coverage.

This app does not infer trees, align sequences, build gene trees, run
orthology, query online annotation services, or bundle project-specific color
palettes and metadata. Use separate TAFFISH tools or explicit workflow inputs
for MAFFT, MUSCLE, IQ-TREE, FastTree, OrthoFinder, and reference metadata.

Normal helper runs should not install R packages or download core plotting
dependencies at runtime. Network-dependent resources, custom annotation
databases, and project-specific assets should be passed explicitly by the flow
or user.

The image is expected to be large because it fixes a complete R/Bioconductor
visualization stack. That is intentional: downstream flows should not install
R packages at runtime or borrow `Rscript` from unrelated tool images.

## Smoke Coverage

Smoke tests check:

- Rscript reports R `4.6.0`.
- `BiocManager::version()` is exactly `3.23`.
- all required Bioconductor/CRAN packages can be loaded.
- helper help/version pages are available.
- `bioviz-tree` renders a rectangular journal-style tree with metadata, long labels, and label-safe canvas behavior to PDF, PNG, and SVG.
- `bioviz-tree` renders an independent circular PNG tree without tip labels.

Each smoke test creates its own `/tmp/taf-bioviz-*` fixture and does not depend
on state from another smoke command.

## Upstream

- Bioconductor homepage: <https://bioconductor.org/>
- Bioconductor install page: <https://bioconductor.org/install/>
- Bioconductor 3.23 release: <https://www.bioconductor.org/news/bioc_3_23_release/>
- Bioconductor Docker documentation: <https://www.bioconductor.org/help/docker/>
- package citations: use `citation("ggtree")`, `citation("treeio")`, `citation("ape")`, `citation("ggplot2")`, or the relevant package name inside R

The TAFFISH app repository code and documentation are Apache-2.0. The container
runtime includes R, Bioconductor, CRAN, Debian, and package-specific components
under their respective upstream licenses.
