# 🔧 Troubleshooting Guide: Fixed the readxl Error

## ✅ What Was Fixed

### The Problem
- **Error:** "readxl was not found in the package registry"
- **Cause:** Using `library(tidyverse)` which is a meta-package that Posit Connect Cloud doesn't properly resolve

### The Solution
Replaced `tidyverse` with individual packages:
- `dplyr` - Data manipulation
- `tidyr` - Data tidying
- `ggplot2` - Plotting
- `readr` - Reading CSV files
- `purrr` - Functional programming
- `tibble` - Modern data frames
- `stringr` - String manipulation
- `forcats` - Factor handling
- `lubridate` - Date/time handling

Plus all your other packages: `readxl`, `scales`, `plotly`, `ggrepel`, `bs4Dash`, `bslib`, `DT`

---

## 🚀 How to Deploy Now

### Option 1: Using RStudio (Recommended)

**Step 1:** Test locally first
```r
source("test_app.R")
```
This will verify all packages load correctly.

**Step 2:** Deploy using the fixed script
```r
source("deploy_fixed.R")
```

### Option 2: Using the Publish Button

1. Open `app.R` in RStudio
2. Click the blue **"Publish"** button (top-right)
3. Select **Posit Connect Cloud**
4. Make sure these files are selected:
   - ✅ app.R
   - ✅ All files in `modules/` folder
   - ✅ All files in `www/` folder
5. Click **Publish**

### Option 3: Manual Deployment

```r
library(rsconnect)

# Configure account (if not done already)
rsconnect::setAccountInfo(
  name = "your-username",
  token = "YOUR-TOKEN",
  secret = "YOUR-SECRET"
)

# Deploy
rsconnect::deployApp(
  appName = "exposure-frequency-severity-model",
  forceUpdate = TRUE,
  launch.browser = TRUE
)
```

---

## 📋 Pre-Deployment Checklist

Before deploying again, make sure:

1. **All packages are installed locally:**
   ```r
   install.packages(c("shiny", "dplyr", "tidyr", "ggplot2", "readr", 
                      "purrr", "tibble", "stringr", "forcats", "lubridate",
                      "readxl", "scales", "plotly", "ggrepel", 
                      "bs4Dash", "bslib", "DT"))
   ```

2. **App runs locally:**
   ```r
   shiny::runApp()
   ```
   
3. **Account is configured:**
   ```r
   rsconnect::accounts()  # Should show your account
   ```

4. **Files are up to date:**
   ```r
   # Pull latest changes if working across machines
   # In terminal: git pull origin main
   ```

---

## 🎯 What Changed in Your Files

### `app.R`
**Before:**
```r
library(tidyverse)
```

**After:**
```r
library(dplyr)
library(tidyr)
library(ggplot2)
library(readr)
library(purrr)
library(tibble)
library(stringr)
library(forcats)
library(lubridate)
```

### `requirements.txt`
Updated to list individual packages instead of `tidyverse`

### New Files Created
- `deploy_fixed.R` - Enhanced deployment script
- `test_app.R` - Local testing script
- `TROUBLESHOOTING.md` - This guide

---

## ⚠️ Common Issues & Solutions

### Issue: "Package X not found"
**Solution:** Install the package locally first:
```r
install.packages("packagename")
```

### Issue: "Account not configured"
**Solution:** Get credentials from https://connect.posit.cloud/ → Tokens
```r
rsconnect::setAccountInfo(name, token, secret)
```

### Issue: "File not found during deployment"
**Solution:** Make sure all module files and www folder exist:
```r
list.files("modules")  # Should show all .R files
list.files("www", recursive = TRUE)  # Should show CSS, images, etc.
```

### Issue: "Deployment still fails"
**Solution:** Try clearing rsconnect cache:
```r
rsconnect::forgetDeployment()
rsconnect::deployApp(forceUpdate = TRUE)
```

---

## 🔄 If You Still Get Errors

1. **Check the deployment logs** in Posit Connect Cloud dashboard
2. **Verify package versions** are compatible
3. **Try deploying with minimal files first:**
   ```r
   # Just deploy app.R and one module to test
   rsconnect::deployApp(
     appFiles = c("app.R", "modules/exposureResultsModule.R")
   )
   ```

4. **Contact support** with the error logs if issues persist

---

## ✨ Success Indicators

You'll know it worked when:
- ✅ Deployment progress reaches 100%
- ✅ Browser opens automatically
- ✅ App interface loads correctly
- ✅ No errors in the Posit Connect Cloud logs

---

## 📞 Need More Help?

- **Posit Community:** https://community.rstudio.com/
- **Posit Connect Docs:** https://docs.posit.co/connect/
- **Your deployment logs:** Check in Posit Connect Cloud dashboard

---

**Good luck! 🚀 The deployment should work now!**
