uniqueClaimsResultsUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
      title = "Unique Claims Results",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      fluidRow(
          hr(),
          hr(),
      downloadButton(ns("downloadUniqueClaims"), "Download Unique Claims Results", class = "btn btn-primary btn-primary-custom")),
      br(),
      br(),
      fluidRow(
        hr(),
        numericInput(ns("uniqueclaimsStartYear"), "Select Start Year", value = 2017, min = 1990, max = 2100),
        hr(),
        numericInput(ns("uniqueclaimsEndYear"), "Select End Year", value = 2023, min = 1990, max = 2100),hr()
      ),
      br(),
      fluidRow(
            hr(),
            actionButton(ns("viewUniqueClaimsButton"), "Calculate Unique Claims Summary", class = "btn btn-primary btn-primary-custom"),
            hr()),
      DTOutput(ns("viewUniqueClaimsSummary"))
    )
  )
}


uniqueClaimsResultsServer <- function(id, processedClaimsData) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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
      data <- tryCatch(Unique_Results(), error = function(e) NULL)
      if (is.null(data)) {
        showNotification("Please calculate Unique Claims first before downloading.", type = "warning")
        return(NULL)
      }
      write.csv(data, file, row.names = FALSE)
    }
  )

    return(reactive({ Unique_Results() }))

  })
}
