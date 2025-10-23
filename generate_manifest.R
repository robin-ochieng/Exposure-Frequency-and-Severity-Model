# Generate a valid manifest.json for Posit Connect Cloud
# Run this script in RStudio (or R terminal) from the project root:
#   source("generate_manifest.R")
# This will create/overwrite manifest.json with the correct package metadata.

required_pkgs <- c(
  "rsconnect", "shiny", "dplyr", "tidyr", "ggplot2", "readr", 
  "purrr", "tibble", "stringr", "forcats", "lubridate",
  "readxl", "scales", "plotly", "ggrepel", "bs4Dash", 
  "bslib", "DT"
)

missing <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  install.packages(missing)
}

# Load rsconnect and write manifest
rsconnect::writeManifest(
  appDir = getwd(),
  appPrimaryDoc = "app.R"
)

message("manifest.json generated successfully. Commit and push it before deploying via Git.")
