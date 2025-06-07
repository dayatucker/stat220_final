# Spotify Music Explorer 2018-2024
This repository contains the final project for STAT220.

For this project, we explored lyrical and musical trends using Spotify data from 2018 to 2024. To acquire the data, we used the Spotify API (via the {spotifyr} package) to collect detailed information on tracks, albums, and artists, and an R wrapper for the Genius API to scrape song lyrics. We then wrangled this data by merging datasets, cleaning text (removing punctuation and annotations as well as parsing release dates and converted durations), reshaping long data for plotting, creating new features like has_feature, years_since_release, and weekday, and filtering out both English and Spanish stopwords to prepare the lyrics for analysis. Futhermore, we parsed JSON from API into structured data. To visualize the data, we created a series of interactive plotly charts in R, including genre-based word frequency plots, sentiment trends over time, and track popularity patterns. The app is styled in a Spotify-inspired dark theme, complete with spotify colors and tooltip-enhanced plotly visuals for interactivity. Additionally, a "Random Song Spotlight" greets users when the app is launched. We used faceting, conditional filtering, and created custom scales. Finally, to communicate insights, we built an interactive Shiny dashboard, organized into 10 clearly labeled tabs, that allows users to explore patterns in music and lyrics across years and genres, making the analysis accessible and engaging. We organized the app into clearly labeled sections accessible via the left sidebar menu (click ☰ in the top left), wrote clear help text and labels, and included a dynamic title/subtitle system based on user input. This project aimed to better understand how musical success evolve over time and vary across genres.

Key Features to Note:

Top Artists/Albums tab – Selecting a row in the table dynamically loads the corresponding Spotify embed, allowing users to instantly preview top tracks by that artist or album without leaving the app.

Track Duration tab – Visualizes the relationship between track length and popularity through an interactive scatterplot. Users can filter by artist to see whether shorter or longer songs tend to perform better.

Tracks with Features tab – Detects collaborations by identifying phrases like “feat.” or “with” in track names, making it easy to explore featured tracks across albums.

Lyric Analysis tab – Performs sentiment analysis on lyrics using the bing lexicon, highlighting how the emotional tone of common words has shifted over time.

App-wide design – Features a cohesive dark mode Spotify theme, along with interactive tooltips.

## Published App Link

## Files
- `data_prep.R`: Script for cleaning and wrangling raw datasets. Produces combined datasets for analysis and visualization
- `lyrics_data_prep.R`: Script extracts and cleans song lyrics from the Genius API to enable textual and sentiment analysis of lyrics associated with Spotify's top charting tracks
- `/spotify_app/`:
  - `/data/`: Directory containing all processed datasets in .csv format
  - `/www/`: Spotify-inspired dark theme styling
  - `global.R`: 
  - `server.R`: Server logic for all outputs
  - `ui.R`: UI layout
- `main.Rmd`: Main file for graphs and visualizations for the report
- `final_proj_sketch.Rmd`: Initial project sketch submitted during the proposal phase
- `.txt` files: **Need to be deleted from repo**

## Datasets
#### `all_tracks_*.csv`: Multiple files, each containing track-level data for a specific year (2018–2024).
Includes:
- track_name
- album_name
- popularity
- track_duration_ms
- explicit
- artist_id
- artist_name
- year

#### `combined_artists_tracks_2018_2024.csv`: Artist-level summary generated from track data.
Includes:
- track_name
- track_id
- album_name
- popularity
- track_duration_ms
- explicit
- artist_id
- release_year
- artist_name
- genres
- charted_year
- years_since_release

#### `combined_albums_tracks_2018_2024.csv`: Aggregated dataset joining track and album-level info across all years (2018-2024).
Includes:
- album_id
- album_name
- release_date
- total_tracks
- popularity
- album_type
- track_id
- track_name
- track_number
- track_artists
- track_duration_ms
- track_explicit (True/False)
- charted_year
- features

#### `new_releases_combined.csv`: Dataset of new music releases scraped from Spotify's API.
Includes:
- album_id
- track_id
- track_name
- track_number
- track_artists
- track_duration_ms
- track_explicit (True/False)
- release_date
- total_tracks
- popularity
- album_type
- album_name
- artist_name
- album_url
- charted_year

#### `all_track_lyrics.csv`: One row per song with cleaned full lyrics.
Includes:
- track_name
- artist_name
- lyrics

#### `lyrics_words.csv`: One row per word (token) per song for word-level analysis.
Includes:
- track_name
- artist_name
- word

## Navigate Repo:
Run `data_prep.R` and `lyrics_data_prep.R` first to load or update your dataset (optional and will take a while)???? 

**Does she need to?***

Go to `/spotify_app/` and run `global.R` and `ui.R`

Launch the app from `server.R`

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
