library(shiny)
library(shinyjs)
library(tidyverse)
library(DT)
library(plotly)
library(tidytext)

# Load Data ----
combined_artists_tracks <- read_csv("data/combined_artists_tracks_2018_2024.csv")
combined_albums_tracks <- read_csv("data/combined_albums_tracks_2018_2024.csv")
new_releases_combined <- read_csv("data/new_releases_combined.csv")

# Release year
combined_artists_tracks <- combined_artists_tracks |>
  mutate(release_year = as.integer(release_year))

# Get all unique genres
genre_choices <- combined_artists_tracks |>
  separate_rows(genres, sep = ",\\s*") |>
  filter(!is.na(genres), genres != "") |>
  distinct(genres) |>
  arrange(genres) |>
  pull(genres)
# Randomly select 3 genres
selected_genres <- sample(genre_choices, 3)

# UI ----
ui <- fluidPage(
  useShinyjs(),
  
  tags$head(
    tags$style(HTML("
    body {
      background-color: #111;
      color: white;
    }

    #sidebar {
      width: 250px;
      background: #000000;
      color: white;
      position: fixed;
      height: 100%;
      overflow-y: auto;
      padding: 10px;
      border-right: 1px solid #333;
      display: block;
      transition: all 0.3s ease;
    }

    #sidebar.hidden {
      margin-left: -260px;
    }

    #content {
      margin-left: 260px;
      transition: all 0.3s ease;
    }

    #content.fullwidth {
      margin-left: 0;
    }

    /* Radio buttons white text */
    .radio label {
      color: white;
    }

    /* Toggle button style */
    #toggleSidebar {
      background-color: transparent;
      border: none;
      font-size: 40px;
      cursor: pointer;
      color: white;
    }
  "))
  ),
  
  # Menu
  actionButton("toggleSidebar", "\u2630", 
               style = "background-color: transparent; border: none; font-size: 40px; cursor: pointer; color: white;"),
  
  div(id = "sidebar",
      h3("Menu"),
      radioButtons("nav", NULL, choices = c(
        "Top Artists/Albums" = "artists",
        "Top Tracks" = "tracks",
        "Track Genre" = "genre",
        "Years Since Release" = "years",
        "Track Duration" = "duration",
        "Number of Tracks in an Album" = "track_count",
        "Tracks with Features" = "features",
        "Most Common Words" = "words",
        "New Releases" = "new_releases")
      )
  ),
  
  div(id = "content",
      p(
        includeCSS("www/styles.css"),
        
        titlePanel("Spotify Music Explorer 2018-2024"),
        
        # Random Song Spotlight Section
        h3("🎵Random Song Spotlight🎵"),
        uiOutput("song_spotlight"),
        
        uiOutput("main_content")
      )))

