
# load libraries
library(geniusr) # Documentation: https://github.com/ewenme/geniusr
library(dplyr)
library(stringr)
library(rvest)
library(purrr)
library(tidyverse)
library(tidytext)


combined_artists_tracks <- read_csv("stat220_final/startfinal/spotify_app/data/combined_artists_tracks_2018_2024.csv")
combined_albums_tracks <- read_csv("stat220_final/startfinal/spotify_app/data/combined_albums_tracks_2018_2024.csv")

# rename artist column to work with the function
combined_albums_tracks <- combined_albums_tracks |>
  rename(artist_name = track_artists)

# genius access token
client_access_token <- paste(readLines("client_access_token.txt"), collapse = "")
genius_token(client_access_token)

# helper function to clean lyrics
get_clean_lyrics <- function(url) {
  page <- read_html(url)
  
  lyrics_nodes <- page |> html_nodes("div[data-lyrics-container='true']")
  
  lines <- lyrics_nodes |>
    html_nodes(xpath = ".//text()") |>
    html_text(trim = TRUE) |>
    str_trim() |>
    keep(~ .x != "") |>
    str_replace_all("[()]", "") |> 
    str_squish()     
  
  lyrics_text <- paste(lines, collapse = " ")
  return(lyrics_text)
}

# function to pull lyrics from songs in datasets
get_lyrics <- function(tracks_data) {
  results <- vector("list", nrow(tracks_data))  # pre-allocate list
  
  for (i in seq_len(nrow(tracks_data))) {
    row <- tracks_data[i, ]
    if (is.na(row$artist_name) || is.na(row$track_name)) {
      next  # skip if missing
    }
    res <- search_song(row$track_name)
    if (!"artist_name" %in% colnames(res)) {
      warning(paste("No 'artist_name' column in search results for track:", row$track_name))
      lyrics <- NA_character_
    } else {
      song <- res |> filter(artist_name == row$artist_name)
      
      if (nrow(song) > 0) {
        lyrics <- get_clean_lyrics(song$song_lyrics_url[1])
      } else {
        lyrics <- NA_character_
      }
    } 
    
    results[[i]] <- tibble(
      track_name = row$track_name,
      artist_name = row$artist_name,
      lyrics = lyrics
    )
  }
  
  bind_rows(results)
}

artist_tracks_with_lyrics <- get_lyrics(combined_artists_tracks)
album_tracks_with_lyrics <- get_lyrics(combined_albums_tracks)

write_csv(artist_tracks_with_lyrics, "artist_tracks_with_lyrics.csv")
write_csv(album_tracks_with_lyrics, "album_tracks_with_lyrics.csv")

all_track_lyrics <- bind_rows(artist_tracks_with_lyrics, album_tracks_with_lyrics) |> 
  distinct(artist_name, track_name, lyrics, .keep_all = TRUE)

clean_lyrics <- function(text) {
  text |>
    str_replace("(?i).*?lyrics", "") |>         # Remove everything before "Lyrics" (case-insensitive)
    str_remove_all("\\[.*?\\]") |>              # Remove text in square brackets
    str_remove_all("[[:punct:]]") |>            # Remove punctuation
    str_to_lower() |>                           # Convert to lowercase (optional)
    str_squish()                                # Trim extra whitespace
}

lyrics_data_clean <- all_track_lyrics |>
  mutate(lyrics = if_else(is.na(lyrics), NA_character_, clean_lyrics(lyrics)))

write_csv(lyrics_data_clean, "data/all_track_lyrics.csv")

lyrics_words <- lyrics_data_clean |>
  unnest_tokens(word, lyrics)

data("stop_words") 

lyrics_words_filtered <- lyrics_words |>
  anti_join(stop_words, by = "word")

write_csv(lyrics_words_filtered, "data/lyrics_words.csv")








