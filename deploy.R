# Deployment Script for Posit Connect Cloud
# Run this script in RStudio to deploy your Shiny app

# Install rsconnect if not already installed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

library(rsconnect)

app_files <- c(
  ".Rprofile",
  "app.R",
  list.files("modules", pattern = "\\.R$", recursive = TRUE, full.names = TRUE),
  list.files("www", recursive = TRUE, full.names = TRUE)
)

# Keep the Git deployment manifest in sync with the source being published.
rsconnect::writeManifest(
  appDir = getwd(),
  appFiles = app_files,
  appPrimaryDoc = "app.R",
  appMode = "shiny"
)

# Set your Posit Connect Cloud account info
# You'll need to get your API key from: https://connect.posit.cloud/connect/#/apps
# Then run: rsconnect::setAccountInfo(name="your-account-name", 
#                                      token="your-token",
#                                      secret="your-secret")

# Deploy the application
rsconnect::deployApp(
  appDir = getwd(),
  appFiles = app_files,
  appPrimaryDoc = "app.R",
  appName = "exposure-frequency-severity-model",
  appTitle = "Exposure Frequency and Severity Model",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

# Note: The first time you run this, you'll need to authenticate with Posit Connect Cloud
# Follow the prompts in the console
