# Spotify Music Explorer 2018-2024 🎧
This repository contains the final project for STAT220.

[View the published app](https://nicholasjchang.shinyapps.io/spotify_app/)

For this project, we explored lyrical and musical trends using Spotify data from 2018 to 2024. To acquire the data, we used the Spotify API via the `spotifyr` package) to collect detailed information on tracks, albums, and artists. We also used the `geniusr` package for the Genius API to scrape song lyrics. We then wrangled this data by merging datasets, cleaning text (removing punctuation and annotations as well as parsing release dates and converted durations), reshaping long data for plotting, creating new features, and filtering out both English and Spanish stopwords for lyrical analysis. Futhermore, we parsed JSON from API into structured data. 

To visualize the data, we created a series of interactive plotly charts in R, including genre-based word frequency plots, sentiment trends over time, and track popularity patterns. The app is styled in a Spotify-inspired dark theme, complete with spotify colors and tooltip-enhanced plotly visuals for interactivity. Additionally, a "Random Song Spotlight" greets users when the app is launched. We used faceting, conditional filtering, and created custom scales. 

Finally, to communicate insights, we built an interactive Shiny dashboard, organized into 10 clearly labeled tabs, that allows users to explore patterns in music and lyrics across years and genres, making the analysis accessible and engaging. We organized the app into clearly labeled sections accessible via the left sidebar menu (click ☰ in the top left), wrote clear help text and labels, and included a dynamic title/subtitle system based on user input. This project aimed to better understand how musical success evolve over time and vary across genres.

### Key Features to Note:

- **Top Artists/Albums tab** – Selecting a row in the table dynamically loads the corresponding Spotify embed, allowing users to instantly preview top tracks by that artist or album without leaving the app.

- **Track Duration tab** – Visualizes the relationship between track length and popularity through an interactive scatterplot. Users can filter by artist to see whether shorter or longer songs tend to perform better.

- **Tracks with Features tab** – Detects collaborations by identifying phrases like “feat.” or “with” in track names, making it easy to explore featured tracks across albums.

- **Lyric Analysis tab** – Performs sentiment analysis on lyrics using the bing lexicon, highlighting how the emotional tone of common words has shifted over time.

- **App-wide design** – Features a cohesive dark mode Spotify theme, along with interactive tooltips.

## Files
- `data_prep.R`: Script for cleaning and wrangling raw track datasets. Produces combined datasets for analysis and visualization of track data
- `lyrics_data_prep.R`: Script extracts and cleans song lyrics from the Genius API to enable textual and sentiment analysis of lyrics associated with Spotify's top charting tracks
- `/spotify_app/`: Directory containing the full structure of the Shiny app
  - `/data/`: Directory containing all processed datasets in .csv format
  - `/www/`: Spotify-inspired dark theme styling
  - `global.R`: Loads data and shared functions used by both UI and server components
  - `server.R`: Server logic for all outputs
  - `ui.R`: Defines the user interface layout and inputs
- `main.Rmd`: Main file for graphs and visualizations for the report
- `final_proj_sketch.Rmd`: Initial project sketch submitted during the proposal phase

## Datasets
#### `all_tracks_*.csv`
This contains track-level data for each year from 2018 to 2024 with each file containing one row per track. Tracks are associated with artists released on Spotify and it provides core data on song popularity, duration, explicitness. This was obtained via the Spotify Web API.

- Includes:
  - track_name: Title of the song
  - album_name: Album where the track appears
  - popularity: Spotify-calculated popularity score (0–100)
  - track_duration_ms: Duration of the track in milliseconds
  - explicit: Whether the track is marked explicit (TRUE/FALSE)
  - artist_id: Unique Spotify ID for the artist
  - artist_name: Name of the artist
  - year: Year the track charted

#### `combined_artists_tracks_2018_2024.csv` 
This merges all yearly track-level files from 2018 to 2024 into a single dataset. Each row links songs to their artists and genre tags. This was originally obtained via the Spotify Web API and bound together to support cross/year analysis of music trends, artist performance, and content characteristics.

