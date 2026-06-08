# Test that the checked-in deployment metadata includes runtime dependencies
# introduced by the app code. This is intended to catch Git-backed Connect
# Cloud deployments that would otherwise start without a required package.

manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)

required_packages <- c(
  "shiny",
  "dplyr",
  "tidyr",
  "ggplot2",
  "readr",
  "purrr",
  "tibble",
  "stringr",
  "forcats",
  "lubridate",
  "readxl",
  "scales",
  "plotly",
  "ggrepel",
  "bs4Dash",
  "bslib",
  "DT",
  "writexl"
)

missing_packages <- setdiff(required_packages, names(manifest$packages))

app_source <- readLines("app.R", warn = FALSE)
source_paths <- regmatches(
  app_source,
  gregexpr('source\\("([^"]+)"', app_source)
)
source_paths <- unlist(lapply(source_paths, function(x) {
  sub('^source\\("([^"]+)".*$', "\\1", x)
}))

missing_sources <- source_paths[!file.exists(source_paths)]
unbundled_sources <- setdiff(source_paths, names(manifest$files))

errors <- character()
if (length(missing_packages) > 0) {
  errors <- c(
    errors,
    paste0(
      "manifest.json is missing package(s): ",
      paste(missing_packages, collapse = ", ")
    )
  )
}
if (length(missing_sources) > 0) {
  errors <- c(
    errors,
    paste0(
      "app.R sources missing file(s): ",
      paste(missing_sources, collapse = ", ")
    )
  )
}
if (length(unbundled_sources) > 0) {
  errors <- c(
    errors,
    paste0(
      "manifest.json does not bundle sourced file(s): ",
      paste(unbundled_sources, collapse = ", ")
    )
  )
}
if (length(errors) > 0) {
  stop(paste(errors, collapse = "\n"), call. = FALSE)
}

bundled_paths <- names(manifest$files)
actual_checksums <- unname(tools::md5sum(bundled_paths))
manifest_checksums <- vapply(
  manifest$files,
  function(file) file$checksum,
  character(1)
)
stale_files <- bundled_paths[
  is.na(actual_checksums) | actual_checksums != manifest_checksums
]
if (length(stale_files) > 0) {
  stop(
    "manifest.json has stale checksum(s): ",
    paste(stale_files, collapse = ", "),
    call. = FALSE
  )
}

cat("Deployment manifest dependency check passed.\n")
