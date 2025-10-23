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
  "bs4Dash", "bslib", "DT"
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

rsconnect::deployApp(
  appDir = getwd(),
  appFiles = c(
    "app.R",
    "modules/claimsDataModule.R",
    "modules/premiumDataModule.R",
    "modules/exposureResultsModule.R",
    "modules/grossReportedClaimsModule.R",
    "modules/uniqueClaimsModule.R",
    "modules/claimFrequencyModule.R",
    "modules/claimFrequencyVarianceModule.R",
    "modules/severityModule.R",
    "modules/severityVarianceModule.R",
    "modules/riskPremiumModule.R",
    "modules/officePremiumModule.R",
    "modules/frequencyvsSeverityModule.R",
    "www/css/custom_styles.css",
    "www/images",
    "www/favicon"
  ),
  appName = "exposure-frequency-severity-model",
  appTitle = "Exposure Frequency and Severity Model",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

cat("\n=== Deployment Complete! ===\n")
