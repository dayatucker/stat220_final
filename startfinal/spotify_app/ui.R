# ui.R
# Defines the user interface of the Shiny app.
# Contains layout, input controls, and output placeholders.

ui <- fluidPage(
  useShinyjs(),
  includeCSS("www/styles.css"),
  
  
  tags$head(
    # JavaScript to handle clicks outside sidebar
    tags$script(HTML("
      $(document).ready(function() {
        $(document).on('click', function(event) {
          var sidebar = $('#sidebar');
          var toggleBtn = $('#toggleSidebar');
          if (!sidebar.is(event.target) && sidebar.has(event.target).length === 0 && !toggleBtn.is(event.target)) {
            Shiny.setInputValue('closeSidebar', true);
          }
        });
      });
    ")),
    # Embed custom Spotify-style fonts
    tags$style(HTML("
            @font-face {
                font-family: 'SpotifyMix';
                src: url('/spotifymix.woff') format('woff');
            }
            @font-face {
                font-family: 'SpotifyMixBold';
                src: url('/spotifymixbold.woff') format('woff');
            }
            html * {
                font-family: 'SpotifyMix', Arial, sans-serif !important;
            }
            html h2, html h3, html h4, html h5 {
                font-family: 'SpotifyMixBold', Arial, sans-serif !important;
            }
        "))
  ),
  
  # Header
  div(
    class = "header-row",
    actionButton("toggleSidebar", "\u2630", 
                 style = "background-color: transparent; border: none; font-size: 40px; cursor: pointer; color: white;"),
    h3("Spotify Music Explorer 2018-2024", style = "display: inline-block; margin-left: 10px; vertical-align: middle;")
  ),
  
  # Sidebar navigation menu
  div(id = "sidebar",
      h3("Menu"),
      br(),
      radioButtons("nav", NULL, choices = c(
        "Info" = "info_tab",
        "Top Artists/Albums" = "artists",
        "Top Tracks" = "tracks",
        "Track Genre" = "genre",
        "Years Since Release" = "years",
        "Track Duration" = "duration",
        "Track Count by Album" = "track_count",
        "Tracks with Features" = "features",
        "New Album Releases 2024" = "new_releases",
        "Lyric Analysis" = "lyric_analysis")
      )
  ),

  # Main content area of the app
  div(id = "content",
      h3("🎵Random Song Spotlight🎵"),
      uiOutput("song_spotlight"),
      uiOutput("main_content")
)
)
