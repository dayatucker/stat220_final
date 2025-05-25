library(shiny)
library(httr2)
library(tidyverse)
library(plotly)

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

# Your get_artists_data function
get_artists_data <- function(artist_ids, token) {
  artist_chunks <- split(artist_ids, ceiling(seq_along(artist_ids) / 50))
  
  map_dfr(artist_chunks, function(ids_chunk) {
    req <- request("https://api.spotify.com/v1/artists") |>
      req_url_query(ids = paste(ids_chunk, collapse = ",")) |>
      req_headers(Authorization = paste("Bearer", token))
    
    resp <- req_perform(req)
    if (resp_status(resp) != 200) stop("Spotify API artists request failed")
    
    content <- resp_body_json(resp, simplifyVector = FALSE)
    artists <- content$artists
    
    map_dfr(artists, function(artist) {
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

# Spotify client credentials - read from your files
client_id <- readLines("spotify_client_id.txt")
client_secret <- readLines("spotify_client_secret.txt")

# Example artist IDs
artist_ids <- c(
  "06HL4z0CvFAxyc27GXpf02", # Taylor Swift
  "1Xyo4u8uXC1ZmMpatF05PJ", # The Weeknd
  "4q3ewBCX7sLwd24euuV69X", # Bad Bunny
  "3TVXtAsR1Inumwj472S9r4", # Drake
  "6qqNVTkY8uBg9cP3Jd7DAH", # Billie Eilish
  "0Y5tJX1MQlPlqiwlOH1tJY", # Post Malone
  "12GqGscKJx3aE4t07u7eVZ", # Imagine Dragons
  "5K4W6rqBFWDnAN6FQUkS6x", # Kanye West
  "66CXWjxzNUsdJxJ2JdwvnR", # Ariana Grande
  "2LRoIwlKmHjgvigdNGBHNo"  # Eminem
)

ui <- fluidPage(
  titlePanel("Spotify Artists: Followers vs Popularity"),
  
  sidebarLayout(
    sidebarPanel(
      actionButton("load_data", "Load Artist Data"),
      br(),
      uiOutput("artist_selector")
    ),
    
    mainPanel(
      plotlyOutput("followers_popularity_plot"),
      verbatimTextOutput("status_text")
    )
  )
)

server <- function(input, output, session) {
  token <- reactiveVal(NULL)
  artists_data <- reactiveVal(NULL)
  status_text <- reactiveVal("Click 'Load Artist Data' to start.")
  
  output$status_text <- renderText(status_text())
  
  observeEvent(input$load_data, {
    status_text("Getting Spotify token...")
    tryCatch({
      tk <- get_spotify_token(client_id, client_secret)
      token(tk)
      status_text("Fetching artist data...")
      data <- get_artists_data(artist_ids, tk)
      artists_data(data)
      status_text("Data loaded successfully!")
    }, error = function(e) {
      status_text(paste("Error:", e$message))
    })
  })
  
  output$artist_selector <- renderUI({
    req(artists_data())
    selectInput(
      "selected_artists",
      "Select Artists to Plot:",
      choices = setNames(artists_data()$artist_id, artists_data()$artist_name),
      selected = artists_data()$artist_id,
      multiple = TRUE
    )
  })
  
  filtered_data <- reactive({
    req(artists_data())
    req(input$selected_artists)
    artists_data() %>% filter(artist_id %in% input$selected_artists)
  })
  
  output$followers_popularity_plot <- renderPlotly({
    df <- filtered_data()
    req(nrow(df) > 0)
    
    plot_ly(
      df,
      x = ~followers / 1e6,
      y = ~popularity,
      type = "scatter",
      mode = "markers+text",
      text = ~artist_name,
      textposition = "top center",
      marker = list(size = 12, color = 'darkblue', opacity = 0.7),
      hoverinfo = "text",
      hovertext = ~paste(
        "Artist:", artist_name,
        "<br>Followers (M):", round(followers / 1e6, 2),
        "<br>Popularity:", popularity,
        "<br>Genres:", genres
      )
    ) %>%
      layout(
        title = "Spotify Followers vs Popularity",
        xaxis = list(title = "Followers (Millions)"),
        yaxis = list(title = "Popularity (0-100)", range = c(0, 100)),
        hovermode = "closest"
      )
  })
}

shinyApp(ui, server)