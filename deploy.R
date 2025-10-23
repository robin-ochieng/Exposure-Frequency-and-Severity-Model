# Deployment Script for Posit Connect Cloud
# Run this script in RStudio to deploy your Shiny app

# Install rsconnect if not already installed
if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect")
}

library(rsconnect)

# Set your Posit Connect Cloud account info
# You'll need to get your API key from: https://connect.posit.cloud/connect/#/apps
# Then run: rsconnect::setAccountInfo(name="your-account-name", 
#                                      token="your-token",
#                                      secret="your-secret")

# Deploy the application
rsconnect::deployApp(
  appDir = getwd(),
  appName = "exposure-frequency-severity-model",
  appTitle = "Exposure Frequency and Severity Model",
  forceUpdate = TRUE,
  launch.browser = TRUE
)

# Note: The first time you run this, you'll need to authenticate with Posit Connect Cloud
# Follow the prompts in the console