# Server ----
server <- function(input, output, session) {
  
  observeEvent(input$toggleSidebar, {
    shinyjs::toggleClass("sidebar", "hidden")
    shinyjs::toggleClass("content", "fullwidth")
  })
  
  output$main_content <- renderUI({
    switch(input$nav,
           "artists" = {
             # Top Artists/Albums Tab
             tabPanel("Top Artists/Albums",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("selected_year", "Select Year:", choices = 2018:2024, selected = 2024),
                          helpText("View top charting artists and albums by year."),
                          conditionalPanel(
                            condition = "input.top_selected == 'Top Artists'",
                            uiOutput("top_artist_iframe")
                          ),
                          conditionalPanel(
                            condition = "input.top_selected == 'Top Albums'",
                            uiOutput("top_album_iframe")
                          )
                        ),
                        mainPanel(
                          br(),
                          tabsetPanel(id = "top_selected",
                                      tabPanel("Top Artists",
                                               h3("Top Artists"),
                                               DTOutput("artist_table")
                                      ),
                                      tabPanel("Top Albums",
                                               h3("Top Albums"),
                                               DTOutput("album_table")
                                      )
                          ),
                          br()
                          
                        )
                      )
             )
           },
           "tracks" = {
             # Top Tracks Tab
             tabPanel("Top Tracks",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("track_year", "Select Year:", choices = 2018:2024, selected = 2024),
                          helpText("Explore top tracks by artist or album for a selected year."),
                          conditionalPanel(
                            condition = "input.track_tab_selected == 'By Artist'",
                            uiOutput("artist_selector"),
                            uiOutput("artist_tracks_iframe")
                            
                          ),
                          conditionalPanel(
                            condition = "input.track_tab_selected == 'By Album'",
                            uiOutput("album_selector"),
                            uiOutput("album_tracks_iframe")
                          )
                        ),
                        mainPanel(
                          br(),
                          tabsetPanel(id = "track_tab_selected",
                                      tabPanel("By Artist", plotlyOutput("artist_tracks_plot")),
                                      tabPanel("By Album", plotlyOutput("album_tracks_plot"))
                          )
                        )
                      )
             )
           },
           "genre" = {
             # Track Genre Tab
             tabPanel("Track Genre",
                      sidebarLayout(
                        sidebarPanel(
                          checkboxGroupInput(
                            inputId = "selected_genres",
                            label = "Select Genres:",
                            choices = genre_choices,
                            selected = selected_genres
                          ),
                          helpText("Select one or more genres to compare track or album counts by year.")
                        ),
                        mainPanel(
                          br(),
                          tabsetPanel(
                            tabPanel("Bar Chart", plotlyOutput("genre_bar")),
                            tabPanel("Track Table", DT::dataTableOutput("genre_table"))
                          )
                        )
                      )
             )
           },
           "years" = {
             # Years Since Release Tab
             tabPanel("Years Since Release",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput(
                            "years_range",
                            "Select Years Since Release Range:",
                            min = floor(min(combined_artists_tracks$years_since_release, na.rm = TRUE)),
                            max = ceiling(max(combined_artists_tracks$years_since_release, na.rm = TRUE)),
                            value = c(
                              floor(min(combined_artists_tracks$years_since_release, na.rm = TRUE)),
                              ceiling(max(combined_artists_tracks$years_since_release, na.rm = TRUE))
                            ),
                            step = 1
                          ),
                          helpText("Negative values indicate tracks released after the charting year (e.g. pre-releases or delayed data).")
                        ),
                        mainPanel(
                          br(),
                          plotlyOutput("years_release_plot", height = "600px")
                        )
                      )
             )
           },
           "duration" = {
             # Track Duration Tab
             tabPanel("Track Duration",
                      sidebarLayout(
                        sidebarPanel(
                          sliderInput("duration_range", "Select Track Duration (Minutes):",
                                      min = 0, max = 10, value = c(2, 5), step = 0.1),
                          helpText("Use the slider to filter tracks by duration in minutes."),
                          conditionalPanel(
                            condition = "input.duration_tab_selected == 'By Artist'",
                            uiOutput("duration_artist_selector")
                          ),
                          conditionalPanel(
                            condition = "input.duration_tab_selected == 'By Album'",
                            uiOutput("duration_album_selector")
                          )
                        ),
                        mainPanel(
                          br(),
                          tabsetPanel(id = "duration_tab_selected",
                                      tabPanel("By Artist", plotlyOutput("duration_artist_plot")),
                                      tabPanel("By Album", plotlyOutput("duration_album_plot"))
                          )
                        )
                      )
             )
           },
           "track_count" = {
             # Number of Tracks in an Album Tab
             tabPanel("Number of Tracks in an Album",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("tracks_year", "Select Charted Year:", 
                                      choices = sort(unique(combined_albums_tracks$charted_year)), selected = 2024),
                          helpText("Select a year to see how many tracks albums had in that charting year.")
                        ),
                        mainPanel(
                          br(),
                          plotlyOutput("album_tracks_count_plot")
                        )
                      )
             )
           },
           "features" = {
             # Tracks with Features Tab
             tabPanel("Tracks with Features",
                      sidebarLayout(
                        sidebarPanel(
                          selectInput("features_year", "Select Charted Year:", 
                                      choices = sort(unique(combined_albums_tracks$charted_year)), selected = 2024),
                          uiOutput("features_album_selector"),
                          helpText("Explore collaborations and featured artists for selected albums.")
                        ),
                        mainPanel(
                          br(),
                          plotlyOutput("featured_tracks_plot"))
                      )
             )
           },
           "words" = {
             # Most Common Words in Track Names
             tabPanel("Most Common Words in Track Names",
                      fluidPage(
                        sidebarLayout(
                          sidebarPanel(
                            uiOutput("word_selector_ui"),
                            helpText("Words are colored by sentiment (positive/negative)")
                          ),
                          mainPanel(
                            br(),
                            plotlyOutput("word_trend_plot")
                          )
                        )
                      )
             )
           },
           "new_releases" = {
             # New Album Releases Tab
             tabPanel("New Album Releases 2024",
                      br(),
                      tabsetPanel(
                        tabPanel("Date of Album Release",
                                 sidebarLayout(
                                   sidebarPanel(
                                     dateRangeInput(
                                       inputId = "release_date_range",
                                       label = "Select Release Date Range:",
                                       start = as.Date("2024-04-01"),
                                       end = as.Date("2024-04-20"),
                                       min = as.Date("2024-04-01"),
                                       max = as.Date("2024-04-20")
                                     ),
                                     helpText("Select a date range only within April 2024.")
                                   ),
                                   mainPanel(
                                     br(),
                                     plotlyOutput("new_release_date_plot")
                                   )
                                 )
                        ),
                        tabPanel("Weekday of Album Release",
                                 sidebarLayout(
                                   sidebarPanel(
                                     helpText("This plot shows how many tracks were released on each weekday in April 2024.")
                                   ),
                                   mainPanel(
                                     br(),
                                     plotlyOutput("weekday_track_count_plot")
                                   )
                                 )
                        )
                      )
             )
           }
    )
  })
  
