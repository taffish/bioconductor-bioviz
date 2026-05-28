suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

bioviz_cli_version <- function() {
  value <- Sys.getenv("BIOVIZ_CLI_VERSION", "0.2.0")
  if (!nzchar(value)) "0.2.0" else value
}

read_table_auto <- function(path) {
  if (is.null(path) || !nzchar(path)) {
    stop("missing input path", call. = FALSE)
  }
  if (!file.exists(path)) {
    stop("input file does not exist: ", path, call. = FALSE)
  }
  data.table::fread(path, data.table = FALSE, check.names = FALSE)
}

normalize_options <- function(opt) {
  names(opt) <- gsub("-", "_", names(opt), fixed = TRUE)
  opt
}

prepare_outdir <- function(outdir, force = FALSE) {
  if (is.null(outdir) || !nzchar(outdir)) {
    stop("--outdir is required", call. = FALSE)
  }
  if (dir.exists(outdir)) {
    existing <- list.files(outdir, all.files = TRUE, no.. = TRUE)
    if (length(existing) && !isTRUE(force)) {
      stop("output directory exists and is not empty: ", outdir,
           " (use --force to overwrite helper outputs)", call. = FALSE)
    }
  } else {
    dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  }
  normalizePath(outdir, mustWork = TRUE)
}

write_tsv <- function(x, path) {
  data.table::fwrite(x, file = path, sep = "\t", quote = FALSE, na = "NA")
}

package_version_or_na <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    as.character(utils::packageVersion(pkg))
  } else {
    NA_character_
  }
}

runtime_versions <- function(extra_packages = character()) {
  pkgs <- unique(c(
    "ape", "treeio", "ggtree", "tidytree", "ggplot2", "svglite", "ragg",
    "optparse", "jsonlite", "readr", "data.table", "ggrepel", "patchwork",
    "cowplot", "scales", "viridis", "RColorBrewer", extra_packages
  ))
  data.frame(
    component = c("R", "Bioconductor", "bioviz-cli", pkgs),
    version = c(
      paste(R.version$major, R.version$minor, sep = "."),
      as.character(BiocManager::version()),
      bioviz_cli_version(),
      vapply(pkgs, package_version_or_na, character(1))
    ),
    stringsAsFactors = FALSE
  )
}

write_versions <- function(outdir, extra_packages = character()) {
  write_tsv(runtime_versions(extra_packages), file.path(outdir, "versions.tsv"))
}

write_manifest <- function(outdir, tool, inputs, outputs, parameters, summary) {
  manifest <- list(
    tool = tool,
    timestamp_utc = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    command_args = commandArgs(trailingOnly = TRUE),
    inputs = inputs,
    outputs = outputs,
    parameters = parameters,
    summary = summary,
    runtime = runtime_versions()
  )
  jsonlite::write_json(manifest, file.path(outdir, "run.manifest.json"),
                       auto_unbox = TRUE, pretty = TRUE, dataframe = "rows")
}

write_session_info <- function(outdir) {
  capture.output(utils::sessionInfo(),
                 file = file.path(outdir, "sessionInfo.txt"))
}

choose_column <- function(df, explicit, candidates, purpose,
                          fallback_position = NULL) {
  if (!is.null(explicit) && nzchar(explicit)) {
    if (!explicit %in% names(df)) {
      stop(purpose, " column not found: ", explicit, call. = FALSE)
    }
    return(explicit)
  }
  hit <- candidates[candidates %in% names(df)]
  if (length(hit)) {
    return(hit[[1]])
  }
  if (!is.null(fallback_position) && ncol(df) >= fallback_position) {
    return(names(df)[[fallback_position]])
  }
  stop("could not infer ", purpose, " column", call. = FALSE)
}

ensure_unique <- function(values, what) {
  dup <- unique(values[duplicated(values)])
  if (length(dup)) {
    stop(what, " contains duplicated ids: ", paste(head(dup, 10), collapse = ", "),
         call. = FALSE)
  }
}

split_formats <- function(value) {
  if (is.null(value) || !nzchar(value)) {
    stop("--formats cannot be empty", call. = FALSE)
  }
  formats <- unique(trimws(unlist(strsplit(value, ",", fixed = TRUE))))
  formats <- formats[nzchar(formats)]
  allowed <- c("pdf", "png", "svg")
  bad <- setdiff(formats, allowed)
  if (length(bad)) {
    stop("unsupported output format(s): ", paste(bad, collapse = ", "),
         "; supported formats are pdf,png,svg", call. = FALSE)
  }
  formats
}
