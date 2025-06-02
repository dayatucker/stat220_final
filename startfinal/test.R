library(shiny)
library(tidyverse)
library(DT)
library(plotly)

# Load Data ----
combined_artists_tracks <- read_csv("data/combined_artists_tracks_2018_2024.csv")
combined_albums_tracks <- read_csv("data/combined_albums_tracks_2018_2024.csv")
new_releases_combined <- read_csv("data/new_releases_combined.csv")

combined_artists_tracks <- combined_artists_tracks %>%
  mutate(release_year = as.Date(release_year))

# UI ----
ui <- fluidPage(
  titlePanel("Spotify Music Explorer 2018-2024"),
  
  # Random Song Spotlight Section
  h3("🎵Random Song Spotlight🎵"),
  uiOutput("song_spotlight"),
  
  tabsetPanel(
    # Top Artists/Albums Tab
    tabPanel("Top Artists/Albums",
             sidebarLayout(
               sidebarPanel(
                 selectInput("selected_year", "Select Year:", choices = 2018:2024, selected = 2024)
               ),
               mainPanel(
                 h3("Top Artists"),
                 DTOutput("artist_table"),
                 br(),
                 h3("Top Albums"),
                 DTOutput("album_table")
               )
             )
    ),
    
    # Top Tracks Tab
    tabPanel("Top Tracks",
             sidebarLayout(
               sidebarPanel(
                 selectInput("track_year", "Select Year:", choices = 2018:2024, selected = 2024),
                 conditionalPanel(
                   condition = "input.track_tab_selected == 'By Artist'",
                   uiOutput("artist_selector")
                 ),
                 conditionalPanel(
                   condition = "input.track_tab_selected == 'By Album'",
                   uiOutput("album_selector")
                 )
               ),
               mainPanel(
                 tabsetPanel(id = "track_tab_selected",
                             tabPanel("By Artist", plotlyOutput("artist_tracks_plot")),
                             tabPanel("By Album", plotlyOutput("album_tracks_plot"))
                 )
               )
             )
    ),
    
    # Track Genre Tab
    tabPanel("Track Genre",
             sidebarLayout(
               sidebarPanel(
                 checkboxGroupInput("selected_genres", "Select General Genres:",
                                    choices = sort(unique(unlist(str_split(combined_artists_tracks$genres, ",\\s*")))),
                                    selected = NULL)
               ),
               mainPanel(plotlyOutput("genre_scatter"))
             )
    ),
    
    # Years Since Release Tab
    tabPanel("Years Since Release",
             sidebarLayout(
               sidebarPanel(
                 sliderInput("years_range", "Select Years Since Release:",
                             min = floor(min(combined_artists_tracks$years_since_release, na.rm = TRUE)),
                             max = ceiling(max(combined_artists_tracks$years_since_release, na.rm = TRUE)),
                             value = c(0, 5), step = 0.5)
               ),
               mainPanel(plotlyOutput("years_release_plot"))
             )
    ),
    
    # Track Duration Tab
    tabPanel("Track Duration",
             sidebarLayout(
               sidebarPanel(
                 sliderInput("duration_range", "Select Track Duration (Minutes):",
                             min = 0, max = 10, value = c(2, 5), step = 0.1),
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
                 tabsetPanel(id = "duration_tab_selected",
                             tabPanel("By Artist", plotlyOutput("duration_artist_plot")),
                             tabPanel("By Album", plotlyOutput("duration_album_plot"))
                 )
               )
             )
    ),
    
    # Number of Tracks in an Album Tab
    tabPanel("Number of Tracks in an Album",
             sidebarLayout(
               sidebarPanel(
                 selectInput("tracks_year", "Select Charted Year:", 
                             choices = sort(unique(combined_albums_tracks$charted_year)), selected = 2024)
               ),
               mainPanel(plotlyOutput("album_tracks_count_plot"))
             )
    ),
    
    # Tracks with Features Tab
    tabPanel("Tracks with Features",
             sidebarLayout(
               sidebarPanel(
                 selectInput("features_year", "Select Charted Year:", 
                             choices = sort(unique(combined_albums_tracks$charted_year)), selected = 2024),
                 uiOutput("features_album_selector")
               ),
               mainPanel(plotlyOutput("featured_tracks_plot"))
             )
    ),
    
    # New Album Releases Tab
    tabPanel("New Album Releases",
             tabsetPanel(
               tabPanel("By Date",
                        sidebarLayout(
                          sidebarPanel(
                            dateRangeInput("release_date_range", "Select Release Date Range:",
                                           start = min(new_releases_combined$release_date, na.rm = TRUE),
                                           end = max(new_releases_combined$release_date, na.rm = TRUE))
                          ),
                          mainPanel(plotlyOutput("new_release_date_plot"))
                        )
               ),
               tabPanel("By Album",
                        sidebarLayout(
                          sidebarPanel(
                            checkboxGroupInput("selected_new_albums", "Select Album(s):",
                                               choices = sort(unique(new_releases_combined$album_name)))
                          ),
                          mainPanel(plotlyOutput("new_release_album_plot"))
                        )
               ),
               tabPanel("By Track",
                        sidebarLayout(
                          sidebarPanel(
                            checkboxGroupInput("selected_new_tracks", "Select Track(s):",
                                               choices = sort(unique(new_releases_combined$track_name)))
                          ),
                          mainPanel(plotlyOutput("new_release_track_plot"))
                        )
               )
             )
    )
  )
)

