officePremiumUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
        title = "Office Premium",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        fluidRow(hr(),hr(), 
        downloadButton(ns("downloadOfficePremium"), "Download Office Premium Data", class = "btn btn-primary btn-primary-custom")),
        br(),
        br(),
        sliderInput(ns("lossRatioInput"), "Select Loss Ratio", min = 0.1, max = 1.0, value = 0.6, step = 0.1, pre = "%"), 
        fluidRow(
            hr(),
            actionButton(ns("viewOfficePremiumButton"), "Calculate Office Premium", class = "btn btn-primary btn-primary-custom"),
            hr()),                 
        DTOutput(ns("viewOfficePremium"))
    )
  )
}


officePremiumServer <- function(id, Risk_Premium, yearStart, yearEnd) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

  # Calculate Office Premiums
  Office_Premium <- eventReactive(input$viewOfficePremiumButton, {
    req(Risk_Premium(), yearStart(), yearEnd())  
    Loss_Ratio <- input$lossRatioInput  # Use dynamic input from UI
    
    # Use user input to define the year range
    years <- seq(yearStart(), yearEnd()) 
    
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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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


     return(reactive({ Office_Premium() }))
  })
}

