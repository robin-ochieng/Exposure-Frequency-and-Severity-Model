# Script to generate/update manifest.json and renv.lock
# This ensures your deployment has the correct package dependencies

cat("=== Generating Deployment Files ===\n\n")

# 1. Initialize renv (if not already done)
cat("1. Setting up renv...\n")
if (!requireNamespace("renv", quietly = TRUE)) {
  cat("   Installing renv package...\n")
  install.packages("renv")
}

library(renv)

# Initialize renv project (creates renv.lock)
cat("   Initializing renv project...\n")
tryCatch({
  renv::init(bare = TRUE, restart = FALSE)
  cat("   ✓ renv initialized\n")
}, error = function(e) {
  cat("   Note: renv may already be initialized\n")
})

# Take a snapshot of current packages
cat("\n2. Creating package snapshot...\n")
renv::snapshot(prompt = FALSE)
cat("   ✓ renv.lock created/updated\n")

# 3. Generate manifest.json using rsconnect
cat("\n3. Generating manifest.json...\n")
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  cat("   Installing rsconnect package...\n")
  install.packages("rsconnect")
}

library(rsconnect)

# Write the manifest
tryCatch({
  rsconnect::writeManifest(
    appDir = getwd(),
    appPrimaryDoc = "app.R"
  )
  cat("   ✓ manifest.json created/updated\n")
}, error = function(e) {
  cat("   Error creating manifest:", e$message, "\n")
  cat("   You can create it manually or during deployment\n")
})

cat("\n=== Files Generated ===\n")
cat("✓ renv.lock - Package dependency lockfile\n")
cat("✓ manifest.json - Deployment manifest\n")

cat("\nThese files help Posit Connect Cloud:\n")
cat("  - Install the exact package versions you're using\n")
cat("  - Ensure consistent environment across deployments\n")
cat("  - Speed up future deployments\n")

cat("\n=== Next Steps ===\n")
cat("1. Review the generated files\n")
cat("2. Commit them to git: git add renv.lock manifest.json\n")
cat("3. Deploy using: source('deploy.R')\n")

cat("\nDone! Ready to deploy to Posit Connect Cloud.\n")
