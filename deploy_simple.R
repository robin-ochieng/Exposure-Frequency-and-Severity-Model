# SIMPLE DEPLOYMENT SCRIPT - No manifest.json needed
# Posit Connect Cloud will auto-detect dependencies from app.R

cat("=== Simple Deployment to Posit Connect Cloud ===\n\n")

# Install rsconnect if needed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("Installing rsconnect...\n")
  install.packages("rsconnect")
}

library(rsconnect)

# Check account configuration
cat("1. Checking account configuration...\n")
accounts <- rsconnect::accounts()
if (nrow(accounts) == 0) {
  cat("   ✗ No account configured!\n")
  cat("   Please run:\n")
  cat("   rsconnect::setAccountInfo(name='your-username', token='YOUR-TOKEN', secret='YOUR-SECRET')\n\n")
  stop("Account not configured")
} else {
  cat("   ✓ Account configured:", accounts$name[1], "\n\n")
}

# Make sure all packages are installed locally
cat("2. Verifying packages are installed...\n")
required_pkgs <- c("shiny", "dplyr", "tidyr", "ggplot2", "readr", 
                   "purrr", "tibble", "stringr", "forcats", "lubridate",
                   "readxl", "scales", "plotly", "ggrepel", 
                   "bs4Dash", "bslib", "DT", "writexl")

missing <- c()
for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat("   ✗", pkg, "is missing\n")
    missing <- c(missing, pkg)
  } else {
    cat("   ✓", pkg, "\n")
  }
}

if (length(missing) > 0) {
  cat("\n   Installing missing packages...\n")
  install.packages(missing)
}

# Deploy without manifest files - let rsconnect auto-detect
cat("\n3. Deploying to Posit Connect Cloud...\n")
cat("   (This may take 5-10 minutes)\n\n")

# Remove any existing deployment metadata to start fresh
if (dir.exists("rsconnect")) {
  cat("   Removing old deployment metadata...\n")
  unlink("rsconnect", recursive = TRUE)
}

# Deploy - rsconnect will scan the application files and detect dependencies
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
  launch.browser = TRUE,
  logLevel = "verbose"
)

cat("\n=== Deployment Complete! ===\n")
cat("Your app should open in a browser automatically.\n")