# Server ----
  # Pick a random song when the app loads
  output$song_spotlight <- renderUI({
    
    spotlight_song <- combined_artists_tracks[sample(nrow(combined_artists_tracks), 1), ]
    
    link <- str_c("https://open.spotify.com/embed/track/",spotlight_song$track_id,"?utm_source=generator&theme=0")
    
    fire <- ""
    
    if (spotlight_song$popularity >= 80) {
      fire <- "🔥"
    }
    if (spotlight_song$popularity >= 90) {
      fire <- "🔥🔥"
    }
    if (spotlight_song$popularity >= 95) {
      fire <- "🔥🔥🔥"
    }
    
    
    tagList(
      tags$iframe(src=link, 
                  width="100%", 
                  height="152", 
                  frameBorder="0", 
                  allowfullscreen="", 
                  allow="autoplay; 
              clipboard-write; 
              encrypted-media; 
              fullscreen; 
              picture-in-picture", 
                  loading="lazy"),
      p(str_c("Year Released: ", as.integer(spotlight_song$release_year))),
      p(str_c("Popularity: ", spotlight_song$popularity, fire))
    )
  })
  
# Top Artists/Albums Logic
  filtered_artists_year <- reactive({
    combined_artists_tracks |>
      filter(charted_year == input$selected_year) |>
      group_by(artist_name, genres, artist_id) |>
      summarise(avg_popularity = round(mean(popularity, na.rm = TRUE), 1),
                total_tracks = n(), .groups = "drop") |>
      arrange(desc(avg_popularity))
  })
  
  filtered_artists <- reactive({
    combined_artists_tracks |>
      filter(charted_year == input$selected_year) |>
      group_by(artist_name, genres) |>
      summarise(avg_popularity = round(mean(popularity, na.rm = TRUE), 1),
                total_tracks = n(), .groups = "drop") |>
      arrange(desc(avg_popularity))
  })
  
  filtered_albums_year <- reactive({
    combined_albums_tracks |>
      filter(charted_year == input$selected_year) |>
      group_by(album_name, album_type, album_id) |>
      summarise(total_tracks = max(total_tracks),
                release_date = first(release_date),
                avg_track_duration_sec = round(mean(track_duration_ms, na.rm = TRUE) / 1000, 1),
                .groups = "drop") |>
      arrange(release_date)
  })
  
  filtered_albums <- reactive({
    combined_albums_tracks |>
      filter(charted_year == input$selected_year) |>
      group_by(album_name) |>
      summarise(total_tracks = max(total_tracks),
                release_date = first(release_date),
                avg_track_duration_sec = round(mean(track_duration_ms, na.rm = TRUE) / 1000, 1),
                .groups = "drop") |>
      arrange(release_date)
  })
  
  output$artist_table <- renderDT({
    datatable(
      filtered_artists(), 
      options = list(pageLength = 10), 
      selection = 'single', 
      rownames = FALSE)
  })
  
  output$album_table  <- renderDT({
    datatable(
      filtered_albums(),  
      options = list(pageLength = 10), 
      selection = 'single', 
      rownames = FALSE) 
  })
  
  output$top_artist_iframe <- renderUI({
    selected_row <- input$artist_table_rows_selected
    if (length(selected_row)) {
      selected_artist <- filtered_artists_year()[selected_row, "artist_id", drop = TRUE]
      # Spotify artist URL (example: replace spaces with + for search)
      artist_url <- str_c("https://open.spotify.com/embed/artist/", selected_artist)
      tags$iframe(src = artist_url, width = "100%", height = "500", frameBorder = "0", 
                  allowfullscreen = "", allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture", 
                  loading = "lazy")
    } else {
      helpText(str_c("Select a row from the table to the right to view the artist's top 10 tracks"))
    }
  })
  
  output$top_album_iframe <- renderUI({
    selected_row <- input$album_table_rows_selected
    if (length(selected_row)) {
      selected_album <- filtered_albums_year()[selected_row, "album_id", drop = TRUE]
      # Spotify artist URL (example: replace spaces with + for search)
      album_url <- str_c("https://open.spotify.com/embed/album/", selected_album)
      tags$iframe(src = album_url, width = "100%", height = "500", frameBorder = "0", 
                  allowfullscreen = "", allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture", 
                  loading = "lazy")
    } else {
      # Placeholder instructions
      helpText(str_c("Select a row from the table to the right to view the tracks on the album"))
    }
  })
  
