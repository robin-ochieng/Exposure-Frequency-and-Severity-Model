riskPremiumUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
        title = "Risk Premium",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        fluidRow(hr(),hr(), 
        downloadButton(ns("downloadRiskPremium"), "Download Risk Premium Data", class = "btn btn-primary btn-primary-custom")),
        br(),
        br(),
        fluidRow(
            hr(),
            actionButton(ns("viewRiskPremiumButton"), "Calculate Risk Premium", class = "btn btn-primary btn-primary-custom"),
            hr()),                 
        DTOutput(ns("viewRiskPremium"))
    )
  )
}

riskPremiumServer <- function(id, Unique_Results, Frequency_Results, Severity_Results) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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



     return(reactive({ Risk_Premium() }))
  })
}

