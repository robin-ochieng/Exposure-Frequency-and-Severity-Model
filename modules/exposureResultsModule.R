# Module UI Function
exposureResultsUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      bs4Card(
        title = "Exposure Results",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        fluidRow(hr(), hr(),
          downloadButton(ns("downloadExposure"), "Download Exposure Results", class = "btn btn-primary btn-primary-custom"),
        ),
        br(),
        br(),
        fluidRow(hr(),
                 column(6,
                   numericInput(ns("yearStart"), "Select Exposure Start Year", value = 2017, min = 2000, max = 2100)
                 ),
                 hr()),
        fluidRow(hr(),
                 column(6,
                   numericInput(ns("yearEnd"), "Select Exposure End Year", value = 2023, min = 2000, max = 2100)
                 ),
                 column(6,
                   selectInput(ns("quarterEnd"), "Select Exposure End Quarter", 
                             choices = c("Q1" = 1, "Q2" = 2, "Q3" = 3, "Q4" = 4),
                             selected = 4)
                 ),
                 hr()),
        br(),
        fluidRow(
            hr(),
            actionButton(ns("viewExposureButton"), "Calculate Exposure Results", class = "btn btn-primary btn-primary-custom"),
            hr()),
        DTOutput(ns("viewExposureResults"))
      )
    )
  )
}

# Module Server Function
exposureResultsServer <- function(id, processedPremiumData) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

  # Calculate Exposure Results
  Exposure_Results <- eventReactive(input$viewExposureButton, {
    req(processedPremiumData())
    years <- seq(input$yearStart, input$yearEnd)
    # Initialize progress bar
    withProgress(message = 'Calculating Exposure Results...', value = 0, {
      setProgress(0.1)  # Start with an initial small progress
      beg_dates <- lapply(years, function(x) mdy(paste("01/01/", x, sep = "")))
      names(beg_dates) <- paste("Beg_", years, sep = "")
      
      # Adjust end dates based on selected quarter for the final year
      end_dates <- lapply(seq_along(years), function(i) {
        year <- years[i]
        # For the last year, use the selected quarter
        if (year == input$yearEnd) {
          quarter <- as.numeric(input$quarterEnd)
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
          mdy(paste(end_month, "/", end_day, "/", year, sep = ""))
        } else {
          mdy(paste("12/31/", year, sep = ""))
        }
      })
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
                                        "    'background-color': '#FFFFFF',", 
                                        "    'color': '#000000'",  
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

    # Inside exposureResultsServer, at the very end:
    return(list(
      Exposure_Results = reactive({ Exposure_Results() }),
      yearStart = reactive({ input$yearStart }),
      yearEnd = reactive({ input$yearEnd }),
      quarterEnd = reactive({ input$quarterEnd })
    ))

  })

}

