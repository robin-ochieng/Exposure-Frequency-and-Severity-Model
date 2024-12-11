library(shiny)
library(tidyverse)
library(readxl)
library(scales)
library(plotly)
library(ggrepel)
library(bs4Dash)
library(bslib)
library(DT)

# Increase max file size to 100 MB
options(shiny.maxRequestSize = 2000 * 1024^2)

#Sourcing the modules
source("modules/claimsDataModule.R", local = TRUE)[1]
source("modules/premiumDataModule.R", local = TRUE)[1] 
source("modules/exposureResultsModule.R", local = TRUE)
source("modules/grossReportedClaimsModule.R", local = TRUE)
source("modules/uniqueClaimsModule.R", local = TRUE)
source("modules/claimFrequencyModule.R", local = TRUE)
source("modules/claimFrequencyVarianceModule.R", local = TRUE)
source("modules/severityModule.R", local = TRUE)
source("modules/severityVarianceModule.R", local = TRUE)
source("modules/riskPremiumModule.R", local = TRUE)
source("modules/officePremiumModule.R", local = TRUE)
source("modules/frequencyvsSeverityModule.R", local = TRUE)



# Define a custom theme using bslib
my_theme <- bs_theme(
  bg = "#202123", 
  fg = "#E1E1E1", 
  primary = "#EA80FC", 
  info = "#17a2b8",
  secondary = "#00BFA5",
  base_font = font_google("Mulish"),
  heading_font = font_google("Mulish"),
  code_font = font_google("Mulish"),
  navbar_bg = "#333333",  # Darker background for the navbar for contrast
  navbar_fg = "#ffffff"  # White text color for readability
)


# Define the User Interface for the Application
ui <- bs4DashPage(
  dark = NULL,
  help = NULL,
  fullscreen = FALSE,
  freshTheme = my_theme,
  header = bs4DashNavbar(
    fixed = TRUE,
    sidebarIcon = NULL,
    controlbarIcon = NULL,
    status = "white",
    skin = "dark",
    tags$li(
      class = "text-center header-title-container",  # Added a new class for more specific styling
      tags$h4("Exposure Frequency and Severity Model", class = "header-title")
    )
  ),
  sidebar = bs4DashSidebar(
    skin = "light",
    tags$div(
      class = "menu-container",
    bs4SidebarMenu(
      bs4SidebarMenuItem("Premium Data View", tabName = "viewPremiumData", icon = icon("file-invoice-dollar")),
      bs4SidebarMenuItem("Claims Data View", tabName = "viewClaimsData", icon = icon("file-alt")),
      bs4SidebarMenuItem("Exposure Results", tabName = "viewExposureResults", icon = icon("chart-area")),
      bs4SidebarMenuItem("Gross Reported Claims", tabName = "viewGrossReportedClaims", icon = icon("chart-bar")),
      bs4SidebarMenuItem("Unique Claims ", tabName = "viewUniqueClaimsSummary", icon = icon("clipboard-check")),
      bs4SidebarMenuItem("Claim Frequencies", tabName = "viewClaimFrequencies", icon = icon("chart-pie")),
      bs4SidebarMenuItem("Claim Severities", tabName = "viewClaimSeverities", icon = icon("exclamation-triangle")),
      bs4SidebarMenuItem("Risk Premium", tabName = "viewRiskPremium", icon = icon("coins")),
      bs4SidebarMenuItem("Office Premium", tabName = "viewOfficePremium", icon = icon("building")),
      bs4SidebarMenuItem("Freq. vs Severity Plot", tabName = "plot1", icon = icon("balance-scale"))
    )),
    div(class = "sidebar-logo",
        img(src = "images/kenbright.png")
    )
  ),
  controlbar = NULL,
  body = dashboardBody(
    tags$head(
        includeCSS("www/css/custom_styles.css"),
        tags$link(href = "https://fonts.googleapis.com/css?family=Mulish", rel = "stylesheet")
    ),
    bs4TabItems(
      bs4TabItem(
         tabName = "viewPremiumData",
         premiumDataInputUI("premiumDataModule")
      ),
      bs4TabItem(
         tabName = "viewClaimsData",
         claimsDataInputUI("claimsDataModule") 
      ),
      bs4TabItem(
         tabName = "viewExposureResults",
         exposureResultsUI("exposureResults")
      ),
      bs4TabItem(
        tabName = "viewGrossReportedClaims",
        grossReportedClaimsUI("grossReportedClaims")
      ),
      bs4TabItem(
        tabName = "viewUniqueClaimsSummary",
        uniqueClaimsResultsUI("uniqueClaimsModule")
      ),
      bs4TabItem(tabName = "viewClaimFrequencies",
                 fluidRow(claimsFrequencyUI("claimsFrequency")),
                 fluidRow(claimsFrequencyVarianceUI("claimsFrequencyVariance"))
      ),
      bs4TabItem(tabName = "viewClaimSeverities",
                 fluidRow(severityUI("severity")),
                 fluidRow(severityVarianceUI("severityVariance"))
      ),
      bs4TabItem(tabName = "viewRiskPremium",
                 fluidRow(riskPremiumUI("riskPremium"))
      ),
      bs4TabItem(tabName = "viewOfficePremium",
                 fluidRow(officePremiumUI("officePremium"))
                 ),
      bs4TabItem(tabName = "plot1",
                 frequencyvsSeverityUI("frequencyvsSeverity")
                 )
    )
  )
)

# Define the server logic required to read the input and calculate outputs
server <- function(input, output, session) {
  
  observeEvent(input$toggleControlbar, {
    updateBoxSidebar("controlbar")
  })
  
  processedData <- callModule(premiumDataInput, "premiumDataModule") 


  processedClaimsData  <- callModule(claimsDataInput, "claimsDataModule")


  Exposure_Results <- exposureResultsServer("exposureResults", processedData)


  Gross_Reported_Claims <- grossReportedClaimsServer("grossReportedClaims", processedClaimsData)


  Unique_Results <- uniqueClaimsResultsServer("uniqueClaimsModule", processedClaimsData)


  Frequency_Results <- claimsFrequencyServer("claimsFrequency", Unique_Results, Exposure_Results$Exposure_Results)
 

  claimsFrequencyVarianceServer("claimsFrequencyVariance", Frequency_Results)
  

  Severity_Results <- severityServer("severity", Unique_Results, Gross_Reported_Claims)


  severityVarianceServer("severityVariance", Severity_Results)


  Risk_Premium <- riskPremiumServer("riskPremium", Unique_Results, Frequency_Results, Severity_Results)


  officePremiumServer("officePremium", Risk_Premium, 
                      yearStart = Exposure_Results$yearStart, 
                      yearEnd = Exposure_Results$yearEnd)
  
 

  frequencyvsSeverityServer("frequencyvsSeverity", Frequency_Results, Severity_Results)
  

  
}

# Run the application
shinyApp(ui = ui, server = server)