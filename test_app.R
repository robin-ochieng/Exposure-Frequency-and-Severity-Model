# Test app locally before deployment
# Run this to ensure all packages load correctly

cat("=== Testing App Locally ===\n\n")

cat("1. Loading required packages...\n")

packages_to_test <- c(
  "shiny", "dplyr", "tidyr", "ggplot2", "readr", 
  "purrr", "tibble", "stringr", "forcats", "lubridate",
  "readxl", "scales", "plotly", "ggrepel", 
  "bs4Dash", "bslib", "DT"
)

all_loaded <- TRUE
for (pkg in packages_to_test) {
  result <- tryCatch({
    library(pkg, character.only = TRUE)
    cat("   ✓", pkg, "loaded successfully\n")
    TRUE
  }, error = function(e) {
    cat("   ✗", pkg, "FAILED to load:", e$message, "\n")
    FALSE
  })
  
  if (!result) all_loaded <- FALSE
}

if (all_loaded) {
  cat("\n2. All packages loaded successfully!\n")
  cat("   Starting Shiny app...\n\n")
  
  # Run the app
  shiny::runApp()
} else {
  cat("\n⚠ Some packages failed to load. Install them with:\n")
  cat("install.packages(c('", paste(packages_to_test, collapse = "', '"), "'))\n", sep = "")
}
