# taf-bioconductor-bioviz

A curated R/Bioconductor environment for static biological figures, with
`bioviz-tree` for Newick trees. This is not the complete Bioconductor catalog
or a tree-inference pipeline.

## Identity and installation

- App: `bioconductor-bioviz 3.24-r1`; command: `taf-bioconductor-bioviz`.
- Image: `ghcr.io/taffish/bioconductor-bioviz:3.24-r1`.
- Runtime: Bioconductor `3.24`, R `4.6.2`; helper CLI `0.2.0`.
- Platforms: native `linux/amd64` and `linux/arm64`.
- Required host software: TAFFISH and a configured Docker, Podman or Apptainer
  backend. No host R installation is required.

```sh
taf install bioconductor-bioviz
taf-bioconductor-bioviz --help
taf-bioconductor-bioviz --version
taf-bioconductor-bioviz Rscript --version
taf-bioconductor-bioviz bioviz-runtime-info
```

The wrapper version describes the app. `bioviz-runtime-info` prints the actual
R, Bioconductor and main package versions. The wrapper supports command mode:
always use `Rscript script.R`, not a bare script filename. `--compile` prints
the generated command without executing it.

## Plot a tree

```sh
taf-bioconductor-bioviz bioviz-tree --tree tree.nwk \
  --metadata metadata.tsv --label-map labels.tsv --color-by group \
  --layout rectangular --formats pdf,png,svg --outdir plots
```

Inputs:

- `--tree`: one Newick tree, read with `ape::read.tree`; input is not modified.
- `--metadata`: optional TSV/CSV keyed by original tip labels. The ID column
  is inferred from `sample`, `sample_id`, `id`, `sequence_id`, `tip`,
  `tip_label` or `label`; override with `--metadata-id-column`.
- `--label-map`: optional table mapping original IDs to display labels. Source
  candidates are `sequence_id`, `id`, `tip`, `tip_label`, `old_id`, `from`;
  target candidates are `label`, `display_label`, `name`, `sample`,
  `new_id`, `to`. Override with `--label-map-from` and `--label-map-to`.
  Without a recognized name, the first/second column is used respectively.
- Duplicate metadata/map IDs are rejected. Unmatched labels keep their original
  ID; metadata matches and missing values are recorded in the output.

Defaults are `--layout rectangular --style journal --formats pdf,png,svg`,
`--label-align none --label-transform none --scale-bar auto`.
Other layouts are `circular` and `fan`; other styles are `classic` and
`minimal`. A numeric `--color-by` field uses a continuous color scale;
categorical fields use group colors. Without metadata there are no default
tip dots in journal style.

`--label-align guide` adds dotted guides. `--label-transform pretty` replaces
underscores/pipes only in display labels. The rectangular scale bar represents
branch-length units, not support or time. Use `--scale-bar none` to suppress it.
`--width`, `--height` (inches), `--dpi`, `--tip-label-size`,
`--label-offset` and `--right-padding` override automatic sizing.
Run `taf-bioconductor-bioviz bioviz-tree --help` for the complete options.

## Paths, custom R and quoting

Run in a writable working directory. TAFFISH compiles arguments into shell
code; preserve literal shell quotes around a path/title that contains spaces:

```sh
taf-bioconductor-bioviz Rscript '"my plot.R"'
taf-bioconductor-bioviz bioviz-tree --tree '"input tree.nwk"' \
  --title '"Example tree"' --outdir '"tree plots"'
```

The outer single quotes are consumed by the host shell; the inner double quotes
reach the generated command. For complicated expressions, put R code in a file
and invoke explicit `Rscript`, rather than embedding several levels of `-e`
quoting. Treat scripts and shell arguments as trusted code, not untrusted input.

## Outputs, overwrite and retry

The requested formats create `tree.pdf`, `tree.png`, `tree.svg`. Each run
also writes `tree_plot_summary.tsv`, `tree_tip_annotations.tsv`,
`versions.tsv`, `run.manifest.json` and `sessionInfo.txt`.
The summary preserves the existing phylogeny Flow field names, including
`tip_count`, `layout`, `formats`, `style`, `label_align`,
`label_transform`, `metadata_matched_tips` and output paths.
These are technical plot/provenance records, not scientific validation of a tree.

A nonempty output directory is refused unless `--force` is explicit.
`--force` overwrites named helper outputs, not unrelated files; avoid using it
in directories containing important results. Rendering is not transactional:
an error or Ctrl-C can leave partial outputs, and an old manifest is not a
completion marker for a failed overwrite. Retry in a fresh directory and check
the exit status. There is no resume or automatic deletion facility.

## Resources and backends

