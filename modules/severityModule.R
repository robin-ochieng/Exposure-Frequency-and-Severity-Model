severityUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
      title = "Claim Severities",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      fluidRow(hr(),hr(), 
      downloadButton(ns("downloadClaimSeverities"), "Download Claim Severities Data", class = "btn btn-primary btn-primary-custom")),
      br(),
      br(),
      fluidRow(
        hr(),
        actionButton(ns("viewClaimSeveritiesButton"), "Calculate Claim Severities", class = "btn btn-primary btn-primary-custom"),
        hr()),   
      DTOutput(ns("viewClaimSeverities"))
     )
  )
}

severityServer <- function(id, Unique_Results, Gross_Reported_Claims) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
  
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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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

     return(reactive({ Severity_Results() }))
 
  })
}

