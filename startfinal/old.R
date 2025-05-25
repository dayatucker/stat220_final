# Load packages ----------------------------------------------------------------

library(shiny)
library(tidyverse)
library(httr2)
library(plotly)
library(DT)

# Load and prep data -----------------------------------------------------------

client_id <- readLines("spotify_client_id.txt")
client_secret <- readLines("spotify_client_secret.txt")

get_spotify_token <- function(client_id, client_secret) {
  resp <- request("https://accounts.spotify.com/api/token") |>
    req_auth_basic(client_id, client_secret) |>
    req_body_form(grant_type = "client_credentials") |>
    req_method("POST") |>
    req_perform()
  
  resp_body_json(resp)$access_token
}

token <- get_spotify_token(client_id, client_secret)

get_artists_data <- function(artist_ids, token) {
  artist_chunks <- split(artist_ids, ceiling(seq_along(artist_ids) / 50))
  
  map_dfr(artist_chunks, function(ids_chunk) {
    req <- request("https://api.spotify.com/v1/artists") |>
      req_url_query(ids = paste(ids_chunk, collapse = ",")) |>
      req_headers(Authorization = paste("Bearer", token))
    
    resp <- req_perform(req)
    content <- resp_body_json(resp, simplifyVector = FALSE)
    
    map_dfr(content$artists, function(artist) {
      tibble(
        artist_id = artist$id,
        artist_name = artist$name,
        genres = paste(artist$genres, collapse = ", "),
        popularity = artist$popularity,
        followers = artist$followers$total,
        artist_url = artist$external_urls$spotify
      )
    })
  })
}

get_artist_top_tracks <- function(artist_id, token) {
  url <- paste0("https://api.spotify.com/v1/artists/", artist_id, "/top-tracks?market=US")
  
  req <- request(url) |>
    req_headers(Authorization = paste("Bearer", token))
  
  resp <- req_perform(req)
  content <- resp_body_json(resp, simplifyVector = FALSE)
  
  map_dfr(content$tracks, function(track) {
    tibble(
      track_name = track$name,
      album_name = track$album$name,
      popularity = track$popularity,
      track_duration_ms = track$duration_ms,
      explicit = track$explicit,
      artist_id = artist_id
    )
  })
}

artist_ids <- c(
  "06HL4z0CvFAxyc27GXpf02",
  "1Xyo4u8uXC1ZmMpatF05PJ",
  "4q3ewBCX7sLwd24euuV69X",
  "3TVXtAsR1Inumwj472S9r4",
  "6qqNVTkY8uBg9cP3Jd7DAH",
  "0Y5tJX1MQlPlqiwlOH1tJY",
  "12GqGscKJx3aE4t07u7eVZ",
  "5K4W6rqBFWDnAN6FQUkS6x",
  "66CXWjxzNUsdJxJ2JdwvnR",
  "2LRoIwlKmHjgvigdNGBHNo"
)

artists_data <- get_artists_data(artist_ids, token)
artist_choices <- c("All Artists" = "all", setNames(artists_data$artist_id, artists_data$artist_name))

# Define UI --------------------------------------------------------------------

ui <- fluidPage(
  titlePanel("Spotify Artist Explorer"),
  tabsetPanel(
    tabPanel("Top Songs Table",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selected_artist_table", "Choose an Artist:",
                             choices = artist_choices, selected = "all")
               ),
               mainPanel(
                 DTOutput("top_songs_table")
               )
             )
    ),
    tabPanel("Top Songs Plot",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selected_artist_plot", "Choose an Artist:",
                             choices = artist_choices, selected = "all"),
                 radioButtons("explicit_filter", "Explicit Filter:",
                              choices = c("All", "Explicit Only", "Not Explicit Only"),
                              selected = "All")
               ),
               mainPanel(
                 plotlyOutput("top_songs_plot")
               )
             )
    )
  )
)

# Define server function -------------------------------------------------------

server <- function(input, output, session) {
  fetch_tracks <- function(artist_id) {
    if (artist_id == "all") {
      # Fetch all artists' top tracks, combine
      tracks_list <- lapply(artist_ids, get_artist_top_tracks, token = token)
      all_tracks <- bind_rows(tracks_list)
      
      # Order descending by popularity and keep top 10 only
      all_tracks %>% arrange(desc(popularity)) %>% slice_head(n = 10)
    } else {
      get_artist_top_tracks(artist_id, token)
    }
  }
  
  top_tracks_table_data <- reactive({
    req(input$selected_artist_table)
    tracks <- fetch_tracks(input$selected_artist_table)
    tracks
  })
  
  output$top_songs_table <- renderDT({
    top_tracks_table_data() %>%
      mutate(duration_min = round(track_duration_ms / 60000, 2)) %>%
      select(Track = track_name,
             Album = album_name,
             Popularity = popularity,
             `Duration (min)` = duration_min,
             Explicit = explicit)
  }, options = list(pageLength = 10))
  
  top_tracks_plot_data <- reactive({
    req(input$selected_artist_plot)
    tracks <- fetch_tracks(input$selected_artist_plot)
    
    if (input$explicit_filter == "Explicit Only") {
      tracks <- filter(tracks, explicit == TRUE)
    } else if (input$explicit_filter == "Not Explicit Only") {
      tracks <- filter(tracks, explicit == FALSE)
    }
    tracks
  })
  
  output$top_songs_plot <- renderPlotly({
    plot_data <- top_tracks_plot_data()
    
    # Join artist name for hover info
    plot_data <- left_join(plot_data, artists_data %>% select(artist_id, artist_name), by = "artist_id")
    
    plot_ly(plot_data,
            x = ~reorder(track_name, popularity),
            y = ~popularity,
            type = 'bar',
            color = ~explicit,
            colors = c('blue', 'red'),
            text = ~paste("Track:", track_name,
                          "<br>Artist:", artist_name,
                          "<br>Popularity:", popularity,
                          "<br>Explicit:", ifelse(explicit, "Yes", "No")),
            hoverinfo = "text") %>%
      layout(title = "Top Tracks Popularity",
             xaxis = list(title = "Track Name", tickangle = -45),
             yaxis = list(title = "Popularity"),
             barmode = "group")
  })
}

# Create the Shiny app object --------------------------------------------------

shinyApp(ui, server)
