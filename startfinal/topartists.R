# Load required libraries
library(shiny)
library(tidyverse)
library(plotly)

# Mock example dataset for demonstration - replace with your actual all_tracks data
all_tracks <- tibble(
  artist_name = sample(
    c("Drake", "The Weeknd", "Taylor Swift", "Billie Eilish", "Adele", "Ed Sheeran"),
    size = 1000, replace = TRUE
  ),
  year = sample(2014:2025, size = 1000, replace = TRUE)
)

# Define UI
ui <- fluidPage(
  titlePanel("Top Artists Frequency in Spotify’s Top Hit Playlists (2014–2025)"),
  sidebarLayout(
    sidebarPanel(
      sliderInput("top_n", "Number of Top Artists to Display:",
                  min = 3, max = 20, value = 10)
    ),
    mainPanel(
      plotlyOutput("artistFreqPlot")
    )
  )
)

# Define server logic
server <- function(input, output) {
  
  top_artists_data <- reactive({
    all_tracks %>%
      count(artist_name, sort = TRUE) %>%
      slice_head(n = input$top_n)
  })
  
  output$artistFreqPlot <- renderPlotly({
    data <- top_artists_data()
    
    plot_ly(
      data,
      x = ~reorder(artist_name, n),
      y = ~n,
      type = "bar",
      marker = list(color = "royalblue"),
      text = ~paste("Artist:", artist_name, "<br>Appearances:", n),
      hoverinfo = "text"
    ) %>%
      layout(
        title = paste("Top", input$top_n, "Most Featured Artists"),
        xaxis = list(title = "Artist", tickangle = -45),
        yaxis = list(title = "Number of Appearances"),
        margin = list(b = 100),
        hovermode = "closest"
      )
  })
}

# Run the app
shinyApp(ui = ui, server = server)