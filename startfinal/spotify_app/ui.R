# ui.R
# Defines the user interface of the Shiny app.
# Contains layout, input controls, and output placeholders.

ui <- fluidPage(
  useShinyjs(),
  
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "www/styles.css")
  ),
  
  # Menu
  actionButton("toggleSidebar", "\u2630", 
               style = "background-color: transparent; border: none; font-size: 40px; cursor: pointer; color: white;"),
  
  div(id = "sidebar",
      h3("Menu"),
      radioButtons("nav", NULL, choices = c(
        "Info" = "info_tab",
        "Top Artists/Albums" = "artists",
        "Top Tracks" = "tracks",
        "Track Genre" = "genre",
        "Years Since Release" = "years",
        "Track Duration" = "duration",
        "Track Count by Album" = "track_count",
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