# Dynamic Track Selectors
  output$artist_selector <- renderUI({
    choices <- combined_artists_tracks |> filter(charted_year == input$track_year) |> distinct(artist_name) |> arrange(artist_name)
    selectInput("selected_artist", "Select Artist:", choices = choices$artist_name)
  })
  
  output$album_selector <- renderUI({
    choices <- combined_albums_tracks |> filter(charted_year == input$track_year) |> distinct(album_name) |> arrange(album_name)
    selectInput("selected_album", "Select Album:", choices = choices$album_name)
  })
  
  output$artist_tracks_iframe <- renderUI({
    req(input$selected_artist)
    df <- combined_artists_tracks |>
      filter(charted_year == input$track_year, artist_name == input$selected_artist)
    artist_id <- df$artist_id[1]
    
    artist_url <- str_c("https://open.spotify.com/embed/artist/", artist_id)
    tags$iframe(src = artist_url, width = "100%", height = "500", frameBorder = "0", 
                allowfullscreen = "", allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture", 
                loading = "lazy")
  })
  
  output$album_tracks_iframe <- renderUI({
    req(input$selected_album)
    df <- combined_albums_tracks |>
      filter(charted_year == input$track_year, album_name == input$selected_album)
    album_id <- df$album_id[1]
    
    album_url <- str_c("https://open.spotify.com/embed/album/", album_id)
    tags$iframe(src = album_url, width = "100%", height = "500", frameBorder = "0", 
                allowfullscreen = "", allow = "autoplay; clipboard-write; encrypted-media; fullscreen; picture-in-picture", 
                loading = "lazy")
  })
  
