severityVarianceUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
       title = "Claim Severity Variance by Year",
       status = "white",
       solidHeader = TRUE,
       width = 12,
       fluidRow(hr(),hr(), 
       downloadButton(ns("downloadClaimSeveritiesVariance"), "Download Claim Severities variance Data", class = "btn btn-primary btn-primary-custom")),
       br(),
       br(),
      fluidRow(
        hr(),
        actionButton(ns("viewClaimSeveritiesButton"), "Calculate Claim Severities Variances", class = "btn btn-primary btn-primary-custom"),
        hr()),   
       DTOutput(ns("viewSeverityChanges"))
        )
  )
}

severityVarianceServer <- function(id, Severity_Results) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  
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
                                        "    'background-color': '#FFFFFF',",
                                        "    'color': '#000000'",
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
      data <- tryCatch(Percentage_Change_Severity(), error = function(e) NULL)
      if (is.null(data)) {
        showNotification("Please calculate Severity Variance first before downloading.", type = "warning")
        return(NULL)
      }
      results <- data
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
 
 
  })
}

