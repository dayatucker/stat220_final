library(shiny)
library(tidyverse)
library(plotly)
library(lubridate)

# NOTE: Replace this with your actual all_tracks dataset loaded from your data source
# Here's a small mockup example — comment out or replace with your real data

# Uncomment and load your real data:
# all_tracks <- readRDS("path_to_your_all_tracks_data.rds")

# For demo, minimal example data:
all_tracks <- tibble(
  year = rep(2014:2025, each = 100),
  track_explicit = sample(c(TRUE, FALSE), size = 1200, replace = TRUE, prob = c(0.3, 0.7))
)

# Define UI
ui <- fluidPage(
  titlePanel("Explicit Tracks in Spotify's Top Hit Playlists (2014–2025)"),
  
  sidebarLayout(
    sidebarPanel(
      helpText("Visualizing percentage of explicit tracks per year in Spotify's Top Hit playlists.")
    ),
    mainPanel(
      plotlyOutput("explicitTrendPlot")
    )
  )
)

# Define server logic
server <- function(input, output, session) {
  
  explicit_trend_data <- reactive({
    all_tracks %>%
      group_by(year) %>%
      summarise(
        total_tracks = n(),
        explicit_tracks = sum(track_explicit),
        percent_explicit = round(100 * explicit_tracks / total_tracks, 1)
      )
  })
  
  output$explicitTrendPlot <- renderPlotly({
    data <- explicit_trend_data()
    
    plot_ly(
      data, x = ~year, y = ~percent_explicit,
      type = 'scatter', mode = 'lines+markers',
      marker = list(size = 10, color = 'red'),
      line = list(width = 3),
      text = ~paste0("Year: ", year, "<br>% Explicit: ", percent_explicit, "%"),
      hoverinfo = "text"
    ) %>%
      layout(
        title = "Percentage of Explicit Tracks in Spotify Top Hit Playlists by Year",
        xaxis = list(title = "Year", dtick = 1),
        yaxis = list(title = "% Explicit Tracks", range = c(0, 100)),
        hovermode = "closest"
      )
  })
}

# Run the app
shinyApp(ui = ui, server = server)