claimsDataInputUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
     hr(),
     div(
      column(12,
      br(),
      br(),
      class = "upload-container",
      fileInput(ns("file2"),
      label = tags$span("Upload Claims Data as an Excel or CSV File", class = "upload-label"), 
      accept = c(".xlsx", ".xls", ".csv"))
      )
     ),
      hr(),
      br(),
      div(
        class = "upload-container",
        tags$p(class = "instruction-header", "How to Prepare Data before Upload:"),
        tags$ul(
          class = "list-item",
          tags$li(class = "custom-list-item", "Ensure the data format is Excel or CSV."),
          tags$li(class = "custom-list-item", "The Required Columns are:-"),
          tags$ul(
            class = "sub-list-item",
            tags$li(class = "custom-list-item", icon("file-alt"), " ", tags$b("ClaimNo: -"), " The Unique Claim Number"),
            tags$li(class = "custom-list-item", icon("calendar-day"), " ", tags$b("Loss_Date: -"), " The Claim Loss Date"),
            tags$li(class = "custom-list-item", icon("sitemap"), " ", tags$b("Statutory_Class: -"), " The Claim Statutory Class"),
            tags$li(class = "custom-list-item", icon("dollar-sign"), " ", tags$b("Gross_Reported: -"), " The Claim Amount")
          )
        )
      ),
      hr(),
      bs4Card(
        title = "Claim Data Overview",
        status = "white",
        solidHeader = TRUE,
        width = 12,
        DTOutput(ns("viewClaimsData"))  # Include DTOutput within the card
      )
    )
  )
}

claimsDataInput <- function(input, output, session) {
  ns <- session$ns
  
processedClaimsData <- eventReactive(input$file2, {
  req(input$file2)
  inFile <- input$file2

  withProgress(message = 'Loading Claims Data...', {
    incProgress(0.1)  # Initial progress

    # Check the file extension
    file_ext <- tools::file_ext(inFile$name)

    if (file_ext %in% c("xlsx", "xls")) {
      # Process Excel file
      data <- read_excel(inFile$datapath) %>%
        mutate(
          Loss_Date = lubridate::parse_date_time(Loss_Date, orders = c("dmy", "ymd", "mdy")),
          Claim_ID = paste(ClaimNo, Loss_Date),
          Loss_year = year(Loss_Date),
          Gross_Reported = as.numeric(Gross_Reported)
        ) %>%
        group_by(Claim_ID) %>%
        mutate(Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
    } else if (file_ext == "csv") {
      # Process CSV file
      data <- read_csv(inFile$datapath) %>%
        mutate(
          Loss_Date = lubridate::parse_date_time(Loss_Date, orders = c("dmy", "ymd", "mdy")),
          Claim_ID = paste(ClaimNo, Loss_Date),
          Loss_year = year(Loss_Date),
          Gross_Reported = as.numeric(Gross_Reported)
        ) %>%
        group_by(Claim_ID) %>%
        mutate(Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
    } else {
      stop("Unsupported file format. Please upload an Excel or CSV file.")
    }

    incProgress(0.9, detail = "Almost done...")  # Incremental progress
    data
  })
})
  
  # Display processed claims data
  output$viewClaimsData <- renderDT({
    req(processedClaimsData())
    datatable(processedClaimsData(), options = list(scrollX = TRUE, 
                                                    pageLength = 15,
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

  return(reactive({ processedClaimsData() }))
}

