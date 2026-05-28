suppressPackageStartupMessages({
  source("/opt/bioconductor-bioviz/R/bioviz_common.R")
})

versions <- runtime_versions()
data.table::fwrite(versions, file = "", sep = "\t", quote = FALSE, na = "NA")
