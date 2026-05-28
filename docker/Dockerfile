FROM bioconductor/bioconductor_docker:RELEASE_3_23

ARG BIOCONDUCTOR_VERSION=3.23
ARG R_VERSION=4.6.0
ARG BIOVIZ_CLI_VERSION=0.1.0

LABEL maintainer="taffish@163.com"

USER root
ENV DEBIAN_FRONTEND=noninteractive
ENV BIOCONDUCTOR_VERSION=${BIOCONDUCTOR_VERSION}
ENV R_VERSION=${R_VERSION}
ENV BIOVIZ_CLI_VERSION=${BIOVIZ_CLI_VERSION}

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      bash \
      build-essential \
      coreutils \
      curl \
      fontconfig \
      grep \
      libcurl4-gnutls-dev \
      libfontconfig1-dev \
      libfreetype6-dev \
      libfribidi-dev \
      libharfbuzz-dev \
      libjpeg-dev \
      libpng-dev \
      libssl-dev \
      libtiff5-dev \
      libxml2-dev \
      pandoc \
      sed; \
    rm -rf /var/lib/apt/lists/*

RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org")); if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager"); stopifnot(as.character(BiocManager::version()) == Sys.getenv("BIOCONDUCTOR_VERSION")); pkgs <- c("ape","treeio","ggtree","tidytree","ggplot2","svglite","ragg","optparse","jsonlite","readr","data.table","ggrepel","patchwork","cowplot","scales","viridis","RColorBrewer"); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) BiocManager::install(missing, ask = FALSE, update = FALSE, Ncpus = 2); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("missing R packages after install: ", paste(missing, collapse = ", "))'

COPY docker/R/ /opt/bioconductor-bioviz/R/
COPY docker/bin/ /opt/bioconductor-bioviz/bin/

ENV PATH=/opt/bioconductor-bioviz/bin:${PATH}

RUN set -eux; \
    chmod 0755 /opt/bioconductor-bioviz/bin/bioviz-*; \
    chmod 0644 /opt/bioconductor-bioviz/R/*.R

RUN set -eux; \
    Rscript --version 2>&1 | grep -F "Rscript (R) version ${R_VERSION}" >/dev/null; \
    Rscript -e "stopifnot(as.character(BiocManager::version()) == '${BIOCONDUCTOR_VERSION}')"; \
    bioviz-runtime-info > /opt/bioconductor-bioviz/runtime-versions.tsv; \
    grep -F "Bioconductor	${BIOCONDUCTOR_VERSION}" /opt/bioconductor-bioviz/runtime-versions.tsv >/dev/null; \
    bioviz-tree --version | grep -Fx "bioviz-tree ${BIOVIZ_CLI_VERSION} (Bioconductor ${BIOCONDUCTOR_VERSION})" >/dev/null; \
    bioviz-tree --help 2>&1 | grep -F "Tree plotting helper for Newick phylogenies" >/dev/null; \
    mkdir -p /tmp/taf-bioviz-check; \
    cd /tmp/taf-bioviz-check; \
    printf '%s\n' '((seq1:0.1,seq2:0.2):0.3,(seq3:0.2,seq4:0.4):0.1);' > tree.nwk; \
    printf '%b\n' \
      'sample	group	region' \
      'seq1	A	leaf' \
      'seq2	A	leaf' \
      'seq3	B	root' \
      'seq4	B	root' > metadata.tsv; \
    printf '%b\n' \
      'sequence_id	label' \
      'seq1	Alpha one' \
      'seq2	Alpha two' \
      'seq3	Beta one' \
      'seq4	Beta two' > label-map.tsv; \
    bioviz-tree --tree tree.nwk --metadata metadata.tsv --label-map label-map.tsv --color-by group --layout rectangular --formats pdf,png,svg --outdir out; \
    test -s out/tree.pdf; \
    test -s out/tree.png; \
    test -s out/tree.svg; \
    test -s out/tree_plot_summary.tsv; \
    test -s out/run.manifest.json; \
    grep -F "metadata_matched_tips" out/tree_plot_summary.tsv >/dev/null; \
    cd /; \
    rm -rf /tmp/taf-bioviz-check

WORKDIR /root

ENV TAFFISH_ENV=TAFFISH
ENV TAFFISH_NAME=bioconductor-bioviz
