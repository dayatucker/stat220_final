library(shiny)
library(tidyverse)
library(lubridate)
library(httr2)
library(purrr)
library(plotly)
library(DT)

# --- Spotify API functions -----------------------------------------------------

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
      track_explicit = track$explicit,
      artist_id = artist_id
    )
  })
}

get_playlist_tracks <- function(playlist_id, token) {
  url <- paste0("https://api.spotify.com/v1/playlists/", playlist_id, "/tracks")
  
  req <- request(url) |>
    req_headers(Authorization = paste("Bearer", token))
  
  resp <- req_perform(req)
  content <- resp_body_json(resp, simplifyVector = FALSE)
  tracks <- content$items
  
  map_dfr(tracks, function(item) {
    track <- item$track
    tibble(
      track_id = track$id,
      track_name = track$name,
      album_id = track$album$id,
      album_name = track$album$name,
      artist_id = track$artists[[1]]$id,
      artist_name = track$artists[[1]]$name,
      track_duration_ms = track$duration_ms,
      track_explicit = track$explicit,
      added_at = ymd_hms(item$added_at),
      album_release_date = track$album$release_date,
      popularity = track$popularity
    )
  })
}

# --- Insert your Spotify token here ---
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

# --- Artist IDs and Playlist IDs for 2014–2025 ---
artist_ids <- c(
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "1Xyo4u8uXC1ZmMpatF05PJ",  # The Weeknd
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "6qqNVTkY8uBg9cP3Jd7DAH",  # Billie Eilish
  "0Y5tJX1MQlPlqiwlOH1tJY",  # Travis Scott
  "12GqGscKJx3aE4t07u7eVZ",  # Peso Pluma
  "5K4W6rqBFWDnAN6FQUkS6x",  # Kanye West
  "66CXWjxzNUsdJxJ2JdwvnR",  # Ariana Grande
  "2LRoIwlKmHjgvigdNGBHNo"   # Feid
)

playlists <- list(
  "2014" = "5oN9E0LneOjbrYkGrZmUc9",
  "2015" = "4xYPZBwLtndo3MqjM0kMz1",
  "2016" = "0MvxEHiGaSFsKXry6Vjvb1",
  "2017" = "0cNzbPLBSPIFUrJkqxkmUw",
  "2018" = "5l771HfZDqlBsDFQzO0431",
  "2020" = "2fmTTbBkXi8pewbUvG3CeZ",
  "2021" = "5GhQiRkGuqzpWZSE7OU4Se",
  "2022" = "56r5qRUv3jSxADdmBkhcz7",
  "2023" = "6unJBM7ZGitZYFJKkO0e4P",
  "2024" = "774kUuKDzLa8ieaSmi8IfS",
  "2025" = "5mCL9f0hUeCm49FFPY8JGn"
)

# --- Load artist metadata ---
artists_data <- get_artists_data(artist_ids, token)

# --- Load playlist tracks and add year info ---
all_tracks <- map_dfr(names(playlists), function(year) {
  df <- get_playlist_tracks(playlists[[year]], token)
  df$playlist_name <- paste0(year, " Playlist")
  df$year <- as.integer(year)
  df
}) %>%
  mutate(album_release_date = as.Date(album_release_date),
         playlist_name = as.factor(playlist_name))

# --- Shiny UI ---
ui <- fluidPage(
  titlePanel("Spotify Top Hit Playlists (2014–2025) Dashboard"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("filter_year", "Select Year:", choices = c("All", sort(unique(all_tracks$year))), selected = "All"),
      checkboxGroupInput("explicit_filter", "Show Tracks Explicit Only?", choices = c("Yes" = TRUE, "No" = FALSE), selected = c(TRUE, FALSE))
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Top Songs by Artist",
                 selectInput("select_artist", "Select Artist:", choices = c("All", unique(all_tracks$artist_name)), selected = "All"),
                 plotlyOutput("top_songs_plot")
        ),
        tabPanel("Top 15 Most Featured Artists",
                 plotlyOutput("top_artists_plot")
        ),
        tabPanel("Explicit Tracks Share",
                 plotlyOutput("explicit_share_plot")
        ),
        tabPanel("Data Table",
                 DTOutput("tracks_table")
        )
      )
    )
  )
)

# --- Shiny Server ---
server <- function(input, output, session) {
  
  filtered_tracks <- reactive({
    df <- all_tracks
    if(input$filter_year != "All"){
      df <- df %>% filter(year == as.integer(input$filter_year))
    }
    if(!is.null(input$explicit_filter)) {
      explicit_vals <- as.logical(input$explicit_filter)
      df <- df %>% filter(track_explicit %in% explicit_vals)
    }
    df
  })
  
  output$top_songs_plot <- renderPlotly({
    df <- filtered_tracks()
    if(input$select_artist != "All"){
      df <- df %>% filter(artist_name == input$select_artist)
    }
    top_songs <- df %>%
      arrange(desc(popularity)) %>%
      distinct(track_name, .keep_all = TRUE) %>%  # avoid duplicate tracks
      slice_head(n = 20)
    
    p <- ggplot(top_songs, aes(x = reorder(track_name, popularity), y = popularity,
                               fill = track_explicit,
                               text = paste("Artist:", artist_name,
                                            "<br>Explicit:", track_explicit))) +
      geom_col() +
      coord_flip() +
      scale_fill_manual(values = c("TRUE" = "red", "FALSE" = "steelblue")) +
      labs(title = paste("Top 20 Tracks by Popularity",
                         ifelse(input$select_artist == "All", "", paste("for", input$select_artist))),
           x = "Track Name",
           y = "Popularity",
           fill = "Explicit") +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  output$top_artists_plot <- renderPlotly({
    df <- filtered_tracks()
    artist_counts <- df %>%
      group_by(artist_name) %>%
      summarise(track_count = n()) %>%
      arrange(desc(track_count)) %>%
      slice_head(n = 15)
    
    p <- ggplot(artist_counts, aes(x = reorder(artist_name, track_count), y = track_count,
                                   text = paste("Artist:", artist_name,
                                                "<br>Tracks:", track_count))) +
      geom_col(fill = "darkgreen") +
      coord_flip() +
      labs(title = "Top 15 Most Featured Artists",
           x = "Artist",
           y = "Number of Tracks") +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  output$explicit_share_plot <- renderPlotly({
    df <- all_tracks %>%
      filter(year >= 2014 & year <= 2025) %>%
      group_by(year) %>%
      summarise(
        explicit_count = sum(track_explicit),
        total_tracks = n(),
        explicit_share = explicit_count / total_tracks
      )
    
    p <- ggplot(df, aes(x = year, y = explicit_share,
                        text = paste0("Year: ", year,
                                      "<br>Explicit Tracks: ", explicit_count,
                                      "<br>Total Tracks: ", total_tracks,
                                      "<br>Share: ", scales::percent(explicit_share)))) +
      geom_line(group = 1, color = "purple", size = 1.2) +
      geom_point(color = "purple", size = 3) +
      scale_y_continuous(labels = scales::percent_format()) +
      labs(title = "Share of Explicit Tracks in Top Hit Playlists (2014–2025)",
           x = "Year",
           y = "Explicit Track Share") +
      theme_minimal()
    
    ggplotly(p, tooltip = "text")
  })
  
  output$tracks_table <- renderDT({
    df <- filtered_tracks()
    datatable(df %>% select(track_name, artist_name, album_name, year, popularity, track_explicit),
              options = list(pageLength = 10),
              rownames = FALSE)
  })
  
}

# Run the app
shinyApp(ui, server)

