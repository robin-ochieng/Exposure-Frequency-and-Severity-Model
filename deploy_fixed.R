# Quick Fix Deployment Script for Posit Connect Cloud
# This script ensures all packages are properly detected

cat("=== Preparing for Posit Connect Cloud Deployment ===\n\n")

# Install rsconnect if needed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

library(rsconnect)

# Ensure all required packages are installed
cat("1. Checking and installing required packages...\n")
required_packages <- c(
  "shiny", "dplyr", "tidyr", "ggplot2", "readr", 
  "purrr", "tibble", "stringr", "forcats", "lubridate",
  "readxl", "scales", "plotly", "ggrepel", 
  "bs4Dash", "bslib", "DT", "writexl"
)

for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("   Installing", pkg, "...\n")
    install.packages(pkg)
  } else {
    cat("   ✓", pkg, "\n")
  }
}

cat("\n2. Ready to deploy!\n")
cat("   Make sure you've configured your account with:\n")
cat("   rsconnect::setAccountInfo(name, token, secret)\n\n")

# Deploy with explicit file list to avoid issues
cat("3. Deploying to Posit Connect Cloud...\n\n")

app_files <- c(
  ".Rprofile",
  "app.R",
  list.files("modules", pattern = "\\.R$", recursive = TRUE, full.names = TRUE),
  list.files("www", recursive = TRUE, full.names = TRUE)
)

rsconnect::writeManifest(
  appDir = getwd(),
  appFiles = app_files,
  appPrimaryDoc = "app.R",
  appMode = "shiny"
)

rsconnect::deployApp(
  appDir = getwd(),
  appFiles = app_files,
  appPrimaryDoc = "app.R",
  appName = "exposure-frequency-severity-model",
  appTitle = "Exposure Frequency and Severity Model",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

cat("\n=== Deployment Complete! ===\n")
