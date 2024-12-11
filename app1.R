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

# Define a custom theme using bslib
my_theme <- bs_theme(
  bootswatch = "minty",
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
ui <- dashboardPage(
  dark = NULL,
  help = NULL,
  fullscreen = FALSE,
  scrollToTop = TRUE,
  freshTheme = my_theme,
  header = bs4DashNavbar(
    status = "primary",
    skin = "dark",
    title = dashboardBrand(
      title = "Exposure, Freq & Severity",
      color = "primary",
      image = ""
    ),
    actionButton("toggleControlbar", "Input Controls", class = "btn btn-primary")
  ),
  sidebar = bs4DashSidebar(
    skin = "light",
    bs4SidebarMenu(
      bs4SidebarMenuItem("Premium Data View", tabName = "viewPremiumData", icon = icon("file-invoice-dollar")),
      bs4SidebarMenuItem("Claims Data View", tabName = "viewClaimsData", icon = icon("file-alt")),
      bs4SidebarMenuItem("Exposure Results", tabName = "viewExposureResults", icon = icon("chart-area")),
      bs4SidebarMenuItem("Gross Reported Claims", tabName = "viewGrossReportedClaims", icon = icon("chart-bar")),
      bs4SidebarMenuItem("Unique Claims Summary", tabName = "viewUniqueClaimsSummary", icon = icon("clipboard-check")),
      bs4SidebarMenuItem("Claim Frequencies", tabName = "viewClaimFrequencies", icon = icon("chart-pie")),
      bs4SidebarMenuItem("Claim Severities", tabName = "viewClaimSeverities", icon = icon("exclamation-triangle")),
      bs4SidebarMenuItem("Risk Premium", tabName = "viewRiskPremium", icon = icon("coins")),
      bs4SidebarMenuItem("Office Premium", tabName = "viewOfficePremium", icon = icon("building")),
      bs4SidebarMenuItem("Freq. vs Severity Plot", tabName = "plot1", icon = icon("balance-scale"))
    )
  ),
  controlbar = bs4DashControlbar(
    id = "controlbar",
    skin = "info",
    bs4Card(
      title = "Input Controls",
      background = "info",
      width = 12,
      style = "max-width: 100%;",
      status = "primary",
      solidHeader = TRUE,
      collapsible = TRUE,
      br(),
      actionButton("loadPremiumButton", "Load Premium Data", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("loadClaimsButton", "Load Claims Data", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewExposureButton", "Calculate Exposure Results", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewClaimsButton", "View Gross Reported Claims", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewUniqueClaimsButton", "View Unique Claims Summary", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewClaimFrequenciesButton", "View Claim Frequencies", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewClaimSeveritiesButton", "Calculate Claim Severities", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewRiskPremiumButton", "Calculate Risk Premium", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("viewOfficePremiumButton", "Calculate Office Premium", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;"),
      br(),
      br(),
      actionButton("showPlot1", "Frequency vs Severity Plot", class = "btn btn-primary",
                   style = "background-color: #007bff; color: white; font-size: 12px;")
    )
  ),
  body = dashboardBody(
    tags$head(
      tags$link(href = "https://fonts.googleapis.com/css?family=Mulish", rel = "stylesheet"),
      tags$style(HTML("
        body {
          font-family: 'Mulish', sans-serif;
          background-color: #f4f4f4;
          }
        .shiny-output-error {
            color: #ff0000;
          }
        .shiny-output-error:before {
            content: 'Error: ';
          }
        .well {
            background-color: #ffffff;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          }
      "))
    ),
    bs4TabItems(
      bs4TabItem(tabName = "viewPremiumData",
                 fluidRow(
                   hr(),
                   div(
                     style = "background-color: #17a2b8; padding: 20px; border-radius: 10px; margin-bottom: 20px; color: white;",
                     fileInput("file1", 
                               label = tags$span("Upload Premium Data as a Excel File", style = "color: white;"),
                               accept = c(".xlsx", ".xls")
                     ),
                     tags$p(class = "instruction-header", style = "font-weight: bold; font-size: 16px; margin-top: 20px;", "Data Upload Guidelines:"),
                     tags$ul(
                       style = "font-size: 14px;",
                       tags$li("Ensure the data format is Excel The Required Columns are:"),
                       tags$ul(
                         style = "font-size: 12px;",
                         tags$li(tags$b("Period_From: -"), " The Policy Start Date"),
                         tags$li(tags$b("Period_Upto: -"), " The Policy End Date"),
                         tags$li(tags$b("PolicyNo: -"), " The Policy Number"),
                         tags$li(tags$b("Statutory_Class: -"), " The Statutory Class of Business"),
                         tags$li(tags$b("Gross_Premium: -"), " The Gross Premium Amount")
                       )
                     )
                   ),
                   hr(),
                   br(),
                   bs4Card(
                     title = "Premium Data Overview",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     DTOutput("viewPremiumData")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewClaimsData",
                 fluidRow(
                   hr(),
                   div(
                     style = "background-color: #17a2b8; padding: 20px; border-radius: 10px; margin-bottom: 20px; color: white;",
                     fileInput("file2", 
                               label = tags$span("Upload Claim Data as a Excel File", style = "color: white;"),
                               accept = c(".xlsx", ".xls")
                     ),
                     tags$p(class = "instruction-header", style = "font-weight: bold; font-size: 16px; margin-top: 20px;", "Data Upload Guidelines:"),
                     tags$ul(
                       style = "font-size: 14px;",
                       tags$li("Ensure the data format is Excel, The Required Columns are:"),
                       tags$ul(
                         style = "font-size: 12px;",
                         tags$li(tags$b("ClaimNo: -"), " The Unique Claim Number"),
                         tags$li(tags$b("Loss_Date: -"), " The Claim Loss Date"),
                         tags$li(tags$b("Statutory_Class: -"), " The Claim Statutory Class"),
                         tags$li(tags$b("Gross_Reported: -"), " The Claim Amount")
                       )
                     )
                   ),
                   hr(),
                   br(),
                   bs4Card(
                     title = "Claim Data Overview",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     DTOutput("viewClaimsData")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewExposureResults",
                 fluidRow(
                   bs4Card(
                     title = "Exposure Results",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadExposure", "Download Exposure Results", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     fluidRow(hr(),
                              numericInput("yearStart", "Select Exposure Start Year", value = 2017, min = 2000, max = 2100),
                              hr(),
                              numericInput("yearEnd", "Select Exposure End Year", value = 2023, min = 2000, max = 2100),hr()),
                     DTOutput("viewExposureResults")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewGrossReportedClaims",
                 fluidRow(
                   bs4Card(
                     title = "Gross Reported Claims",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadGrossClaims", "Download Gross Reported Claims", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     fluidRow(hr(),
                              numericInput("claimsStartYear", "Start Year for Gross Reported Claims", value = 2017, min = 1990, max = 2100),
                              hr(),
                              numericInput("claimsEndYear", "End Year for Gross Reported Claims", value = 2023, min = 1990, max = 2100),hr()),
                     DTOutput("viewGrossReportedClaims")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewUniqueClaimsSummary",
                 fluidRow(
                   bs4Card(
                     title = "Unique Claims Summary",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadUniqueClaims", "Download Unique Claims Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     fluidRow(hr(),
                              numericInput("uniqueclaimsStartYear", "Start Year for Unique Claims", value = 2017, min = 1990, max = 2100),
                              hr(),
                              numericInput("uniqueclaimsEndYear", "End Year for Unique Claims", value = 2023, min = 1990, max = 2100), hr()),
                     DTOutput("viewUniqueClaimsSummary")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewClaimFrequencies",
                 fluidRow(
                   bs4Card(
                     title = "Claim Frequencies",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadClaimFrequencies", "Download Claim Frequencies Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     DTOutput("viewClaimFrequencies")
                   )
                 ),
                 fluidRow(
                   bs4Card(
                     title = "Claim Frequencies Variance by Year",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadClaimFrequenciesvariance", "Download Claim Frequencies Variance Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     DTOutput("viewClaimFrequenciesvariance")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewClaimSeverities",
                 fluidRow(
                   bs4Card(
                     title = "Claim Severities",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadClaimSeverities", "Download Claim Severities Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     DTOutput("viewClaimSeverities")
                   )
                 ),
                 fluidRow(
                   bs4Card(
                     title = "Claim Severity Variance by Year",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadClaimSeveritiesVariance", "Download Claim Severities variance Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     DTOutput("viewSeverityChanges")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewRiskPremium",
                 fluidRow(
                   bs4Card(
                     title = "Risk Premium",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     downloadButton("downloadRiskPremium", "Download Risk Premium Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     DTOutput("viewRiskPremium")
                   )
                 )
      ),
      bs4TabItem(tabName = "viewOfficePremium",
                 fluidRow(
                   bs4Card(
                     title = "Office Premium",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     
                     downloadButton("downloadOfficePremium", "Download Office Premium Data", class = "btn btn-primary",
                                    style = "background-color: #007bff; color: white; font-size: 14px;"),
                     br(),
                     br(),
                     sliderInput("lossRatioInput", "Select Loss Ratio", min = 0.1, max = 1.0, value = 0.6, step = 0.1, pre = "%"),
                     br(),
                     DTOutput("viewOfficePremium")
                   )
                 )
      ),
      bs4TabItem(tabName = "plot1",
                 fluidRow(
                   bs4Card(
                     selectInput("yearInput", "Select Plot Year:", choices = character(0)),
                     br(),
                     title = "Frequency vs Severity Plot",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     uiOutput("plotUI1")
                   )
                 ),
                 fluidRow(
                   bs4Card(
                     selectInput("selectedYear", "Select Year:", choices = character(0)),
                     br(),
                     title = "Frequency vs Severity Table",
                     status = "primary",
                     solidHeader = TRUE,
                     width = 12,
                     DTOutput("yearlyChangesTable")
                   )
                 )
      )
    )
  )
)

# Define the server logic required to read the input and calculate outputs
server <- function(input, output, session) {
  
  observeEvent(input$toggleControlbar, {
    updateBoxSidebar("controlbar")
  })
  
  
  # Reactive value for storing the claims data
  processedPremiumData <- eventReactive(input$loadPremiumButton, {
    req(input$file1)
    inFile <- input$file1
    withProgress(message = 'Loading Premium Data...', {
      incProgress(0.1)  # initial progress
      data <- read_excel(inFile$datapath)%>%
        mutate(   
          `Period_From` = as.Date(`Period_From`, format = "%m/%d/%Y"),
          `Period_Upto` = as.Date(`Period_Upto`, format = "%m/%d/%Y"),
          Policy_ID = paste(PolicyNo, Period_From, Period_Upto))%>%
        group_by(Policy_ID) %>%
        mutate(
          Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
      incProgress(0.9, detail = "Almost done...")  # incremental progress
      data
    })
  })
  
  # Reactive value for storing the claims data
  processedClaimsData <- eventReactive(input$loadClaimsButton, {
    req(input$file2)
    inFile <- input$file2
    withProgress(message = 'Loading Claims Data...', {
      incProgress(0.1)  # initial progress
      data <- read_excel(inFile$datapath)%>%
        mutate(   
          Loss_Date = as.Date(Loss_Date, format = "%m/%d/%Y")) %>%
        mutate(
          Claim_ID = paste(ClaimNo, Loss_Date),
          Loss_year = year(Loss_Date)) %>%
        group_by(Claim_ID) %>%
        mutate(Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
      incProgress(0.9, detail = "Almost done...")  # incremental progress
      data
    })
  })
  
  # Display processed premium data
  output$viewPremiumData <- renderDT({
    req(processedPremiumData())
    datatable(processedPremiumData(), options = list(scrollX = TRUE, 
                                                     pageLength = 30,
                                                     autoWidth = FALSE,
                                                     paging = TRUE,
                                                     searching = FALSE,
                                                     info = FALSE,
                                                     initComplete = JS(
                                                       "function(settings, json) {",
                                                       "  $(this.api().table().header()).css({",
                                                       "    'background-color': '#007BFF',", 
                                                       "    'color': '#FFFFFF'",  
                                                       "  });",
                                                       "}"
                                                     )))
  })
  
  
  # Display processed claims data
  output$viewClaimsData <- renderDT({
    req(processedClaimsData())
    datatable(processedClaimsData(), options = list(scrollX = TRUE, 
                                                    pageLength = 30,
                                                    autoWidth = FALSE,
                                                    paging = TRUE,
                                                    searching = FALSE,
                                                    info = FALSE,
                                                    initComplete = JS(
                                                      "function(settings, json) {",
                                                      "  $(this.api().table().header()).css({",
                                                      "    'background-color': '#007BFF',", 
                                                      "    'color': '#FFFFFF'",  
                                                      "  });",
                                                      "}"
                                                    )))
  })
  
  # Calculate Exposure Results
  Exposure_Results <- eventReactive(input$viewExposureButton, {
    req(processedPremiumData())
    years <- seq(input$yearStart, input$yearEnd)
    # Initialize progress bar
    withProgress(message = 'Calculating Exposure Results...', value = 0, {
      setProgress(0.1)  # Start with an initial small progress
      beg_dates <- lapply(years, function(x) mdy(paste("01/01/", x, sep = "")))
      names(beg_dates) <- paste("Beg_", years, sep = "")
      end_dates <- lapply(years, function(x) mdy(paste("12/31/", x, sep = "")))
      names(end_dates) <- paste("End_", years, sep = "")
      data <- processedPremiumData()
      for (i in seq_along(years)) {
        year <- years[i]
        beg_key <- names(beg_dates)[i]
        end_key <- names(end_dates)[i]
        # Increment progress
        incProgress(1/length(years), detail = paste("Processing year:", year))
        data <- data %>%
          mutate(!!paste("Exposure", year, sep = "_") := 
                   (pmax(0, (pmin(end_dates[[end_key]], `Period_Upto`) - 
                               pmax(beg_dates[[beg_key]], `Period_From`) + 1))) / 365.25)}
      # Almost done, set progress to 90%
      setProgress(0.9, detail = "Finalizing calculations...")
      data %>%
        filter(Unique == 1) %>%
        group_by(Statutory_Class) %>%
        summarise(across(starts_with("Exposure_"), ~ sum(., na.rm = TRUE)))
    })
  })  
  
  
  # Display Exposure Results
  output$viewExposureResults <- renderDT({
    req(Exposure_Results())
    results <- Exposure_Results()
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        scales::comma(as.numeric(formatC(x, format = "f", digits = 0)))
      } else {
        x
      }
    })
    
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Exposure Results
  output$downloadExposure <- downloadHandler(
    filename = function() {
      paste("Exposure-Results-", Sys.Date(), ".csv", sep = "")
    },
    content = function(file) {
      req(Exposure_Results())
      results <- Exposure_Results()
      # Write the results to a CSV file
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  
  # Creating the Gross Reported Claims table
  Gross_Reported_Claims <- eventReactive(input$viewClaimsButton, {
    req(processedClaimsData())
    claims_data <- processedClaimsData()
    
    claims_data %>%
      filter(Loss_year >= input$claimsStartYear, Loss_year <= input$claimsEndYear)%>%
      group_by(Statutory_Class, Loss_year) %>%
      summarise(Gross_Reported_Sum = sum(Gross_Reported, na.rm = TRUE), .groups = 'drop') %>%
      pivot_wider(
        names_from = Loss_year,
        values_from = Gross_Reported_Sum,
        values_fill = list(Gross_Reported_Sum = 0)
      ) %>%
      select(Statutory_Class, sort(setdiff(names(.), "Statutory_Class")))
  })
  
  # Output for Gross Reported Claims
  output$viewGrossReportedClaims <- renderDT({
    req(Gross_Reported_Claims())
    results <- Gross_Reported_Claims()
    # Apply formatting to numeric columns with commas and two decimal points
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        scales::comma(x)
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Gross Reported Claims
  output$downloadGrossClaims <- downloadHandler(
    filename = function() {
      paste("gross-reported-claims-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Gross_Reported_Claims())
      write.csv(Gross_Reported_Claims(), file, row.names = FALSE)
    }
  )
  
  # Creating the Unique Claims Summary table
  Unique_Results <- eventReactive(input$viewUniqueClaimsButton, {
    req(processedClaimsData())
    claims_data <- processedClaimsData()
    
    claims_data %>%
      filter(Loss_year >= input$uniqueclaimsStartYear, Loss_year <= input$uniqueclaimsEndYear) %>%
      group_by(Statutory_Class, Loss_year) %>%
      summarise(Uniq_Sum = sum(Unique, na.rm = TRUE), .groups = 'drop') %>%
      pivot_wider(
        names_from = Loss_year,
        values_from = Uniq_Sum,
        values_fill = list(Uniq_Sum = 0)
      ) %>%
      select(Statutory_Class, sort(setdiff(names(.), "Statutory_Class")))
  })
  
  # Output for Unique Claims Summary
  output$viewUniqueClaimsSummary <- renderDT({
    req(Unique_Results())
    results <- Unique_Results()
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        scales::comma(x)
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  
  # Download handler for Unique Claims Summary
  output$downloadUniqueClaims <- downloadHandler(
    filename = function() {
      paste("unique-claims-summary-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Unique_Results())
      results <- Unique_Results()
      # Ensure results are formatted before writing to CSV
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          as.character(scales::comma(x, accuracy = 0.01))
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  # Reactive for Claim Frequencies
  Frequency_Results <- reactive({
    req(input$viewClaimFrequenciesButton)
    req(Unique_Results(), Exposure_Results())
    
    # Merge the Exposure_results and the Unique_Results data frames by 'Statutory_Class'
    Merged_Results_Exposure <- merge(Unique_Results(), Exposure_Results(), by = "Statutory_Class", all.x = TRUE)
    
    # Extract the years used in the Unique_Results 
    Unique_Results_Years <- setdiff(names(Unique_Results()), "Statutory_Class")
    
    # Initialize an empty data frame to store the division results
    Frequency_Results <- Merged_Results_Exposure %>% select(Statutory_Class)
    
    # Frequencies Results in Percentage
    # Loop through each year column to perform the division
    for (year in Unique_Results_Years) {
      exposure_col <- paste0("Exposure_", year)
      if (exposure_col %in% names(Merged_Results_Exposure)) {
        Frequency_Results[[paste0("Freq_", year)]] <- Merged_Results_Exposure[[year]] / Merged_Results_Exposure[[exposure_col]] * 100
      } else {
        Frequency_Results[[paste0("Freq_", year)]] <- NA
      }
    }
    Frequency_Results
  })
  
  # Output for Claim Frequencies
  output$viewClaimFrequencies <- renderDT({
    req(Frequency_Results())
    results <- Frequency_Results()
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        sprintf("%.0f%%", x)  # Formatting as percentage with two decimal places
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Claim Frequencies
  output$downloadClaimFrequencies <- downloadHandler(
    filename = function() {
      paste("claim-frequencies-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Frequency_Results())
      results <- Frequency_Results()
      # Convert numeric results to percentage format for the CSV
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          sprintf("%.2f%%", x)
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  
  
  # Calculate Year-Over-Year Percentage Change
  Percentage_Change_Results <- reactive({
    req(input$viewClaimFrequenciesButton)
    req(Frequency_Results())
    
    freq_data <- Frequency_Results()
    change_data <- freq_data
    
    # Extract the year columns only
    freq_columns <- grep("Freq_", names(freq_data), value = TRUE)
    
    # Loop through each frequency column except the first one to calculate percentage change
    for (i in 2:length(freq_columns)) {
      previous_year <- freq_columns[i - 1]
      current_year <- freq_columns[i]
      change_column_name <- sprintf("Change_%s_to_%s", sub("Freq_", "", previous_year), sub("Freq_", "", current_year))
      
      # Calculate percentage change and format it
      change_data[[change_column_name]] <- (freq_data[[current_year]] - freq_data[[previous_year]]) 
    }
    
    # Select only change columns and the Statutory_Class
    change_data <- change_data[c("Statutory_Class", grep("Change_", names(change_data), value = TRUE))]
    change_data
  })
  
  
  # Output for Percentage Change
  output$viewClaimFrequenciesvariance <- renderDT({
    req(Percentage_Change_Results())
    changes <- Percentage_Change_Results()
    
    # Formatting the data before it is passed to DataTables
    percentage_columns <- grep("Change_", names(changes), value = TRUE)
    changes[percentage_columns] <- lapply(changes[percentage_columns], function(x) {
      paste0(round(x, 0), "%")  # Round to no decimal places and add percentage sign
    })
    
    # Create a DataTable and apply conditional formatting
    DT <- datatable(changes, options = list(
      scrollX = TRUE,
      pageLength = 30,
      autoWidth = FALSE,
      initComplete = JS(
        "function(settings, json) {",
        "  $(this.api().table().header()).css({",
        "    'background-color': '#007BFF',", 
        "    'color': '#FFFFFF'",
        "  });",
        "}"
      )
    )) %>% 
      formatStyle(
        columns = percentage_columns,
        backgroundColor = 'white',  # Set a consistent background color for all cells
        color = JS(
          'function(value, type, row, meta) {',
          '  if (type === "display") {',  # Only format for display purposes
          '    var num = Number(value.replace(/[^-\\d]/g, ""));',  # Extract the number from the string
          '    return num > 0 ? "green" : num < 0 ? "red" : "black";',  # Conditional text coloring
          '  }',
          '  return "black";',  # Default text color for non-display types
          '}'
        ),
        fontWeight = 'bold'  # Bold font weight for better readability
      )
    
    DT  # Return the DataTable object
  })
  
  # Download handler for Claim Frequencies
  output$downloadClaimFrequenciesvariance <- downloadHandler(
    filename = function() {
      paste("claim-frequencies-Variance-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Percentage_Change_Results())
      results <- Percentage_Change_Results()
      # Convert numeric results to percentage format for the CSV
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          sprintf("%.2f%%", x)
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  
  # Calculate Claim Severities
  Severity_Results <- reactive({
    req(input$viewClaimSeveritiesButton) 
    req(Unique_Results(), Gross_Reported_Claims())
    
    Merged_Results_Gross_Reported_Claims <- merge(Unique_Results(), Gross_Reported_Claims(), by = "Statutory_Class", suffixes = c("_Uniq", "_Gross"))
    Gross_Reported_Claims_Years <- setdiff(names(Unique_Results()), "Statutory_Class")
    Severity_Results <- Merged_Results_Gross_Reported_Claims %>% select(Statutory_Class)
    
    for (year in Gross_Reported_Claims_Years) {
      uniq_col <- paste0(year, "_Uniq")
      gross_col <- paste0(year, "_Gross")
      if (gross_col %in% names(Merged_Results_Gross_Reported_Claims) && uniq_col %in% names(Merged_Results_Gross_Reported_Claims)) {
        Severity_Results[[paste0("Sev_", year)]] <- Merged_Results_Gross_Reported_Claims[[gross_col]] / Merged_Results_Gross_Reported_Claims[[uniq_col]]
      } else {
        Severity_Results[[paste0("Sev_", year)]] <- NA
      }
    }
    Severity_Results
  })
  
  output$viewClaimSeverities <- renderDT({
    req(Severity_Results())
    results <- Severity_Results()
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        scales::comma(x, accuracy = 1)
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Claim Severities
  output$downloadClaimSeverities <- downloadHandler(
    filename = function() {
      paste("claim-severities-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Severity_Results())
      results <- Severity_Results()
      # Convert numeric results to string with two decimal places for the CSV
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          as.character(scales::comma(x, accuracy = 0.1))
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  
  # Calculate Year-Over-Year Percentage Change for Severities
  Percentage_Change_Severity <- reactive({
    req(input$viewClaimSeveritiesButton) 
    req(Severity_Results())
    sev_data <- Severity_Results()
    
    # Initialize an empty data frame to store the results
    change_data <- data.frame(Statutory_Class = sev_data$Statutory_Class)
    
    # List of severity columns
    sev_columns <- grep("Sev_", names(sev_data), value = TRUE)
    
    # Calculate percentage change for each year
    for (i in 1:(length(sev_columns) - 1)) {
      previous_year_col <- sev_columns[i]
      current_year_col <- sev_columns[i + 1]
      change_column_name <- sprintf("Change_%s_to_%s", sub("Sev_", "", previous_year_col), sub("Sev_", "", current_year_col))
      
      # Compute percentage change
      change_data[[change_column_name]] <- (sev_data[[current_year_col]] - sev_data[[previous_year_col]]) / sev_data[[previous_year_col]] * 100
    }
    
    change_data
  })
  
  # Output for Percentage Change in Severity
  output$viewSeverityChanges <- renderDT({
    req(Percentage_Change_Severity())
    changes <- Percentage_Change_Severity()
    
    changes[] <- lapply(changes, function(x) {
      if(is.numeric(x)) {
        paste0(sprintf("%.1f", x), "%")  # Format as percentage with one decimal place
      } else {
        x
      }
    })
    
    datatable(changes, options = list(scrollX = TRUE,
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',",
                                        "    'color': '#FFFFFF'",
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Claim Severities
  output$downloadClaimSeveritiesVariance <- downloadHandler(
    filename = function() {
      paste("claim-severities-Variance-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Percentage_Change_Severity())
      results <- Percentage_Change_Severity()
      # Convert numeric results to string with two decimal places for the CSV
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          sprintf("%.2f%%", x)
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  # Define Unique_Results_Years as a reactive expression
  Unique_Results_Years <- reactive({
    req(Unique_Results())  # Ensure Unique_Results is ready
    years <- setdiff(names(Unique_Results()), "Statutory_Class")  # Assuming the structure includes Statutory_Class
    if (length(years) == 0) {
      showNotification("Unique_Results_Years() is empty", type = "error")
    }
    
    years
  })
  # Calculate Risk Premium
  Risk_Premium <- reactive({
    req(input$viewRiskPremiumButton)
    req(Frequency_Results(), Severity_Results(), Unique_Results_Years())
    Merged_Risk_Premium <- merge(Frequency_Results(), Severity_Results(), by = "Statutory_Class", all = TRUE)
    if (nrow(Merged_Risk_Premium) == 0) {
      showNotification("Merged_Risk_Premium is empty after merging Frequency_Results and Severity_Results", type = "error")
      return(data.frame())  # Return an empty data frame to prevent further errors
    }
    Risk_Premium <- Merged_Risk_Premium %>% select(Statutory_Class)
    for (year in Unique_Results_Years()) {
      freq_col <- paste0("Freq_", year)
      sev_col <- paste0("Sev_", year)
      if (freq_col %in% names(Merged_Risk_Premium) && sev_col %in% names(Merged_Risk_Premium)) {
        Risk_Premium[[paste0("Risk_Premium_", year)]] <- Merged_Risk_Premium[[freq_col]] * Merged_Risk_Premium[[sev_col]] / 100
      } else {
        Risk_Premium[[paste0("Risk_Premium_", year)]] <- NA
      }
    }
    Risk_Premium
  })
  
  output$viewRiskPremium <- renderDT({
    req(Risk_Premium())
    results <- Risk_Premium()
    
    if (nrow(results) == 0) {
      showNotification("Risk_Premium results are empty", type = "error")
      return(data.frame())  # Return an empty data frame to prevent rendering issues
    }
    
    results[] <- lapply(results, function(x) {
      if(is.numeric(x)) {
        scales::comma(x, accuracy = 1)
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  
  # Download handler for Risk Premium
  output$downloadRiskPremium <- downloadHandler(
    filename = function() {
      paste("risk-premium-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Risk_Premium())
      results <- Risk_Premium()
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          as.character(scales::comma(x))
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  # Calculate Office Premiums
  Office_Premium <- eventReactive(input$viewOfficePremiumButton, {
    req(Risk_Premium())  # Ensure Risk_Premium is ready
    
    Loss_Ratio <- input$lossRatioInput  # Use dynamic input from UI
    
    # Use user input to define the year range
    years <- seq(input$yearStart, input$yearEnd)
    
    Office_Premium <- Risk_Premium() %>% select(Statutory_Class)
    
    
    for (year in years) {
      risk_premium_col <- paste0("Risk_Premium_", year)
      if (risk_premium_col %in% names(Risk_Premium())) {
        Office_Premium[[paste0("Office_Premium_", year)]] <- Risk_Premium()[[risk_premium_col]] / Loss_Ratio
      } else {
        Office_Premium[[paste0("Office_Premium_", year)]] <- NA
      }
    }
    Office_Premium
  })
  
  output$viewOfficePremium <- renderDT({
    req(Office_Premium())
    results <- Office_Premium()
    results[] <- lapply(results, function(x) {
      if (is.numeric(x)) {
        scales::comma(x, accuracy = 1)
      } else {
        x
      }
    })
    datatable(results, options = list(scrollX = TRUE, 
                                      pageLength = 30,
                                      autoWidth = FALSE,
                                      paging = TRUE,
                                      searching = FALSE,
                                      info = FALSE,
                                      initComplete = JS(
                                        "function(settings, json) {",
                                        "  $(this.api().table().header()).css({",
                                        "    'background-color': '#007BFF',", 
                                        "    'color': '#FFFFFF'",  
                                        "  });",
                                        "}"
                                      )))
  })
  
  # Download handler for Office Premium
  output$downloadOfficePremium <- downloadHandler(
    filename = function() {
      paste("office-premium-", Sys.Date(), ".csv", sep="")
    },
    content = function(file) {
      req(Office_Premium())
      results <- Office_Premium()
      results[] <- lapply(results, function(x) {
        if (is.numeric(x)) {
          as.character(scales::comma(x, accuracy = 0.01))
        } else {
          x
        }
      })
      write.csv(results, file, row.names = FALSE)
    }
  )
  
  Merged_Risk_Premium <- reactive({
    merged_data <- merge(Frequency_Results(), Severity_Results(), by = "Statutory_Class", all = TRUE)
    
    if (nrow(merged_data) == 0) {
      showNotification("Merged_Risk_Premium is empty", type = "error")
      return(data.frame())  # Return an empty data frame to prevent further errors
    }
    
    merged_data
  })
  
  data_long <- reactive({
    req(Merged_Risk_Premium())
    Merged_Risk_Premium() %>%
      pivot_longer(
        cols = matches("Freq_|Sev_"),
        names_to = c(".value", "year"),
        names_pattern = "(Freq_|Sev_)(\\d+)"
      )%>%
      filter(!is.na(year)) 
  })
  
  observe({
    updateSelectInput(session, "yearInput", choices = unique(data_long()$year))
  })
  
  # Render plot based on user input
  output$yearPlot1 <- renderPlotly({
    req(input$yearInput)  # Ensure that the input is not NULL
    year_data <- data_long() %>% filter(year == input$yearInput)
    
    p <- ggplot(year_data, aes(x = Sev_, y = Freq_)) +
      geom_point(aes(color = Statutory_Class), size = 4, alpha = 0.8) +
      geom_label_repel(aes(label = Statutory_Class), size = 3, box.padding = unit(0.35, "lines"),
                       point.padding = unit(0.5, "lines"),
                       label.padding = unit(0.2, "lines")) +
      scale_color_viridis_d(option = "D") +
      labs(
        title = paste("Scatter Plot of Severity vs Frequency for the year", input$yearInput),
        x = "Severity",
        y = "Frequency"
      ) +
      theme_minimal() +
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5, size = 20),  # Center and increase font size of title
            panel.grid.major = element_blank(),  # Remove major grid lines
            panel.grid.minor = element_blank())
    
    ggplotly(p)  # Convert ggplot object to plotly interactive plot
  })
  
  # Conditional UI to display or hide the plot
  output$plotUI1 <- renderUI({
    if (input$showPlot1 %% 2 == 1) { # Show plot if button is pressed an odd number of times
      plotlyOutput("yearPlot1", height = "550px")
    }
  })
  data_long <- reactive({
    req(Merged_Risk_Premium())
    Merged_Risk_Premium() %>%
      pivot_longer(
        cols = matches("Freq_|Sev_"),
        names_to = c(".value", "year"),
        names_pattern = "(Freq_|Sev_)(\\d+)"
      )%>%
      filter(!is.na(year)) 
  })
  
  # Prepare data for the table showing yearly changes with percentage calculations
  yearly_changes <- reactive({
    req(data_long())
    data_long() %>%
      group_by(year, Statutory_Class) %>%
      summarise(
        Average_Severity = mean(Sev_, na.rm = TRUE),
        Average_Frequency = mean(Freq_, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      arrange(Statutory_Class, year) %>%
      group_by(Statutory_Class) %>%
      mutate(
        Freq_Percent_Change = (Average_Frequency / lag(Average_Frequency) - 1) * 100,
        Sev_Percent_Change = (Average_Severity / lag(Average_Severity) - 1) * 100
      ) %>%
      ungroup()
  })
  
  observe({
    updateSelectInput(session, "selectedYear", choices = unique(yearly_changes()$year))
  })
  
  filtered_data <- reactive({
    yearly_changes() %>%
      filter(year == input$selectedYear) %>%
      mutate(Average_Severity = formatC(Average_Severity, format = "f", big.mark = ",", digits = 0),
             Average_Frequency = format(Average_Frequency, big.mark = ",", digits = 1, nsmall = 1),
             Freq_Percent_Change = format(Freq_Percent_Change, big.mark = ",", digits = 1, nsmall = 1),
             Sev_Percent_Change = format(Sev_Percent_Change, big.mark = ",", digits = 1, nsmall = 1))
  })
  
  output$yearlyChangesTable <- renderDT({
    datatable(filtered_data()[, c("Statutory_Class", "Average_Severity", "Average_Frequency", 
                                  "Freq_Percent_Change", "Sev_Percent_Change")], 
              options = list(pageLength = 20, autoWidth = TRUE), 
              rownames = FALSE, escape = FALSE) %>%
      formatStyle(
        'Freq_Percent_Change',
        valueColumns = 'Freq_Percent_Change',
        target = 'cell',
        field = 'Freq_Percent_Change',
        color = styleInterval(0, c("red", "blue")),
        backgroundColor = styleInterval(0, c("pink", "lightblue")),
        fontWeight = 'bold',
        fontSize = styleInterval(0, c("100%", "100%")),
        content = JS(
          "function(data, type, row, meta){
          if (type === 'display'){
            var icon = data > 0 ? '&#9650;' : '&#9660;';
            var color = data > 0 ? 'blue' : 'red';
            return '<span style=\"color:' + color + ';\">' + data.toFixed(2) + '% ' + icon + '</span>';
          }
          return data.toFixed(2) + '%';
        }"
        )
      ) %>%
      formatStyle(
        'Sev_Percent_Change',
        valueColumns = 'Sev_Percent_Change',
        target = 'cell',
        field = 'Sev_Percent_Change',
        color = styleInterval(0, c("red", "blue")),
        backgroundColor = styleInterval(0, c("pink", "lightblue")),
        fontWeight = 'bold',
        fontSize = styleInterval(0, c("100%", "100%")),
        content = JS(
          "function(data, type, row, meta){
          if (type === 'display'){
            var icon = data > 0 ? '&#9650;' : '&#9660;';
            var color = data > 0 ? 'blue' : 'red';
            return '<span style=\"color:' + color + ';\">' + data.toFixed(2) + '% ' + icon + '</span>';
          }
          return data.toFixed(2) + '%';
        }"
        )
      )
  })
  
}

# Run the application
shinyApp(ui = ui, server = server)
          