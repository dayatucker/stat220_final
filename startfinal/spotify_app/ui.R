# ui.R
# Defines the user interface of the Shiny app.
# Contains layout, input controls, and output placeholders.

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
    
    /* Radio button container */
    #sidebar .radio {
      display: flex;
      flex-direction: column;
      gap: 8px;
    }
    
    #sidebar .radio input[type='radio'] {
      display: none;
    }
    
    #sidebar .radio label {
      display: block;
      background-color: #222;
      color: white;
      padding: 10px 15px;
      border-radius: 8px;
      cursor: pointer;
      transition: all 0.2s ease;
      border: 1px solid #444;
      font-size: 15px;
    }

    #sidebar .radio label:hover {
      background-color: #333;
    }

    #sidebar .radio input[type='radio']:checked + label {
      background-color: #007bff;
      color: white;
      font-weight: 500;
      border-color: #007bff;
    }

  "))
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
