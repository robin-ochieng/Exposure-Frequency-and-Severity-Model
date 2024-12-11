premiumDataInputUI <- function(id) {
  ns <- NS(id)
  tagList(
  fluidRow(
   hr(),
   div(
     column(12,
      br(),
      br(),
     class = "upload-container",
     fileInput(ns("file1"), label = tags$span("Upload Premium Data as an Excel  or CSV File", class = "upload-label"),  accept = c(".xlsx", ".xls", ".csv"))
     )
    ),
    hr(),
    br(),
    div(
      class = "upload-container",
      tags$p(class = "instruction-header", "How to Prepare Data before Upload:"),
      tags$ul(
      class = "list-item",
      tags$li(class = "custom-list-item", "Ensure the data format is Excel."),
      tags$li(class = "custom-list-item", "The Required Columns are:-"),
      tags$ul(
      class = "sub-list-item",
      tags$li(class = "custom-list-item", icon("calendar-day"), " ", tags$b("Period_From: -"), " The Policy Start Date"),
      tags$li(class = "custom-list-item", icon("calendar-day"), " ", tags$b("Period_Upto: -"), " The Policy End Date"),
      tags$li(class = "custom-list-item", icon("file-alt"), " ", tags$b("PolicyNo: -"), " The Policy Number"),
      tags$li(class = "custom-list-item", icon("sitemap"), " ", tags$b("Statutory_Class: -"), " The Statutory Class of Business"),
      tags$li(class = "custom-list-item", icon("dollar-sign"), " ", tags$b("Gross_Premium: -"), " The Gross Premium Amount")

     )
    )
   ),
   hr(),
   bs4Card(
      title = "Premium Data Overview",
      status = "white",
      solidHeader = TRUE,
      width = 12,
      DTOutput(ns("viewPremiumData"))
     )
    )  
  )
}


premiumDataInput <- function(input, output, session) {
  ns <- session$ns
  
processedPremiumData <- eventReactive(input$file1, {
  req(input$file1)
  inFile <- input$file1

  withProgress(message = 'Loading Premium Data...', {
    incProgress(0.1)  # Initial progress
    
    # Check the file extension
    file_ext <- tools::file_ext(inFile$name)

    if (file_ext %in% c("xlsx", "xls")) {
      # Process Excel file
      data <- read_excel(inFile$datapath) %>%
        mutate(
          `Period_From` = as.Date(`Period_From`, format = "%m/%d/%Y"),
          `Period_Upto` = as.Date(`Period_Upto`, format = "%m/%d/%Y"),
          Policy_ID = paste(PolicyNo, Period_From, Period_Upto)
        ) %>%
        group_by(Policy_ID) %>%
        mutate(Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
    } else if (file_ext == "csv") {
      # Process CSV file
      data <- read_csv(inFile$datapath) %>%
        mutate(
          `Period_From` = as.Date(`Period_From`, format = "%m/%d/%Y"),
          `Period_Upto` = as.Date(`Period_Upto`, format = "%m/%d/%Y"),
          Policy_ID = paste(PolicyNo, Period_From, Period_Upto)
        ) %>%
        group_by(Policy_ID) %>%
        mutate(Unique = ifelse(row_number() == 1, 1, 0)) %>%
        ungroup()
    } else {
      stop("Unsupported file format. Please upload an Excel or CSV file.")
    }

    incProgress(0.9, detail = "Almost done...")  # Incremental progress
    data
  })
})
  
  output$viewPremiumData <- renderDT({
    req(processedPremiumData())
    datatable(processedPremiumData(), options = list(scrollX = TRUE, 
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

  return(reactive({ processedPremiumData() }))
  
}