The image includes `ape`, `treeio`, `ggtree`, `tidytree`, `ggplot2`,
`svglite`, `ragg`, `ggrepel`, `patchwork`, `cowplot`, `scales`,
`viridis`, `RColorBrewer`, `optparse`, `jsonlite`, `readr` and
`data.table`, plus the official base's system/font dependencies.
It does not require a downloadable database/model. Newick, annotations and
project assets are user-supplied inputs; normal helper runs are offline.
There is no resource discovery/downloader or automatic package installation.
Custom scripts may deliberately access networks or install packages; that is
outside the offline helper contract.

Choose the backend without changing the command:

```sh
TAFFISH_CONTAINER_BACKEND=docker taf-bioconductor-bioviz bioviz-runtime-info
TAFFISH_CONTAINER_BACKEND=podman taf-bioconductor-bioviz bioviz-runtime-info
TAFFISH_CONTAINER_BACKEND=apptainer taf-bioconductor-bioviz bioviz-runtime-info
```

For personal inputs, place readable files under your working directory. For
shared inputs, an administrator prepares the files once in a site directory
(for example `/srv/bioviz-inputs`, directories 0755, data files 0644), and users
mount it read-only. No app-specific install command is needed; the administrator
remains responsible for the source and license of those project inputs.

```sh
TAFFISH_CONTAINER_BACKEND=docker \
TAFFISH_DOCKER_RUN_ARGS='-v /srv/bioviz-inputs:/inputs:ro' \
taf-bioconductor-bioviz bioviz-tree --tree /inputs/tree.nwk --outdir plots-docker

TAFFISH_CONTAINER_BACKEND=podman \
TAFFISH_PODMAN_RUN_ARGS='-v /srv/bioviz-inputs:/inputs:ro' \
taf-bioconductor-bioviz bioviz-tree --tree /inputs/tree.nwk --outdir plots-podman

TAFFISH_CONTAINER_BACKEND=apptainer \
TAFFISH_APPTAINER_RUN_ARGS='--bind /srv/bioviz-inputs:/inputs:ro' \
taf-bioconductor-bioviz bioviz-tree --tree /inputs/tree.nwk --outdir plots-apptainer
```

On macOS, the selected VM must be permitted to share the actual host path.
SELinux sites must arrange a suitable read-only label; do not disable isolation
or recursively relabel shared data as a workaround. Output belongs in the
user's writable working directory, not the image library or shared input root.

## Figures and service boundary

Open PDF/PNG/SVG on the host. There is no HTML dashboard, browser port or GUI
launcher. The official base contains RStudio/Shiny-related components, but this
app does not start or promise those independent services; its default container
command is Rscript help, not the base's service initializer.
No Cytoscape, noVNC, Jupyter or unrelated viewer is added.

Font coverage and rendering depend on the device and available fonts. Inspect
the final figure, especially long labels and non-ASCII text, before publication.
Base R PDF devices have more limited Unicode handling than PNG/SVG; custom R
scripts can select an appropriate font and device. A successful exit alone does
not prove every glyph is displayed correctly.

## Build and reproducibility

The Dockerfile uses the official `RELEASE_3_24` multi-platform digest
`sha256:4d674c1916aecfe940d95a8135fa67f2529aa431364fb3b7ff2d23a52a8ed363`.
The base is fixed, but upstream Bioconductor/CRAN repositories are not a complete
time-frozen snapshot: patch versions and archive availability may change.
Installed R and system inventories are retained under
`/opt/bioconductor-bioviz/` as `installed-packages.tsv`,
`runtime-versions.tsv` and `system-packages.tsv`.
Inventories document what was built; they are not a repository lock or a promise
of bit-identical future rebuilds. Changed dependencies require a new validated
TAFFISH app release, not replacement of a published image.

Build checks are lightweight version/import checks. Runtime acceptance covers
actual tree figures, annotations, output semantics, negative cases and the
generated wrapper. The inherited official base is large; deleting its files in
a later layer would not reclaim its lower-layer size.
The locally built images occupy 5,137,563,056 bytes on ARM64 and 5,228,287,712
bytes on amd64 (uncompressed engine sizes, not download sizes). Most of this is
the official base; the amd64 base alone occupies 5,073,141,875 bytes. The added
R plotting packages and small helpers account for about 155 MB on that platform.
Keeping the established official-base route preserves its tested R/system
integration; this app does not claim a minimal R-only distribution.

## Upstream, citation and licenses

- [Bioconductor 3.24 release](https://bioconductor.org/news/bioc_3_24_release/)
- [Installation](https://bioconductor.org/install/)
- [Official Docker documentation](https://bioconductor.org/help/docker/)
- Use `citation("ggtree")`, `citation("treeio")`, `citation("ape")` or the
  relevant package name in an R script for package-specific citations.

TAFFISH wrapper/helper code is Apache-2.0. R, CRAN, Bioconductor, Ubuntu and
inherited components retain their own licenses, recorded in the image inventory
and installed package metadata. No wrapper license supersedes them. Users must
check separately the permissions for their trees, annotations, fonts and other
input assets.
