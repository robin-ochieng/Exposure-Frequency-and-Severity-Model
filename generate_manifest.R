# ========================================================================
# Generate manifest.json for Git-based Posit Connect Cloud Deployment
# ========================================================================
# 
# This script creates a manifest.json file with EXACT package versions
# from your local R installation. This ensures Posit Connect installs
# the same versions you have tested locally.
#
# USAGE:
#   1. Open RStudio and set working directory to project root
#   2. Run: source("generate_manifest.R")
#   3. Commit the generated manifest.json to git
#   4. Push to GitHub
#   5. Deploy via Git in Posit Connect Cloud
#
# ========================================================================

cat("\n")
cat("========================================================================\n")
cat("  MANIFEST.JSON GENERATOR FOR POSIT CONNECT CLOUD\n")
cat("========================================================================\n\n")

# Check if we're in the correct directory
if (!file.exists("app.R")) {
  stop("Error: app.R not found! Please run this script from the project root directory.")
}

cat("Step 1: Checking R version...\n")
r_version <- paste(R.version$major, R.version$minor, sep = ".")
cat("   R version:", r_version, "\n\n")

# List of required packages for this Shiny app
required_pkgs <- c(
  "rsconnect",  # For deployment
  "shiny",      # Shiny framework
  "dplyr",      # Data manipulation
  "tidyr",      # Data tidying
  "ggplot2",    # Plotting
  "readr",      # Reading files
  "purrr",      # Functional programming
  "tibble",     # Modern data frames
  "stringr",    # String operations
  "forcats",    # Factor handling
  "lubridate",  # Date/time handling
  "readxl",     # Excel file reading
  "scales",     # Scaling functions
  "plotly",     # Interactive plots
  "ggrepel",    # Label repelling for ggplot2
  "bs4Dash",    # Bootstrap 4 dashboard
  "bslib",      # Bootstrap themes
  "DT"          # DataTables
)

cat("Step 2: Checking installed packages...\n")

# Check which packages are missing
missing <- c()
installed_versions <- list()

for (pkg in required_pkgs) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    missing <- c(missing, pkg)
    cat("   ✗", pkg, "- NOT INSTALLED\n")
  } else {
    version <- as.character(packageVersion(pkg))
    installed_versions[[pkg]] <- version
    cat("   ✓", pkg, version, "\n")
  }
}

# Install missing packages if any
if (length(missing) > 0) {
  cat("\nStep 3: Installing missing packages...\n")
  cat("   Installing:", paste(missing, collapse = ", "), "\n")
  install.packages(missing, dependencies = TRUE)
  
  # Get versions of newly installed packages
  for (pkg in missing) {
    if (requireNamespace(pkg, quietly = TRUE)) {
      version <- as.character(packageVersion(pkg))
      installed_versions[[pkg]] <- version
      cat("   ✓ Installed", pkg, version, "\n")
    } else {
      stop(paste("Failed to install package:", pkg))
    }
  }
} else {
  cat("\n   All required packages are already installed!\n")
}

cat("\nStep 4: Loading rsconnect package...\n")
if (!require("rsconnect", quietly = TRUE)) {
  stop("Error: rsconnect package not available. Cannot generate manifest.")
}
cat("   ✓ rsconnect loaded\n")

cat("\nStep 5: Generating manifest.json...\n")
cat("   This will scan app.R and detect all dependencies...\n")

# Remove old manifest if it exists
if (file.exists("manifest.json")) {
  cat("   Removing old manifest.json...\n")
  file.remove("manifest.json")
}

# Generate manifest using rsconnect
tryCatch({
  rsconnect::writeManifest(
    appDir = getwd(),
    appPrimaryDoc = "app.R",
    appMode = "shiny"
  )
  
  cat("   ✓ manifest.json created successfully!\n")
  
}, error = function(e) {
  cat("   ✗ Error generating manifest:", e$message, "\n")
  stop("Manifest generation failed")
})

# Verify manifest was created
if (!file.exists("manifest.json")) {
  stop("Error: manifest.json was not created!")
}

cat("\nStep 6: Verifying manifest.json...\n")

# Read and parse the manifest
manifest <- jsonlite::fromJSON("manifest.json", simplifyVector = FALSE)

cat("   ✓ Manifest is valid JSON\n")
cat("   ✓ App mode:", manifest$metadata$appmode, "\n")
cat("   ✓ Primary doc:", manifest$metadata$entrypoint, "\n")
cat("   ✓ R version:", manifest$packages$R$version, "\n")

# Count packages in manifest
pkg_count <- length(manifest$packages) - 1  # Subtract 1 for R itself
cat("   ✓ Packages listed:", pkg_count, "\n")

cat("\n========================================================================\n")
cat("  SUCCESS! manifest.json has been generated\n")
cat("========================================================================\n\n")

cat("Package versions captured:\n")
for (pkg in names(installed_versions)) {
  cat("  -", pkg, ":", installed_versions[[pkg]], "\n")
}

cat("\n📋 NEXT STEPS:\n\n")
cat("1. Review the generated manifest.json file\n")
cat("2. Commit it to git:\n")
cat("     git add manifest.json\n")
cat("     git commit -m \"Add manifest.json for Posit Connect deployment\"\n")
cat("     git push origin main\n\n")
cat("3. In Posit Connect Cloud:\n")
cat("   - Go to your content settings\n")
cat("   - Configure Git deployment\n")
cat("   - Repository: robin-ochieng/Exposure-Frequency-and-Severity-Model\n")
cat("   - Branch: main\n")
cat("   - Primary file: app.R\n\n")
cat("4. Click 'Deploy' and Posit Connect will use your manifest.json\n")
cat("   to install the exact package versions you have locally!\n\n")

cat("========================================================================\n\n")
