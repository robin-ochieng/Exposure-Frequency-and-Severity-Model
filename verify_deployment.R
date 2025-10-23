# Pre-Deployment Verification Script
# Run this before deploying to check if everything is ready

cat("=== Posit Connect Cloud Deployment Verification ===\n\n")

# Check if rsconnect is installed
cat("1. Checking rsconnect package...\n")
if (requireNamespace("rsconnect", quietly = TRUE)) {
  cat("   ✓ rsconnect is installed\n")
  cat("   Version:", as.character(packageVersion("rsconnect")), "\n")
} else {
  cat("   ✗ rsconnect is NOT installed\n")
  cat("   Install it with: install.packages('rsconnect')\n")
}

cat("\n2. Checking required packages...\n")
required_packages <- c("shiny", "tidyverse", "readxl", "scales", 
                       "plotly", "ggrepel", "bs4Dash", "bslib", "DT")

missing_packages <- c()
for (pkg in required_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("   ✓", pkg, "\n")
  } else {
    cat("   ✗", pkg, "- NOT INSTALLED\n")
    missing_packages <- c(missing_packages, pkg)
  }
}

if (length(missing_packages) > 0) {
  cat("\n   Install missing packages with:\n")
  cat("   install.packages(c('", paste(missing_packages, collapse = "', '"), "'))\n", sep = "")
}

cat("\n3. Checking project files...\n")
files_to_check <- c("app.R", "modules", "www")
for (file in files_to_check) {
  if (file.exists(file)) {
    cat("   ✓", file, "exists\n")
  } else {
    cat("   ✗", file, "NOT FOUND\n")
  }
}

cat("\n4. Checking rsconnect account configuration...\n")
accounts <- rsconnect::accounts()
if (nrow(accounts) > 0) {
  cat("   ✓ Account configured:", accounts$name[1], "\n")
  cat("   Server:", accounts$server[1], "\n")
} else {
  cat("   ✗ No account configured\n")
  cat("   Configure with: rsconnect::setAccountInfo(name, token, secret)\n")
}

cat("\n5. Testing app locally...\n")
cat("   Run: shiny::runApp() to test before deploying\n")

cat("\n=== Verification Complete ===\n")
if (length(missing_packages) == 0 && nrow(accounts) > 0) {
  cat("\n✓ Ready to deploy!\n")
  cat("Run: source('deploy.R') or click the Publish button in RStudio\n")
} else {
  cat("\n⚠ Please fix the issues above before deploying\n")
}
