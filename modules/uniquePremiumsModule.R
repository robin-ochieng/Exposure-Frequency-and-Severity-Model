# Module UI Function
uniquePremiumsResultsUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
      title = "Unique Premiums Results",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      fluidRow(
        hr(),
        hr(),
        downloadButton(ns("downloadUniquePremiums"), "Download Unique Premiums Results", class = "btn btn-primary btn-primary-custom")
      ),
      br(),
      br(),
      fluidRow(
        hr(),
        column(6,
          numericInput(ns("valuationYear"), "Select Valuation Year", value = 2023, min = 1990, max = 2100)
        ),
        column(6,
          selectInput(ns("valuationQuarter"), "Select Valuation Quarter", 
                      choices = c("Q1" = 1, "Q2" = 2, "Q3" = 3, "Q4" = 4),
                      selected = 4)
        ),
        hr()
      ),
      br(),
      fluidRow(
        hr(),
        column(6,
          numericInput(ns("premiumStartYear"), "Select Premium Start Year", value = 2017, min = 1990, max = 2100)
        ),
        column(6,
          numericInput(ns("premiumEndYear"), "Select Premium End Year", value = 2023, min = 1990, max = 2100)
        ),
        hr()
      ),
      br(),
      fluidRow(
        hr(),
        actionButton(ns("viewUniquePremiumsButton"), "Calculate Unique Premiums Summary", class = "btn btn-primary btn-primary-custom"),
        hr()
      ),
      DTOutput(ns("viewUniquePremiumsSummary"))
    )
  )
}


# Module Server Function
uniquePremiumsResultsServer <- function(id, processedPremiumData) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    # Calculate valuation date based on year and quarter
    valuationDate <- reactive({
      year <- input$valuationYear
      quarter <- as.numeric(input$valuationQuarter)
      end_month <- quarter * 3  # Q1=3, Q2=6, Q3=9, Q4=12
      
      # Get the last day of the quarter
      if (end_month %in% c(1, 3, 5, 7, 8, 10, 12)) {
        end_day <- 31
      } else if (end_month == 2) {
        # Check for leap year
        end_day <- ifelse(((year %% 4 == 0) & (year %% 100 != 0)) | (year %% 400 == 0), 29, 28)
      } else {
        end_day <- 30
      }
      
      lubridate::mdy(paste(end_month, "/", end_day, "/", year, sep = ""))
    })
    
    # Creating the Unique Premiums Summary table
    Unique_Premium_Results <- eventReactive(input$viewUniquePremiumsButton, {
      req(processedPremiumData())
      premium_data <- processedPremiumData()
      val_date <- valuationDate()
      
      # Filter policies in-force as at valuation date and extract inception year
      premium_data %>%
        filter(Unique == 1) %>%
        mutate(Inception_Year = lubridate::year(Period_From)) %>%
        filter(Inception_Year >= input$premiumStartYear, 
               Inception_Year <= input$premiumEndYear) %>%
        filter(Period_From <= val_date, Period_Upto >= val_date) %>%
        group_by(Statutory_Class, Inception_Year) %>%
        summarise(Unique_Count = n(), .groups = 'drop') %>%
        pivot_wider(
          names_from = Inception_Year,
          values_from = Unique_Count,
          values_fill = list(Unique_Count = 0)
        ) %>%
        select(Statutory_Class, sort(setdiff(names(.), "Statutory_Class")))
    })
    
    # Output for Unique Premiums Summary
    output$viewUniquePremiumsSummary <- renderDT({
      req(Unique_Premium_Results())
      results <- Unique_Premium_Results()
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
    
    # Download handler for Unique Premiums Summary
    output$downloadUniquePremiums <- downloadHandler(
      filename = function() {
        paste("unique-premiums-summary-", Sys.Date(), ".csv", sep="")
      },
      content = function(file) {
        data <- tryCatch(Unique_Premium_Results(), error = function(e) NULL)
        if (is.null(data)) {
          showNotification("Please calculate Unique Premiums first before downloading.", type = "warning")
          return(NULL)
        }
        write.csv(data, file, row.names = FALSE)
      }
    )
    
    return(reactive({ Unique_Premium_Results() }))
  })
}
