claimsFrequencyUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
        title = "Claim Frequencies",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        fluidRow(hr(),hr(), 
        downloadButton(ns("downloadClaimFrequencies"), "Download Claim Frequencies Data", class = "btn btn-primary btn-primary-custom")),
        br(),
        br(),
      fluidRow(
            hr(),
            actionButton(ns("viewClaimFrequenciesButton"), "Calculate Claim Frequencies", class = "btn btn-primary btn-primary-custom"),
            hr()),        
        DTOutput(ns("viewClaimFrequencies"))
    )
  )
}

claimsFrequencyServer <- function(id, Unique_Results, Exposure_Results) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  
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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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
      data <- tryCatch(Frequency_Results(), error = function(e) NULL)
      if (is.null(data)) {
        showNotification("Please calculate Claim Frequencies first before downloading.", type = "warning")
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

  return(reactive({ Frequency_Results() }))
 
  })
}