# Server ----
server <- function(input, output, session) {
  # Pick a random song when the app loads
  output$song_spotlight <- renderUI({
    if (nrow(combined_artists_tracks) == 0) return(NULL)
    
    spotlight_song <- combined_artists_tracks[sample(nrow(combined_artists_tracks), 1), ]
    
    tagList(
      h4(spotlight_song$track_name),
      h4(str_c("By:", spotlight_song$artist_name)),
      p(str_c("Year:", spotlight_song$charted_year)),
      p(str_c("Genre(s):", spotlight_song$genres)),
      p(str_c("Popularity:", spotlight_song$popularity)),
      
      link <- str_c("https://open.spotify.com/embed/track/",spotlight_song$track_id,"?utm_source=generator")
    )
  
  })
  
  # Top Artists/Albums Logic
  filtered_artists <- reactive({
    combined_artists_tracks %>%
      filter(charted_year == input$selected_year) %>%
      group_by(artist_name, genres) %>%
      summarise(avg_popularity = round(mean(popularity, na.rm = TRUE), 1),
                total_tracks = n(), .groups = "drop") %>%
      arrange(desc(avg_popularity))
  })
  
  filtered_albums <- reactive({
    combined_albums_tracks %>%
      filter(charted_year == input$selected_year) %>%
      group_by(album_name, album_type) %>%
      summarise(total_tracks = max(total_tracks),
                release_date = first(release_date),
                avg_track_duration_sec = round(mean(track_duration_ms, na.rm = TRUE) / 1000, 1),
                .groups = "drop") %>%
      arrange(release_date)
  })
  
  output$artist_table <- renderDT({ datatable(filtered_artists(), options = list(pageLength = 10), rownames = FALSE) })
  output$album_table  <- renderDT({ datatable(filtered_albums(),  options = list(pageLength = 10), rownames = FALSE) })
  
  # Dynamic Track Selectors
  output$artist_selector <- renderUI({
    choices <- combined_artists_tracks %>% filter(charted_year == input$track_year) %>% distinct(artist_name) %>% arrange(artist_name)
    selectInput("selected_artist", "Select Artist:", choices = choices$artist_name)
  })
  
  output$album_selector <- renderUI({
    choices <- combined_albums_tracks %>% filter(charted_year == input$track_year) %>% distinct(album_name) %>% arrange(album_name)
    selectInput("selected_album", "Select Album:", choices = choices$album_name)
  })
  
  output$artist_tracks_plot <- renderPlotly({
    req(input$selected_artist)
    df <- combined_artists_tracks %>% filter(charted_year == input$track_year, artist_name == input$selected_artist)
    p <- ggplot(df, aes(x = reorder(track_name, popularity), y = popularity, fill = as.factor(explicit))) +
      geom_bar(stat = "identity") + coord_flip() +
      labs(title = str_c("Tracks by", input$selected_artist), x = "Track Name", y = "Popularity", fill = "Explicit") +
      theme_minimal()
    ggplotly(p)
  })
  
  output$album_tracks_plot <- renderPlotly({
    req(input$selected_album)
    df <- combined_albums_tracks %>% filter(charted_year == input$track_year, album_name == input$selected_album)
    p <- ggplot(df, aes(x = reorder(track_name, popularity), y = popularity, fill = as.factor(track_explicit))) +
      geom_bar(stat = "identity") + coord_flip() +
      labs(title = str_c("Tracks from Album:", input$selected_album), x = "Track Name", y = "Popularity", fill = "Explicit") +
      theme_minimal()
    ggplotly(p)
  })
  
  # Genre Tab
  output$genre_scatter <- renderPlotly({
    req(input$selected_genres)
    df <- combined_artists_tracks %>% separate_rows(genres, sep = ",\\s*") %>% filter(genres %in% input$selected_genres) %>%
      mutate(charted_year = as.factor(charted_year), hover_text = str_c("Artist:", artist_name, "\nTrack:", track_name, "\nGenre:", genres, "\nYear:", charted_year))
    p <- ggplot(df, aes(x = charted_year, y = genres, text = hover_text)) +
      geom_jitter(alpha = 0.6, color = "#1DB954", width = 0.3, height = 0.2) +
      labs(title = "Specific Genres by Year", x = "Year", y = "Specific Genre") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  # Years Since Release
  output$years_release_plot <- renderPlotly({
    df <- combined_artists_tracks %>%
      filter(!is.na(years_since_release), years_since_release >= input$years_range[1], years_since_release <= input$years_range[2]) %>%
      mutate(hover_text = str_c("Artist:", artist_name, "\nTrack:", track_name, "\nYears Since Release:", round(years_since_release, 1), "\nPopularity:", popularity))
    p <- ggplot(df, aes(x = years_since_release, y = popularity, text = hover_text)) +
      geom_point(alpha = 0.6, color = "#1DB954") +
      labs(title = "Track Popularity vs. Years Since Release", x = "Years Since Release", y = "Popularity") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  # Track Duration
  output$duration_artist_selector <- renderUI({ selectInput("duration_artist", "Select Artist:", choices = sort(unique(combined_artists_tracks$artist_name))) })
  output$duration_album_selector <- renderUI({ selectInput("duration_album", "Select Album:", choices = sort(unique(combined_albums_tracks$album_name))) })
  
  output$duration_artist_plot <- renderPlotly({
    req(input$duration_artist)
    df <- combined_artists_tracks %>% filter(artist_name == input$duration_artist) %>% mutate(duration_min = track_duration_ms / 60000) %>% filter(duration_min >= input$duration_range[1], duration_min <= input$duration_range[2])
    p <- ggplot(df, aes(x = duration_min, y = popularity, text = str_c("Track:", track_name, "\nDuration:", round(duration_min, 2), "min\nPopularity:", popularity))) +
      geom_point(alpha = 0.7, color = "#1DB954") +
      labs(title = str_c("Popularity vs. Duration for", input$duration_artist), x = "Track Duration (Minutes)", y = "Popularity") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  output$duration_album_plot <- renderPlotly({
    req(input$duration_album)
    df <- combined_albums_tracks %>% filter(album_name == input$duration_album) %>% mutate(duration_min = track_duration_ms / 60000) %>% filter(duration_min >= input$duration_range[1], duration_min <= input$duration_range[2])
    p <- ggplot(df, aes(x = duration_min, y = popularity, text = str_c("Track:", track_name, "\nArtist:", track_artists, "\nDuration:", round(duration_min, 2), "min\nPopularity:", popularity))) +
      geom_point(alpha = 0.7, color = "#1DB954") +
      labs(title = str_c("Popularity vs. Duration for Album:", input$duration_album), x = "Track Duration (Minutes)", y = "Popularity") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  # Number of Tracks in Album
  output$album_tracks_count_plot <- renderPlotly({
    req(input$tracks_year)
    album_counts <- combined_albums_tracks %>%
      filter(charted_year == input$tracks_year) %>%
      group_by(album_name, track_artists) %>%
      summarise(num_tracks = n(), .groups = "drop") %>%
      arrange(desc(num_tracks)) %>%
      mutate(hover_text = str_c("Album: ", album_name, "\nArtist(s): ", track_artists, "\nTracks: ", num_tracks))
    p <- ggplot(album_counts, aes(x = reorder(album_name, num_tracks), y = num_tracks, text = hover_text)) +
      geom_bar(stat = "identity", fill = "#1DB954") + coord_flip() +
      labs(title = str_c("Number of Tracks per Album in", input$tracks_year), x = "Album Name", y = "Number of Tracks") +
      theme_minimal() +
      theme(axis.text.y = element_text(angle = 45, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
  # Tracks with Features Tab
  output$features_album_selector <- renderUI({
    choices <- combined_albums_tracks %>% filter(charted_year == input$features_year) %>% distinct(album_name) %>% arrange(album_name)
    selectInput("features_album", "Select Album:", choices = choices$album_name)
  })
  
  output$featured_tracks_plot <- renderPlotly({
    req(input$features_album)
    df <- combined_albums_tracks %>%
      filter(charted_year == input$features_year, album_name == input$features_album) %>%
      mutate(has_feature = str_detect(tolower(track_name), "feat\\.|with"),
             feature_label = ifelse(has_feature, "With Feature", "No Feature"))
    p <- ggplot(df, aes(x = reorder(track_name, popularity), y = popularity, fill = feature_label,
                        text = str_c("Track: ", track_name, "\nPopularity: ", popularity, "\nFeature: ", feature_label))) +
      geom_bar(stat = "identity") +
      coord_flip() +
      labs(title = paste("Tracks from", input$features_album), x = "Track Name", y = "Popularity", fill = "Has Feature") +
      theme_minimal() +
      theme(axis.text.y = element_text(angle = 0, hjust = 1))
    ggplotly(p, tooltip = "text")
  })
  
  # New Album Releases Tab Logic
  output$new_release_date_plot <- renderPlotly({
    df <- new_releases_combined %>%
      filter(release_date >= input$release_date_range[1], release_date <= input$release_date_range[2])
    p <- ggplot(df, aes(x = release_date, y = popularity, text = paste("Track:", track_name, "\nArtist:", track_artists))) +
      geom_point(alpha = 0.6, color = "#1DB954") +
      labs(title = "Popularity vs. Release Date", x = "Release Date", y = "Popularity") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  output$new_release_album_plot <- renderPlotly({
    req(input$selected_new_albums)
    df <- new_releases_combined %>% filter(album_name %in% input$selected_new_albums)
    p <- ggplot(df, aes(x = reorder(track_name, popularity), y = popularity, fill = album_name,
                        text = paste("Track:", track_name, "\nPopularity:", popularity))) +
      geom_bar(stat = "identity") + coord_flip() +
      labs(title = "Popularity by Track (Selected Albums)", x = "Track Name", y = "Popularity", fill = "Album") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
  
  output$new_release_track_plot <- renderPlotly({
    req(input$selected_new_tracks)
    df <- new_releases_combined %>%
      filter(track_name %in% input$selected_new_tracks) %>%
      mutate(duration_min = track_duration_ms / 60000)
    p <- ggplot(df, aes(x = duration_min, y = popularity, text = paste("Track:", track_name, "\nDuration:", round(duration_min, 2), "min\nPopularity:", popularity))) +
      geom_point(alpha = 0.7, color = "#1DB954") +
      labs(title = "Popularity vs. Duration (Selected Tracks)", x = "Track Duration (Minutes)", y = "Popularity") +
      theme_minimal()
    ggplotly(p, tooltip = "text")
  })
}

# Run App ----
shinyApp(ui, server)


