# Load packages ----------------------------------------------------------------

library(tidyverse)
library(tidycensus)
library(ggthemes)
library(rvest)
library(janitor)
library(lubridate)
library(httr2)
library(purrr)
library(plotly)
library(shiny)
library(spotifyr)
library(DT)

# Define artist IDs BEFORE using them -----------------------------------------

artist_ids <- c(
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "1Xyo4u8uXC1ZmMpatF05PJ",  # The Weeknd
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "6qqNVTkY8uBg9cP3Jd7DAH",  # Billie Eilish
  "0Y5tJX1MQlPlqiwlOH1tJY",  # Travis Scott
  "12GqGscKJx3aE4t07u7eVZ",  # Ice Spice
  "5K4W6rqBFWDnAN6FQUkS6x",  # Kanye West
  "66CXWjxzNUsdJxJ2JdwvnR",  # Ariana Grande
  "2LRoIwlKmHjgvigdNGBHNo"   # Peso Pluma
)

# Load and prep data ----------------------------------------------------------

# Create a dataframe with top tracks for each artist, with artist name included
top_artist_tracks <- map_dfr(artist_ids, function(id) {
  artist_tracks <- get_artist_top_tracks(id, token)
  artist_name <- get_artists_data(id, token)$artist_name
  artist_tracks |> mutate(artist_id = id, artist_name = artist_name)
})

# Make sure all_tracks exists and is cleaned
all_tracks <- all_tracks |>
  mutate(album_release_date = as.Date(album_release_date),
         playlist_name = as.factor(playlist_name))

# Combine datasets
combined_tracks <- bind_rows(
  all_tracks |> mutate(source = "Playlist"),
  top_artist_tracks |> mutate(source = "Top Artist")
)

# UI --------------------------------------------------------------------------
ui <- fluidPage(
  titlePanel("Spotify Tracks Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("source", "Choose Source:", choices = c("All", "Playlist", "Top Artist")),
      uiOutput("artist_or_playlist_ui")
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Popularity Bar Chart", plotlyOutput("popularityPlot")),
        tabPanel("Track Duration Histogram", plotlyOutput("durationPlot")),
        tabPanel("Track Table", DTOutput("trackTable"))
      )
    )
  )
)

# Server ----------------------------------------------------------------------
server <- function(input, output, session) {
  
  # Dynamic UI for filtering
  output$artist_or_playlist_ui <- renderUI({
    if (input$source == "Playlist") {
      choices <- c("All", unique(combined_tracks$playlist_name))
    } else if (input$source == "Top Artist") {
      choices <- c("All", unique(combined_tracks$artist_name))
    } else {
      choices <- "All"
    }
    selectInput("artist_or_playlist", "Filter by:", choices = choices)
  })
  
  # Reactive filtering
  filtered_tracks <- reactive({
    data <- combined_tracks
    
    if (input$source != "All") {
      data <- data %>% filter(source == input$source)
    }
    
    if (input$source == "Playlist" && input$artist_or_playlist != "All") {
      data <- data %>% filter(playlist_name == input$artist_or_playlist)
    } else if (input$source == "Top Artist" && input$artist_or_playlist != "All") {
      data <- data %>% filter(artist_name == input$artist_or_playlist)
    }
    
    data
  })
  
  # Plot: Popularity
  output$popularityPlot <- renderPlotly({
    data <- filtered_tracks() %>%
      arrange(desc(popularity)) %>%
      head(20)
    
    p <- ggplot(data, aes(x = reorder(track_name, popularity), y = popularity,
                          fill = source, text = paste("Artist:", artist_name))) +
      geom_col() +
      coord_flip() +
      labs(x = "Track", y = "Popularity", title = "Top 20 Tracks by Popularity") +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  # Plot: Duration
  output$durationPlot <- renderPlotly({
    data <- filtered_tracks()
    
    p <- ggplot(data, aes(x = track_duration_ms / 60000, fill = source)) +
      geom_histogram(binwidth = 0.5, alpha = 0.7) +
      labs(x = "Track Duration (minutes)", y = "Count", title = "Distribution of Track Durations") +
      theme_minimal()
    
    ggplotly(p)
  })
  
  # Table
  output$trackTable <- renderDT({
    filtered_tracks() %>%
      select(track_name, artist_name, album_name, popularity, track_duration_ms, source) %>%
      mutate(track_duration_min = round(track_duration_ms / 60000, 2)) %>%
      select(-track_duration_ms)
  })
}

# Run the app ------------------------------------------------------------------
shinyApp(ui, server)
