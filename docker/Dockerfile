# The official multi-platform release is fixed by digest, including R and system
# dependencies. If this digest disappears, verify a replacement official release
# and repeat both native builds; never silently fall back to a moving tag.
FROM bioconductor/bioconductor_docker:RELEASE_3_24@sha256:4d674c1916aecfe940d95a8135fa67f2529aa431364fb3b7ff2d23a52a8ed363

ARG BIOCONDUCTOR_VERSION=3.24
ARG R_VERSION=4.6.2
ARG BIOVIZ_CLI_VERSION=0.2.0

LABEL maintainer="taffish@163.com"

USER root
ENV BIOCONDUCTOR_VERSION=${BIOCONDUCTOR_VERSION} \
    R_VERSION=${R_VERSION} \
    BIOVIZ_CLI_VERSION=${BIOVIZ_CLI_VERSION}

# Bioconductor's release repository and CRAN remain upstream-managed sources:
# dependency patch versions and archive availability can change on later rebuilds.
# The pinned base is immutable; this installation is not a full repository snapshot.
# Keep the installed inventory, diagnose missing/changed packages, and validate a
# new app release before publishing a replacement. Do not weaken version checks or
# install development packages to make a missing release dependency appear to pass.
RUN Rscript -e 'options(repos = c(CRAN = "https://cloud.r-project.org"), timeout = 600); stopifnot(as.character(getRversion()) == Sys.getenv("R_VERSION")); stopifnot(requireNamespace("BiocManager", quietly = TRUE)); stopifnot(as.character(BiocManager::version()) == Sys.getenv("BIOCONDUCTOR_VERSION")); pkgs <- c("ape","treeio","ggtree","tidytree","ggplot2","svglite","ragg","optparse","jsonlite","readr","data.table","ggrepel","patchwork","cowplot","scales","viridis","RColorBrewer"); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) BiocManager::install(missing, version = Sys.getenv("BIOCONDUCTOR_VERSION"), ask = FALSE, update = FALSE, Ncpus = 2); missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]; if (length(missing)) stop("missing R packages after install: ", paste(missing, collapse = ", "))'

COPY docker/R/ /opt/bioconductor-bioviz/R/
COPY docker/bin/ /opt/bioconductor-bioviz/bin/

ENV PATH=/opt/bioconductor-bioviz/bin:${PATH}

# Do not render figures or assert numeric/pixel equality during image builds.
# The full plot and ordinary-user/read-only checks run against the finished image.
RUN set -eu; \
    chmod 0755 /opt/bioconductor-bioviz /opt/bioconductor-bioviz/R /opt/bioconductor-bioviz/bin; \
    chmod 0755 /opt/bioconductor-bioviz/bin/bioviz-*; \
    chmod 0644 /opt/bioconductor-bioviz/R/*.R; \
    bioviz-runtime-info > /opt/bioconductor-bioviz/runtime-versions.tsv; \
    Rscript -e 'p <- installed.packages(fields = c("License", "Repository")); write.table(p[,c("Package","Version","License","Repository","Built")], "/opt/bioconductor-bioviz/installed-packages.tsv", sep="\t", row.names=FALSE, quote=TRUE)'; \
    dpkg-query -W > /opt/bioconductor-bioviz/system-packages.tsv; \
    bioviz-tree --version; \
    chmod 0644 /opt/bioconductor-bioviz/*.tsv

WORKDIR /tmp
ENV TAFFISH_ENV=TAFFISH TAFFISH_NAME=bioconductor-bioviz
# This app exposes a CLI, not the RStudio service inherited from the base image.
CMD ["Rscript", "--help"]