- Includes:
  - track_name: Title of the track
  - track_id: Unique Spotify ID for the track
  - album_name: Album the track appears on
  - popularity: Spotify-calculated popularity score (0–100)
  - track_duration_ms: Duration of the track in milliseconds
  - explicit: Whether the track is marked explicit (TRUE/FALSE)
  - artist_id: Unique Spotify ID for the artist
  - release_year: Year the track was originally released
  - artist_name: Name of the artist
  - genres: Comma-separated list of genres associated with the artist
  - charted_year: Year the track appeared on Spotify’s charts
  - years_since_release: Number of years between release and charting

#### `combined_albums_tracks_2018_2024.csv`
This is a aggregated dataset joining track and album-level info across all years (2018-2024). Songs grouped by album and artist and it enables information about album structure (like the number of tracks), duration, and feature patterns. This was obtained via the Spotify Web API.

- Includes:
  - album_id: Unique Spotify ID for the album
  - album_name: Album the track appears on
  - release_date: Year the track was originally released
  - total_tracks: Total number of tracks on the album
  - popularity: Spotify-calculated popularity score (0–100)
  - album_type: Type of album
  - track_id: Unique Spotify ID for the track
  - track_name: Title of the track
  - track_number: Position of the track on the album
  - track_artists: Artists associated with the track
  - track_duration_ms: Duration of the track in milliseconds
  - track_explicit: Whether the track is marked explicit (TRUE/FALSE)
  - charted_year: Year the track charted
  - features: Indicates if the track includes a featured artist

#### `new_releases_combined.csv`
This contains all new album and track releases in 2024, including both main and featured artists. It focuses on April 2024 only, ideal for understanding the release trends. This was obtained via the Spotify Web API.

- Includes:
  - album_id: Unique Spotify ID for the album
  - track_id: Unique Spotify ID for the track
  - track_name: Name of the track
  - track_number: Position of the track on the album
  - track_artists: Artists featured on the track
  - track_duration_ms: Duration of the track in milliseconds
  - track_explicit: Indicates if the track is explicit (TRUE/FALSE)
  - release_date: Official release date of the album
  - total_tracks: Total number of tracks on the album
  - popularity: Spotify-calculated popularity score (0–100)
  - album_type: Type of album
  - album_name: Title of album
  - artist_name: Primary artist associated with the album
  - album_url: Link to the album on Spotify
  - charted_year: Year the track charted

#### `all_track_lyrics.csv` 
This contains full, cleaned lyrics for each track (one row per song). It is tied to tracks spanning 2018–2024; used for analyzing lyrical trends across time.

- Includes:
  - track_name: Title of the track
  - artist_name: Name of the artist
  - lyrics: Full cleaned lyrics text for the track

#### `lyrics_words.csv`
This contains a tokenized version of the lyrics dataset — one row per word per track. Supports word frequency analysis, sentiment analysis, and tracking word trends over time.

- Includes:
  - track_name: Title of the track
  - artist_name: Name of the artist
  - word: A single tokenized word from the song's lyrics

## Resources
- Set up a Shiny app to use shinyjs: (https://www.rdocumentation.org/packages/shinyjs/versions/2.1.0/topics/useShinyjs)
- Spotify Web API: (https://developer.spotify.com/documentation/web-api)
- Spotify App: (https://open.spotify.com/)
- Spotify Wrapped Links: (https://newsroom.spotify.com/?s=wrapped)
- Lyrics: ([GitHub.com/ewenme/geniusr](https://github.com/ewenme/geniusr)) and (https://docs.genius.com/)
- Spotify Color Scheme: (https://developer.spotify.com/documentation/design#using-our-logo)
- R Color Palletes: (https://www.nceas.ucsb.edu/sites/default/files/2020-04/colorPaletteCheatsheet.pdf)
- Amanda Luby's Slides

## Authors
- Aubrey Tran
- Daya Tucker
- Nicholas Chang
  
*(STAT220 Final - Spring 2025)*
