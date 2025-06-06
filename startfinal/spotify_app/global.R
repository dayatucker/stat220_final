# global.R
# Contains global objects and data setup.
# Loaded once when the app starts, shared across ui and server.

# Load libraries
library(shiny)
library(shinyjs)
library(tidyverse)
library(DT)
library(plotly)
library(tidytext)

# Load Data 
combined_artists_tracks <- read_csv("data/combined_artists_tracks_2018_2024.csv")
combined_albums_tracks <- read_csv("data/combined_albums_tracks_2018_2024.csv")
new_releases_combined <- read_csv("data/new_releases_combined.csv")
lyrics_words <- read_csv("data/lyrics_words.csv")

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

# Ensure track_name and artist_name match formatting between datasets
lyrics_words <- lyrics_words |>
  left_join(
    combined_artists_tracks |> 
      select(track_name, artist_name, charted_year) |> 
      distinct(),
    by = c("track_name", "artist_name")
  )

# top 10 most common words by genre
lyrics_by_genre <- lyrics_words |>
  inner_join(combined_artists_tracks, by = c("track_name", "artist_name"))

word_counts_by_genre <- lyrics_by_genre |>
  count(genres, word, sort = TRUE)

top_words_by_genre <- word_counts_by_genre |>
  filter(!is.na(genres)) |>
  group_by(genres) |>
  slice_max(order_by = n, n = 10) |>
  ungroup()


