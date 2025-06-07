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

# Load Data ----
combined_artists_tracks <- read_csv("data/combined_artists_tracks_2018_2024.csv")
combined_albums_tracks <- read_csv("data/combined_albums_tracks_2018_2024.csv")
new_releases_combined <- read_csv("data/new_releases_combined.csv")
lyrics_words <- read_csv("data/lyrics_words.csv")

# Song Spotlight ----

# Parse release year
combined_artists_tracks <- combined_artists_tracks |>
  mutate(release_year = as.integer(release_year))

# Popularity score
get_popularity_fire <- function(popularity) {
  if (popularity >= 95) return("🔥🔥🔥")
  if (popularity >= 90) return("🔥🔥")
  if (popularity >= 80) return("🔥")
  return("")
}

# Top Artist/Albums Tab ----
# Filtering logic — could move to global if reused across tabs
get_filtered_artists_year <- function(data, year) {
  data |>
    filter(charted_year == year) |>
    group_by(artist_name, genres, artist_id) |>
    summarise(
      avg_popularity = round(mean(popularity, na.rm = TRUE), 1),
      total_tracks = n(), .groups = "drop"
    ) |>
    arrange(desc(avg_popularity))
}

get_filtered_artists <- function(data, year) {
  data |>
    filter(charted_year == year) |>
    group_by(artist_name, genres) |>
    summarise(
      avg_popularity = round(mean(popularity, na.rm = TRUE), 1),
      .groups = "drop"
    ) |>
    arrange(desc(avg_popularity))
}

get_filtered_albums_year <- function(data, year) {
  data |>
    filter(charted_year == year) |>
    group_by(album_name, album_type, album_id) |>
    summarise(
      total_tracks = max(total_tracks),
      release_date = first(release_date),
      avg_track_duration_sec = round(mean(track_duration_ms, na.rm = TRUE) / 1000, 1),
      .groups = "drop"
    ) |>
    arrange(release_date)
}

get_filtered_albums <- function(data, year) {
  data |>
    filter(charted_year == year) |>
    group_by(album_name) |>
    summarise(
      total_tracks = max(total_tracks),
      release_date = first(release_date),
      avg_track_duration_sec = round(mean(track_duration_ms, na.rm = TRUE) / 1000, 1),
      .groups = "drop"
    ) |>
    arrange(release_date)
}

# Track Genre Tab ----

# Get all unique genres
genre_choices <- combined_artists_tracks |>
  separate_rows(genres, sep = ",\\s*") |>
  filter(!is.na(genres), genres != "") |>
  distinct(genres) |>
  arrange(genres) |>
  pull(genres)
# Randomly select 3 genres
selected_genres <- sample(genre_choices, 3)

# Lyric Analysis Tab ----

# Ensure track_name and artist_name match formatting between datasets
lyrics_words <- lyrics_words |>
  left_join(
    combined_artists_tracks |> 
      select(track_name, artist_name, charted_year) |> 
      distinct(),
    by = c("track_name", "artist_name")
  )

# Top 10 most common words by genre
lyrics_by_genre <- lyrics_words |>
  inner_join(combined_artists_tracks, by = c("track_name", "artist_name"))

word_counts_by_genre <- lyrics_by_genre |>
  count(genres, word, sort = TRUE)

top_words_by_genre <- word_counts_by_genre |>
  filter(!is.na(genres)) |>
  mutate(genres = ifelse(
    genres == "corrido, corridos tumbados, corridos bélicos, música mexicana, sad sierreño, banda, electro corridos",
    "corridos",
    genres
  )) |>
  group_by(genres) |>
  slice_max(order_by = n, n = 10) |>
  ungroup()

# Load sentiment lexicon
bing_sentiments <- get_sentiments("bing")

# Join lyrics with year
lyrics_by_year <- lyrics_words |>
  inner_join(combined_artists_tracks, by = c("track_name", "artist_name")) |>
  filter(!is.na(release_year))

# Join with sentiment lexicon
sentiment_by_year <- lyrics_by_year |>
  inner_join(bing_sentiments, by = "word") |>
  count(release_year, sentiment) |>
  pivot_wider(names_from = sentiment, values_from = n, values_fill = 0) |>
  mutate(net_sentiment = positive - negative) |>
  mutate(net_sentiment_prop = (positive - negative) / (positive + negative))

