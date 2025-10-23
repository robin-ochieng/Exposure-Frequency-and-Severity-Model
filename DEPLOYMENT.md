# 🚀 Deploying to Posit Connect Cloud

This guide will help you deploy the Exposure Frequency and Severity Model to Posit Connect Cloud.

## Prerequisites

- R and RStudio installed on your computer
- Posit Connect Cloud account (you already have this!)
- `rsconnect` R package

## 📋 Step-by-Step Deployment Guide

### Method 1: Deploy Using RStudio (Recommended)

#### Step 1: Install Required Packages

Open RStudio and run:

```r
# Install rsconnect package
install.packages("rsconnect")

# Verify all app dependencies are installed
install.packages(c("shiny", "tidyverse", "readxl", "scales", 
                   "plotly", "ggrepel", "bs4Dash", "bslib", "DT"))
```

#### Step 2: Connect RStudio to Posit Connect Cloud

1. **Get your API credentials:**
   - Go to https://connect.posit.cloud/
   - Click on your name (top right) → **Tokens**
   - Click **New Token**
   - Give it a name (e.g., "RStudio Deployment")
   - Copy the **Token** and **Secret**

2. **Configure rsconnect in RStudio:**

```r
library(rsconnect)

# Replace with your actual credentials
rsconnect::setAccountInfo(
  name = "your-account-name",        # Your Posit Connect Cloud username
  token = "your-token-here",         # Token from step 1
  secret = "your-secret-here"        # Secret from step 1
)
```

#### Step 3: Deploy the App

**Option A: Using the Blue Button (Easiest)**

1. Open `app.R` in RStudio
2. Look for the **blue "Publish" button** in the top-right corner of the editor
3. Click it and select **Posit Connect Cloud**
4. Choose the files to include (should include all modules, www folder, etc.)
5. Click **Publish**

**Option B: Using the Deployment Script**

1. Open `deploy.R` in RStudio
2. Update the account information (lines 11-13)
3. Run the entire script: `Ctrl+Shift+Enter` (Windows) or `Cmd+Shift+Enter` (Mac)

**Option C: Using Console Commands**

```r
library(rsconnect)

# Deploy from the app directory
setwd("path/to/your/project")

rsconnect::deployApp(
  appName = "exposure-frequency-severity-model",
  appTitle = "Exposure Frequency and Severity Model",
  launch.browser = TRUE
)
```

#### Step 4: Monitor Deployment

- The deployment process will show progress in the R console
- It may take 5-10 minutes for the first deployment
- Your browser will automatically open the deployed app when ready

---

### Method 2: Deploy Using Command Line

```r
# In R console
library(rsconnect)

# Set working directory to your project
setwd("c:/Users/Robin Ochieng/OneDrive - Kenbright/Attachments/projects/2025/October/Exposure Frequencies and Severity Model")

# Deploy
deployApp(launch.browser = TRUE)
```

---

## 🔧 Troubleshooting

### Issue: "Account not configured"

**Solution:** Run the `setAccountInfo()` command with your credentials.

### Issue: "Package installation failed"

**Solution:** Make sure all packages are installed locally first:

```r
packages <- c("shiny", "tidyverse", "readxl", "scales", 
              "plotly", "ggrepel", "bs4Dash", "bslib", "DT")
install.packages(packages)
```

### Issue: "File size too large"

**Solution:** 
- Remove large data files from the deployment
- Add them to `.rsconnectignore` file
- Upload data separately or load from external sources

### Issue: "Module files not found"

**Solution:** Ensure your `rsconnect` deployment includes the `modules/` directory and `www/` folder.

---

## 📁 Files to Include in Deployment

Make sure these files/folders are included:

✅ `app.R` (main application file)  
✅ `modules/` (all module files)  
✅ `www/` (CSS, images, favicon)  
✅ `.Rprofile` (app settings)  
✅ `requirements.txt` (package list)  

❌ `Data/` (large data files - upload separately if needed)  
❌ `.git/` (version control - automatically excluded)  
❌ `.Rhistory`, `.RData` (automatically excluded)  

---

## 🔒 Creating .rsconnectignore (Optional)

Create a file named `.rsconnectignore` to exclude files from deployment:

```
.git
.gitignore
.Rhistory
.RData
.Rproj.user
*.Rproj
Data/
README.md
deploy.R
DEPLOYMENT.md
```

---

## 📊 After Deployment

### Accessing Your App

- **URL format:** `https://connect.posit.cloud/content/YOUR-CONTENT-ID/`
- You can customize the URL in the Posit Connect Cloud dashboard

### Managing Your App

1. Go to https://connect.posit.cloud/
2. Find your app in the **Content** section
3. You can:
   - View access logs
   - Manage permissions
   - Update settings
   - Redeploy updates

### Updating Your App

After making changes:

```r
# Re-deploy with the same command
rsconnect::deployApp(forceUpdate = TRUE)
```

Or click the **Publish** button again in RStudio.

---

## 🎯 Quick Deployment Checklist

- [ ] Install `rsconnect` package
- [ ] Get API token from Posit Connect Cloud
- [ ] Configure credentials with `setAccountInfo()`
- [ ] Test app locally (run `shiny::runApp()`)
- [ ] Click blue "Publish" button in RStudio
- [ ] Select files to deploy
- [ ] Wait for deployment to complete
- [ ] Test deployed app in browser

---

## 💡 Tips for Success

1. **Test Locally First:** Always run `shiny::runApp()` before deploying
2. **Small Data Files:** Keep uploaded data files under 100 MB
3. **Package Versions:** Posit Connect Cloud will use CRAN package versions
4. **Logs are Your Friend:** Check deployment logs if issues occur
5. **Incremental Updates:** Use `forceUpdate = TRUE` for faster redeployment

---

## 📞 Support

- **Posit Connect Cloud Docs:** https://docs.posit.co/connect/
- **Community Forum:** https://community.rstudio.com/
- **GitHub Issues:** Create issues in your repository

---

**Need help?** The most common issue is credentials. Make sure you've run `setAccountInfo()` correctly!

Good luck with your deployment! 🚀
