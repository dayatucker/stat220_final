# Spotify Music Explorer 2018-2024
This repository contains the final project for STAT220, which explores trends in Spotify music data from 2018 to 2024. The project includes data wrangling, visualization, and a Shiny web app for interactive exploration.

## Files
- `data_prep.R`: Script for cleaning and wrangling raw datasets. Produces combined datasets for analysis and visualization.
- `app.R`:
- `main.Rmd`: Main file for graphs and visualizations for the report
- `/data/`: Directory containing all processed datasets in .csv format
- `/www/`:
- `final_proj_sketch.Rmd`: Initial project sketch submitted during the proposal phase.
- `.txt` files: Delete later

## Datasets
#### `all_tracks_*.csv`: Multiple files, each containing track-level data for a specific year (2018–2024)
Includes:
- track_name
- album_name
- popularity
- track_duration_ms
- explicit
- artist_id
- artist_name
- year

#### `combined_artists_tracks_2018_2024.csv`: Artist-level summary generated from track data
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

#### `combined_albums_tracks_2018_2024.csv`: Aggregated dataset joining track and album-level info across all years (2018-2024)
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
- track_explicit
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
- track_explicit
- release_date
- total_tracks
- popularity
- album_type
- album_name
- artist_name
- album_url
- charted_year

## Resources
Set up a Shiny app to use shinyjs: (https://www.rdocumentation.org/packages/shinyjs/versions/2.1.0/topics/useShinyjs)
## Authors
- Aubrey Tran
- Daya Tucker
- Nicholas Chang
  
*(STAT220 Final - Spring 2025)*
