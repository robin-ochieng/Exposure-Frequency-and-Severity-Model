 # Module UI Function
activePoliciesUI <- function(id) {
  ns <- NS(id)
  tagList(
    bs4Card(
      title = "Active Policies as at Valuation Date",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      fluidRow(
        hr(),
        hr(),
        column(6,
          downloadButton(ns("downloadActivePoliciesSummary"), "Download Summary", class = "btn btn-primary btn-primary-custom")
        ),
        column(6,
          downloadButton(ns("downloadActivePoliciesDetail"), "Download Detailed List", class = "btn btn-primary btn-primary-custom")
        )
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
        actionButton(ns("viewActivePoliciesButton"), "Calculate Active Policies", class = "btn btn-primary btn-primary-custom"),
        hr()
      ),
      br(),
      fluidRow(
        column(12,
          tags$h5("Summary: Active Policy Count by Statutory Class"),
          DTOutput(ns("viewActivePoliciesSummary"))
        )
      ),
      br(),
      hr(),
      fluidRow(
        column(12,
          tags$h5("Detailed View: In-Force Policies"),
          DTOutput(ns("viewActivePoliciesDetail"))
        )
      )
    )
  )
}


# Module Server Function
activePoliciesServer <- function(id, processedPremiumData) {
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
    
    # Filter active policies as at valuation date
    Active_Policies <- eventReactive(input$viewActivePoliciesButton, {
      req(processedPremiumData())
      premium_data <- processedPremiumData()
      val_date <- valuationDate()
      
      # Filter policies in-force as at valuation date (unique policies only)
      premium_data %>%
        filter(Unique == 1) %>%
        filter(Period_From <= val_date, Period_Upto >= val_date)
    })
    
    # Summary: Count by Statutory Class
    Active_Policies_Summary <- reactive({
      req(Active_Policies())
      Active_Policies() %>%
        group_by(Statutory_Class) %>%
        summarise(
          Active_Policy_Count = n(),
          Total_Gross_Premium = sum(Gross_Premium, na.rm = TRUE),
          .groups = 'drop'
        ) %>%
        arrange(desc(Active_Policy_Count))
    })
    
    # Output for Summary Table
    output$viewActivePoliciesSummary <- renderDT({
      req(Active_Policies_Summary())
      results <- Active_Policies_Summary()
      results[] <- lapply(results, function(x) {
        if(is.numeric(x)) {
          scales::comma(x)
        } else {
          x
        }
      })
      datatable(results, 
                options = list(scrollX = TRUE, 
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
                               )),
                caption = htmltools::tags$caption(
                  style = 'caption-side: top; text-align: left; font-weight: bold;',
                  paste("Valuation Date:", format(valuationDate(), "%d %B %Y"))
                ))
    })
    
    # Output for Detailed Table
    output$viewActivePoliciesDetail <- renderDT({
      req(Active_Policies())
      results <- Active_Policies() %>%
        select(PolicyNo, Statutory_Class, Period_From, Period_Upto, Gross_Premium) %>%
        mutate(
          Period_From = format(Period_From, "%d-%b-%Y"),
          Period_Upto = format(Period_Upto, "%d-%b-%Y")
        )
      
      results$Gross_Premium <- scales::comma(results$Gross_Premium)
      
      datatable(results, 
                options = list(scrollX = TRUE, 
                               pageLength = 15,
                               autoWidth = FALSE,
                               paging = TRUE,
                               searching = TRUE,
                               info = TRUE,
                               initComplete = JS(
                                 "function(settings, json) {",
                                 "  $(this.api().table().header()).css({",
                                 "    'background-color': '#FFFFFF',", 
                                 "    'color': '#000000'",  
                                 "  });",
                                 "}"
                               )),
                caption = htmltools::tags$caption(
                  style = 'caption-side: top; text-align: left; font-weight: bold;',
                  paste("Total Active Policies:", scales::comma(nrow(Active_Policies())))
                ))
    })
    
    # Download handler for Summary
    output$downloadActivePoliciesSummary <- downloadHandler(
      filename = function() {
        paste("active-policies-summary-", format(valuationDate(), "%Y-%m-%d"), ".csv", sep="")
      },
      content = function(file) {
        data <- tryCatch(Active_Policies_Summary(), error = function(e) NULL)
        if (is.null(data)) {
          showNotification("Please calculate Active Policies first before downloading.", type = "warning")
          return(NULL)
        }
        write.csv(data, file, row.names = FALSE)
      }
    )
    
    # Download handler for Detail
    output$downloadActivePoliciesDetail <- downloadHandler(
      filename = function() {
        paste("active-policies-detail-", format(valuationDate(), "%Y-%m-%d"), ".csv", sep="")
      },
      content = function(file) {
        data <- tryCatch(Active_Policies(), error = function(e) NULL)
        if (is.null(data)) {
          showNotification("Please calculate Active Policies first before downloading.", type = "warning")
          return(NULL)
        }
        results <- data %>%
          select(PolicyNo, Statutory_Class, Period_From, Period_Upto, Gross_Premium) %>%
          mutate(
            Period_From = format(Period_From, "%d-%b-%Y"),
            Period_Upto = format(Period_Upto, "%d-%b-%Y")
          )
        write.csv(results, file, row.names = FALSE)
      }
    )
    
    return(reactive({ Active_Policies() }))
  })
}
