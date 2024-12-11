claimsFrequencyVarianceUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
        title = "Claim Frequencies Variance by Year",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        fluidRow(hr(),hr(), 
        downloadButton(ns("downloadClaimFrequenciesvariance"), "Download Claim Frequencies Variance Data", class = "btn btn-primary btn-primary-custom")),
        br(),
        br(),
        fluidRow(
            hr(),
            actionButton(ns("viewClaimFrequenciesButton"), "View Claim Frequencies Variance", class = "btn btn-primary btn-primary-custom"),
            hr()), 
        DTOutput(ns("viewClaimFrequenciesvariance"))
    )
  )
}

claimsFrequencyVarianceServer <- function(id, Frequency_Results) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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
        "    'background-color': '#FFFFFF',", 
        "    'color': '#000000'",
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


  

  })
}