# Top Artist/Album Tracks
  output$artist_tracks_plot <- renderPlotly({
    req(input$selected_artist)
    df <- combined_artists_tracks |>
      filter(charted_year == input$track_year, artist_name == input$selected_artist)
    p <- ggplot(df, aes(x = reorder(track_name, popularity), y = popularity, fill = as.factor(explicit),
                        text = str_c(
                          "Track: ", track_name,
                          "\nPopularity: ", popularity,
                          "\nExplicit: ", ifelse(explicit, "Yes", "No")
                        ))) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c("FALSE" = "#1ed760", "TRUE" = "#191414")) +
      labs(title = str_c("Tracks by ", input$selected_artist),
           x = "Track Name", y = "Popularity", fill = "Explicit") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
  output$album_tracks_plot <- renderPlotly({
    req(input$selected_album)
    df <- combined_albums_tracks |>
      filter(charted_year == input$track_year, album_name == input$selected_album)
    p <- ggplot(df, aes(x = reorder(track_name, track_popularity), y = track_popularity, fill = as.factor(track_explicit),
                        text = str_c(
                          "Track: ", track_name,
                          "\nPopularity: ", track_popularity,
                          "\nExplicit: ", ifelse(track_explicit, "Yes", "No")
                        ))) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = c("FALSE" = "#1ed760", "TRUE" = "#191414")) +
      labs(title = str_c("Tracks from Album: ", input$selected_album),
           x = "Track Name", y = "Popularity", fill = "Explicit") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
# Genre Tab
  output$genre_bar <- renderPlotly({
    req(input$selected_genres)
    df <- combined_artists_tracks |>
      separate_rows(genres, sep = ",\\s*") |>
      filter(genres %in% input$selected_genres) |>
      distinct(album_name, genres, charted_year) |>
      count(genres, charted_year, name = "track_count") |>
      mutate(charted_year = as.factor(charted_year))
    p <- ggplot(df, aes(x = charted_year, y = track_count, fill = genres,
                        text = str_c("Genre: ", genres, "\nYear: ", charted_year, "\nCount: ", track_count))) +
      geom_col(position = "dodge") +
      labs(title = "Number of Tracks per Genre by Year",
           x = "Year", y = "Unique Track Count", fill = "Genre")
    ggplotly(p, tooltip = "text")
  })
  
  output$genre_table <- DT::renderDataTable({
    req(input$selected_genres)
    combined_artists_tracks |>
      separate_rows(genres, sep = ",\\s*") |>
      filter(genres %in% input$selected_genres) |>
      group_by(track_name, artist_name) |>
      summarise(
        genres = str_c(unique(genres), collapse = ", "),
        album_name = first(album_name),
        popularity = max(popularity, na.rm = TRUE),
        charted_years = paste(sort(unique(charted_year)), collapse = ", "),
        .groups = "drop"
      ) |>
      arrange(desc(popularity))
  })
  
# Years Since Release
  output$years_release_plot <- renderPlotly({
    df <- combined_artists_tracks |>
      filter(!is.na(years_since_release),
             years_since_release >= input$years_range[1],
             years_since_release <= input$years_range[2]) |>
      distinct(artist_name, track_name, .keep_all = TRUE) |>
      mutate(hover_text = str_c("Artist: ", artist_name,
                                "\nTrack: ", track_name,
                                "\nYears Since Release: ", round(years_since_release, 1),
                                "\nPopularity: ", popularity))
    p <- ggplot(df, aes(x = years_since_release, y = popularity, text = hover_text)) +
      geom_point(alpha = 0.6, color = "#1ed760") +
      labs(title = "Track Popularity vs. Years Since Release",
           x = "Years Since Release", y = "Popularity")
    ggplotly(p, tooltip = "text")
  })
  
# Track Duration
  output$duration_artist_selector <- renderUI({
    selectInput("duration_artist", "Select Artist:",
                choices = c("All", sort(unique(combined_artists_tracks$artist_name))),
                selected = "All")
  })
  
  output$duration_album_selector <- renderUI({
    selectInput("duration_album", "Select Album:",
                choices = c("All", sort(unique(combined_albums_tracks$album_name))),
                selected = "All")
  })
  
  output$duration_artist_plot <- renderPlotly({
    req(input$duration_artist)
    
    df <- combined_artists_tracks |>
      mutate(duration_min = track_duration_ms / 60000) |>
      filter(duration_min >= input$duration_range[1], duration_min <= input$duration_range[2])
    
    if (input$duration_artist != "All") {
      df <- df |> filter(artist_name == input$duration_artist)
    }
    
    p <- ggplot(df, aes(x = duration_min, y = popularity,
                        text = str_c("Track: ", track_name,
                                     "\nArtist: ", artist_name,
                                     "\nDuration: ", round(duration_min, 2), " min",
                                     "\nPopularity: ", popularity))) +
      geom_point(alpha = 0.7, color = "#1ed760") +
      labs(title = ifelse(input$duration_artist == "All",
                          "Popularity vs. Duration for All Artists",
                          str_c("Popularity vs. Duration for ", input$duration_artist)),
           x = "Track Duration (Minutes)", y = "Popularity")
    ggplotly(p, tooltip = "text")
  })
  
  output$duration_album_plot <- renderPlotly({
    req(input$duration_album)
    
    df <- combined_albums_tracks |>
      mutate(duration_min = track_duration_ms / 60000) |>
      filter(duration_min >= input$duration_range[1], duration_min <= input$duration_range[2])
    
    if (input$duration_album != "All") {
      df <- df |> filter(album_name == input$duration_album)
    }
    
    p <- ggplot(df, aes(x = duration_min, y = track_popularity,
                        text = str_c("Track: ", track_name,
                                     "\nAlbum: ", album_name,
                                     "\nArtist: ", track_artists,
                                     "\nDuration: ", round(duration_min, 2), " min",
                                     "\nPopularity: ", track_popularity))) +
      geom_point(alpha = 0.7, color = "#1ed760") +
      labs(title = ifelse(input$duration_album == "All",
                          "Popularity vs. Duration for All Albums",
                          str_c("Popularity vs. Duration for Album: ", input$duration_album)),
           x = "Track Duration (Minutes)", y = "Popularity")
    ggplotly(p, tooltip = "text")
  })
  
# Number of Tracks in Album
  output$album_tracks_count_plot <- renderPlotly({
    req(input$tracks_year)
    album_counts <- combined_albums_tracks |>
      filter(charted_year == input$tracks_year) |>
      group_by(album_name, track_artists) |>
      summarise(num_tracks = n(), .groups = "drop") |>
      arrange(desc(num_tracks)) |>
      mutate(hover_text = str_c("Album: ", album_name, "\nArtist(s): ", track_artists, "\nTracks: ", num_tracks))
    p <- ggplot(album_counts, aes(x = reorder(album_name, num_tracks), y = num_tracks, text = hover_text)) +
      geom_bar(stat = "identity", fill = "#1ed760") + coord_flip() +
      labs(title = str_c("Number of Tracks per Album in ", input$tracks_year), x = "Album Name", y = "Number of Tracks") +
      theme(axis.text.y = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
# Tracks with Features Tab
  output$features_album_selector <- renderUI({
    choices <- combined_albums_tracks |> filter(charted_year == input$features_year) |> distinct(album_name) |> arrange(album_name)
    selectInput("features_album", "Select Album:", choices = choices$album_name)
  })
  
  output$featured_tracks_plot <- renderPlotly({
    req(input$features_album)
    df <- combined_albums_tracks |>
      filter(charted_year == input$features_year, album_name == input$features_album) |>
      mutate(has_feature = str_detect(tolower(track_name), "feat\\.|with"),
             feature_label = ifelse(has_feature, "With Feature", "No Feature"))
    p <- ggplot(df, aes(x = reorder(track_name, track_popularity), y = track_popularity, fill = feature_label,
                        text = str_c("Track: ", track_name, "\nArtist Name: ", track_artists, "\nPopularity: ", track_popularity, "\nFeature: ", feature_label))) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(title = paste("Tracks from", input$features_album), x = "Track Name", y = "Popularity", fill = "Has Feature")
    ggplotly(p, tooltip = "text")
  })
  
# Most Common Words in Track Names
  # Load sentiment lexicon
  bing_sentiments <- get_sentiments("bing")
  
  top_words_sentiment <- reactive({
    # Ensure unique track names within each year
    unique_tracks <- combined_albums_tracks |>
      filter(!is.na(charted_year)) |>
      distinct(charted_year, track_name)  # distinct per year
    
    # Tokenize words from track names
    word_data <- unique_tracks |>
      unnest_tokens(word, track_name) |>
      anti_join(stop_words, by = "word") |>
      count(charted_year, word, sort = TRUE)
    
    # Get overall top 10 words across all years
    top_words <- word_data |>
      group_by(word) |>
      summarise(total = sum(n), .groups = "drop") |>
      slice_max(order_by = total, n = 10) |>
      left_join(bing_sentiments, by = "word") |>
      mutate(sentiment = replace_na(sentiment, "neutral"))
    
    list(top_words = top_words, word_counts = word_data)
  })
  
  # Update word choices in checkboxGroupInput
  observe({
    words <- top_words_sentiment()$top_words$word
    updateCheckboxGroupInput(inputId = "selected_words",
                             choices = words,
                             selected = words)
  })
  
  output$word_selector_ui <- renderUI({
    words <- top_words_sentiment()$top_words$word
    checkboxGroupInput(
      inputId = "selected_words",
      label = "Select Words to Display:",
      choices = words,
      selected = words
    )
  })
  
  # Render the sentiment plot
  output$word_trend_plot <- renderPlotly({
    
    req(input$selected_words)
    
    data_all <- top_words_sentiment()
    top_words <- data_all$top_words
    word_counts <- data_all$word_counts
    
    # Filter to selected words
    selected_trends <- word_counts |>
      semi_join(top_words |> filter(word %in% input$selected_words), by = "word") |>
      left_join(top_words |> select(word, sentiment), by = "word")
    
    # Plot
    p <- selected_trends |>
      ggplot(aes(x = charted_year, y = n, color = sentiment, group = word)) +
      geom_line(aes(linetype = word)) +
      labs(title = "Trends in Usage of Common Track Name Words",
           x = "Year",
           y = "Word Frequency",
           color = "Sentiment",
           linetype = "Word")
    ggplotly(p)
  })
  
# New Album Releases Tab Logic
  output$new_release_date_plot <- renderPlotly({
    new_releases_combined$release_date <- as.Date(new_releases_combined$release_date)
    df <- new_releases_combined |>
      filter(release_date >= input$release_date_range[1],
             release_date <= input$release_date_range[2])
    df <- df |>
      mutate(weekday = format(release_date, "%A"))
    p <- ggplot(df, aes(
      x = release_date,
      y = popularity,
      text = str_c(
        "Track: ", track_name,
        "\nArtist: ", track_artists,
        "\nRelease Date: ", release_date,
        " (", weekday, ")"
      )
    )) +
      geom_point(alpha = 0.6, color = "#1ed760") +
      labs(title = "Popularity vs. Release Date", x = "Release Date", y = "Popularity") +
      scale_x_date(date_breaks = "1 day", date_labels = "%m-%d-%y") +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
  output$weekday_track_count_plot <- renderPlotly({
    df <- new_releases_combined |>
      filter(format(release_date, "%Y-%m") == "2024-04") |>
      mutate(weekday = weekdays(release_date)) |>
      count(weekday, name = "track_count") |>
      mutate(weekday = factor(
        weekday,
        levels = c("Monday", "Tuesday", "Wednesday", "Thursday", 
                   "Friday", "Saturday", "Sunday")
      ))
    
    p <- ggplot(df, aes(
      x = weekday, y = track_count, fill = weekday,
      text = paste("Weekday:", weekday, "\nTracks Released:", track_count)
    )) +
      geom_col(show.legend = FALSE) +
      labs(
        title = "New Tracks Released by Weekday (April 2024)",
        x = "Weekday", y = "Number of Tracks")
    ggplotly(p, tooltip = "text")
  })
  
}

# Run App ----
shinyApp(ui, server)


