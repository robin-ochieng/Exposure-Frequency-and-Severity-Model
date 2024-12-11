frequencyvsSeverityUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
        bs4Card(
            selectInput(ns("yearInput"), "Select Plot Year:", choices = character(0)),
            br(),
            title = "Frequency vs Severity Plot",
            status = "white",
            solidHeader = TRUE,
            width = 12,
        fluidRow(
            hr(),
            actionButton(ns("showPlot1"), "Calculate Frequency vs Severity Plot and Table", class = "btn btn-primary btn-primary-custom"),
            hr()),  
            br(),
            br(),
            uiOutput(ns("plotUI1"))
        )
      ),
    fluidRow(
        bs4Card(
            selectInput(ns("selectedYear"), "Select Year:", choices = character(0)),
            br(),
            title = "Frequency vs Severity Table",
            status = "white",
            solidHeader = TRUE,
            width = 12,
            uiOutput(ns("tableUI"))
            )
          )
  )
}


frequencyvsSeverityServer <- function(id, Frequency_Results, Severity_Results) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns

  Merged_Risk_Premium <- reactive({
    merged_data <- merge(Frequency_Results(), Severity_Results(), by = "Statutory_Class", all = TRUE)
    
    if (nrow(merged_data) == 0) {
      showNotification("Merged_Risk_Premium is empty", type = "error")
      return(data.frame())  # Return an empty data frame to prevent further errors
    }
    
    merged_data
  })
  
  data_long <- reactive({
    req(Merged_Risk_Premium())
    Merged_Risk_Premium() %>%
      pivot_longer(
        cols = matches("Freq_|Sev_"),
        names_to = c(".value", "year"),
        names_pattern = "(Freq_|Sev_)(\\d+)"
      )%>%
      filter(!is.na(year)) 
  })
  
  observe({
    updateSelectInput(session, "yearInput", choices = unique(data_long()$year))
  })
  
  # Render plot based on user input
  output$yearPlot1 <- renderPlotly({
    req(input$yearInput)  # Ensure that the input is not NULL
    year_data <- data_long() %>% filter(year == input$yearInput)
    
    p <- ggplot(year_data, aes(x = Sev_, y = Freq_)) +
      geom_point(aes(color = Statutory_Class), size = 4, alpha = 0.8) +
      geom_label_repel(aes(label = Statutory_Class), size = 3, box.padding = unit(0.35, "lines"),
                       point.padding = unit(0.5, "lines"),
                       label.padding = unit(0.2, "lines")) +
      scale_color_viridis_d(option = "D") +
      labs(
        title = paste("Scatter Plot of Severity vs Frequency for the year", input$yearInput),
        x = "Severity",
        y = "Frequency"
      ) +
      theme_minimal() +
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5, size = 20),  # Center and increase font size of title
            panel.grid.major = element_blank(),  # Remove major grid lines
            panel.grid.minor = element_blank())
    
    ggplotly(p)  # Convert ggplot object to plotly interactive plot
  })
  
  # Conditional UI to display or hide the plot
  output$plotUI1 <- renderUI({
    if (input$showPlot1 %% 2 == 1) { # Show plot if button is pressed an odd number of times
      plotlyOutput(ns("yearPlot1"), height = "550px")
    }
  })

  # Prepare data for the table showing yearly changes with percentage calculations
  yearly_changes <- reactive({
    req(data_long())
    data_long() %>%
      group_by(year, Statutory_Class) %>%
      summarise(
        Average_Severity = mean(Sev_, na.rm = TRUE),
        Average_Frequency = mean(Freq_, na.rm = TRUE),
        .groups = 'drop'
      ) %>%
      arrange(Statutory_Class, year) %>%
      group_by(Statutory_Class) %>%
      mutate(
        Freq_Percent_Change = (Average_Frequency / lag(Average_Frequency) - 1) * 100,
        Sev_Percent_Change = (Average_Severity / lag(Average_Severity) - 1) * 100
      ) %>%
      ungroup()
  })
  
  observe({
    updateSelectInput(session, "selectedYear", choices = unique(yearly_changes()$year))
  })
  
  filtered_data <- reactive({
    yearly_changes() %>%
      filter(year == input$selectedYear) %>%
      mutate(Average_Severity = formatC(Average_Severity, format = "f", big.mark = ",", digits = 0),
             Average_Frequency = format(Average_Frequency, big.mark = ",", digits = 1, nsmall = 1),
             Freq_Percent_Change = format(Freq_Percent_Change, big.mark = ",", digits = 1, nsmall = 1),
             Sev_Percent_Change = format(Sev_Percent_Change, big.mark = ",", digits = 1, nsmall = 1))
  })
  
  output$yearlyChangesTable <- renderDT({
    datatable(filtered_data()[, c("Statutory_Class", "Average_Severity", "Average_Frequency", 
                                  "Freq_Percent_Change", "Sev_Percent_Change")], 
              options = list(pageLength = 20, autoWidth = TRUE), 
              rownames = FALSE, escape = FALSE) %>%
      formatStyle(
        'Freq_Percent_Change',
        valueColumns = 'Freq_Percent_Change',
        target = 'cell',
        field = 'Freq_Percent_Change',
        color = styleInterval(0, c("red", "blue")),
        backgroundColor = styleInterval(0, c("pink", "lightblue")),
        fontWeight = 'bold',
        fontSize = styleInterval(0, c("100%", "100%")),
        content = JS(
          "function(data, type, row, meta){
          if (type === 'display'){
            var icon = data > 0 ? '&#9650;' : '&#9660;';
            var color = data > 0 ? 'blue' : 'red';
            return '<span style=\"color:' + color + ';\">' + data.toFixed(2) + '% ' + icon + '</span>';
          }
          return data.toFixed(2) + '%';
        }"
        )
      ) %>%
      formatStyle(
        'Sev_Percent_Change',
        valueColumns = 'Sev_Percent_Change',
        target = 'cell',
        field = 'Sev_Percent_Change',
        color = styleInterval(0, c("red", "blue")),
        backgroundColor = styleInterval(0, c("pink", "lightblue")),
        fontWeight = 'bold',
        fontSize = styleInterval(0, c("100%", "100%")),
        content = JS(
          "function(data, type, row, meta){
          if (type === 'display'){
            var icon = data > 0 ? '&#9650;' : '&#9660;';
            var color = data > 0 ? 'blue' : 'red';
            return '<span style=\"color:' + color + ';\">' + data.toFixed(2) + '% ' + icon + '</span>';
          }
          return data.toFixed(2) + '%';
        }"
        )
      )
  })

    # Conditional UI for the table (showing after button press)
    output$tableUI <- renderUI({
      if (input$showPlot1 %% 2 == 1) {
        DTOutput(ns("yearlyChangesTable"))
      }
    })


  })
}

