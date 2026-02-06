grossReportedClaimsUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
      title = "Gross Reported Claims",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      fluidRow(hr(),hr(),   
      downloadButton(ns("downloadGrossClaims"), "Download Gross Reported Claims", class = "btn btn-primary btn-primary-custom")),
      br(),
      br(),
      fluidRow(hr(),
               numericInput(ns("claimsStartYear"), "Start Year for Gross Reported Claims", value = 2017, min = 1990, max = 2100),
               hr(),
               numericInput(ns("claimsEndYear"), "End Year for Gross Reported Claims", value = 2023, min = 1990, max = 2100),hr()),
      br(),
      fluidRow(
            hr(),
            actionButton(ns("viewClaimsButton"), "Calculate Gross Reported Claims", class = "btn btn-primary btn-primary-custom"),
            hr()),
      DTOutput(ns("viewGrossReportedClaims"))
    )
  )
}

grossReportedClaimsServer <- function(id, processedClaimsData) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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
      data <- tryCatch(Gross_Reported_Claims(), error = function(e) NULL)
      if (is.null(data)) {
        showNotification("Please calculate Gross Reported Claims first before downloading.", type = "warning")
        return(NULL)
      }
      write.csv(data, file, row.names = FALSE)
    }
  )

    return(reactive({ Gross_Reported_Claims() }))  
  })
}




