# Import datasets
library(tidyverse)
library(httr2)
library(httr)
library(stringr)
library(scales)


# API Setup + Token
client_id <- readLines("spotify_client_id.txt")
client_secret <- readLines("spotify_client_secret.txt")

get_spotify_token <- function(client_id, client_secret) {
  resp <- request("https://accounts.spotify.com/api/token") |>
    req_auth_basic(client_id, client_secret) |>
    req_body_form(grant_type = "client_credentials") |>
    req_method("POST") |>
    req_perform()
  
  resp_body_json(resp)$access_token
}

token <- get_spotify_token(client_id, client_secret)


# Function to get the artist and other information
get_artists_data <- function(artist_ids, token) {
  artist_chunks <- split(artist_ids, ceiling(seq_along(artist_ids) / 50))
  
  map_dfr(artist_chunks, function(ids_chunk) {
    req <- request("https://api.spotify.com/v1/artists") |>
      req_url_query(ids = paste(ids_chunk, collapse = ",")) |>
      req_headers(Authorization = paste("Bearer", token))
    
    resp <- req_perform(req)
    content <- resp_body_json(resp, simplifyVector = FALSE)
    
    map_dfr(content$artists, function(artist) {
      tibble(
        artist_id = artist$id,
        artist_name = artist$name,
        genres = str_c(artist$genres, collapse = ", "),
        popularity = artist$popularity,
        followers = artist$followers$total,
        artist_url = artist$external_urls$spotify
      )
    })
  })
}


# Function to include the top tracks of the artists
get_artist_top_tracks <- function(artist_id, token) {
  url <- paste0("https://api.spotify.com/v1/artists/", artist_id, "/top-tracks?market=US")
  
  req <- request(url) |>
    req_headers(Authorization = paste("Bearer", token))
  
  resp <- req_perform(req)
  content <- resp_body_json(resp, simplifyVector = FALSE)
  
  map_dfr(content$tracks, function(track) {
    release_date <- track$album$release_date
    release_year <- as.numeric(substr(release_date, 1, 4))
    tibble(
      track_name = track$name,
      track_id = track$id,
      album_name = track$album$name,
      popularity = track$popularity,
      track_duration_ms = track$duration_ms,
      explicit = track$explicit,
      artist_id = artist_id,
      release_year = release_year
    )
  })
}


# Function to create multiple datasets by year of the top tracks from top artists
merge_artist_data <- function(artist_ids, charted_year){
  artists_data_temp <- get_artists_data(artist_ids, token)
  all_tracks_temp <- map_dfr(artist_ids, get_artist_top_tracks, token = token)
  all_tracks_temp <- all_tracks_temp |>
    left_join(artists_data_temp %>% select(artist_id, artist_name, genres),
              by = "artist_id") |>
    mutate(
      charted_year = charted_year,
      years_since_release = charted_year - release_year
    )
  return(all_tracks_temp)
}


# Artist id lists
artist_ids_2018 <- c(
  "3TVXtAsR1Inumwj472S9r4", # Drake
  "246dkjvS1zLTtiykXe5h60", # Post Malone
  "15UsOTVnJzReFVN1VCnxy4", # XXXTENTACION
  "1vyhD5VmyZ7KMfW5gqLgo5", # J Balvin
  "6eUKZXaKkcviH0Ku9w2n3V"  # Ed Sheeran
)

artist_ids_2019 <- c(
  "246dkjvS1zLTtiykXe5h60", # Post Malone
  "6eUKZXaKkcviH0Ku9w2n3V", # Ed Sheeran
  "6qqNVTkY8uBg9cP3Jd7DAH", # Billie Eilish
  "66CXWjxzNUsdJxJ2JdwvnR", # Ariana Grande
  "4q3ewBCX7sLwd24euuV69X"  # Bad Bunny
)

artist_ids_2020 <- c(
  "4q3ewBCX7sLwd24euuV69X", # Bad Bunny
  "3TVXtAsR1Inumwj472S9r4", # Drake
  "1vyhD5VmyZ7KMfW5gqLgo5", # J Balvin
  "4MCBfE4596Uoi2O4DtmEMz", # Juice WRLD
  "1Xyo4u8uXC1ZmMpatF05PJ"  # The Weeknd
)

artist_ids_2021 <- c(
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "3Nrfpe0tUJi4K4DXYWgMUX",  # BTS
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "1uNFoZAHBGtllmzznpCI3s"   # Justin Bieber
)

artist_ids_2022 <- c(
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "1Xyo4u8uXC1ZmMpatF05PJ",  # The Weeknd
  "3Nrfpe0tUJi4K4DXYWgMUX"   # BTS
)

artist_ids_2023 <- c(
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "1Xyo4u8uXC1ZmMpatF05PJ",  # The Weeknd
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "12GqGscKJx3aE4t07u7eVZ",  # Peso Pluma
  "2LRoIwlKmHjgvigdNGBHNo",  # Feid
  "0Y5tJX1MQlPlqiwlOH1tJY",  # Travis Scott
  "7tYKF4w9nC0nq9CsPZTHyP",  # SZA
  "790FomKkXshlbRYZFtlgla",  # Karol G
  "00FQb4jTyendYWaN8pK0wa"   # Lana Del Rey
)

artist_ids_2024 <- c(
  "06HL4z0CvFAxyc27GXpf02",  # Taylor Swift
  "1Xyo4u8uXC1ZmMpatF05PJ",  # The Weeknd
  "4q3ewBCX7sLwd24euuV69X",  # Bad Bunny
  "3TVXtAsR1Inumwj472S9r4",  # Drake
  "6qqNVTkY8uBg9cP3Jd7DAH",  # Billie Eilish
  "0Y5tJX1MQlPlqiwlOH1tJY",  # Travis Scott
  "12GqGscKJx3aE4t07u7eVZ",  # Peso Pluma
  "5K4W6rqBFWDnAN6FQUkS6x",  # Kanye West
  "66CXWjxzNUsdJxJ2JdwvnR",  # Ariana Grande
  "2LRoIwlKmHjgvigdNGBHNo"   # Feid
)


# Merge track data with artist names
all_tracks_2018 <- merge_artist_data(artist_ids_2018, 2018)
all_tracks_2019 <- merge_artist_data(artist_ids_2019, 2019)
all_tracks_2020 <- merge_artist_data(artist_ids_2020, 2020)
all_tracks_2021 <- merge_artist_data(artist_ids_2021, 2021)
all_tracks_2022 <- merge_artist_data(artist_ids_2022, 2022)
all_tracks_2023 <- merge_artist_data(artist_ids_2023, 2023)
all_tracks_2024 <- merge_artist_data(artist_ids_2024, 2024)


# Combine all years (artists data)
combined_artists_tracks <- bind_rows(
  all_tracks_2018,
  all_tracks_2019,
  all_tracks_2020,
  all_tracks_2021,
  all_tracks_2022,
  all_tracks_2023,
  all_tracks_2024
)


# Collecting IDs for Top Albums from 2018 to 2024
album_ids_2018 <- c(
  "1ATL5GLyefJaxhQzSPVrLX", # Scorpion - Drake
  "6trNtQUgC8cgbWcqoMYkOR", # beerbons & bentleys - Post Malone
  "2Ti79nwTsont5ZHfdxIzAm", # ? - XXXTENTACION
  "2vlhlrgMaXqcnhRqIEV9AP", # Dua Lipa - Dua Lipa
  "3T4tUhGYeRNVUGevb0wThu"  # ÷ - Ed Sheeran
)

album_ids_2019 <- c(
  "0S0KGZnfBGSIssfF54WSJh", # WHEN WE ALL FALL ASLEEP, WHERE DO WE GO? – Billie Eilish
  "4g1ZRSobMefqF6nelkgibi", # Hollywood’s Bleeding – Post Malone
  "2fYhqwDWXjbpjaIJPEfKFw", # thank u, next – Ariana Grande
  "3oIFxDIo2fwuk4lwCmFZCx", # No.6 Collaborations Project – Ed Sheeran
  "0xzScN8P3hQAz3BT3YYX5w"  # Shawn Mendes – Shawn Mendes
)

album_ids_2020 <- c(
  "5lJqux7orBlA1QzyiBGti1", # YHLQMDLG - Bad Bunny
  "4yP0hdKOZPNshxUOjY0cZj", # After Hours - The Weeknd
  "4g1ZRSobMefqF6nelkgibi", # Hollywood's Bleeding - Post Malone
  "7xV2TzoaVc0ycW7fwBwAml", # Fine Line - Harry Styles
  "7fJJK56U9fHixgO0HQkhtI"  # Future Nostalgia - Dua Lipa
)

album_ids_2021 <- c(
  "6s84u2TUpR3wdUv4NgKA2j", # SOUR - Olivia Rodrigo
  "7fJJK56U9fHixgO0HQkhtI", # Future Nostalgia - Dua Lipa
  "5dGWwsZ9iB2Xc3UKR0gif2", # Justice - Justin Bieber
  "32iAEBstCjauDhyKpGjTuq", # = - Ed Sheeran
  "4XLPYMERZZaBzkJg0mkdvO"  # Planet Her - Doja Cat
)

album_ids_2022 <- c(
  "3RQQmkQEvNCY4prGKE6oc5", # Un Verano Sin Ti - Bad Bunny
  "5r36AJ6VOJtp00oxSkBZ5h", # Harry's House - Harry Styles
  "6s84u2TUpR3wdUv4NgKA2j", # SOUR - Olivia Rodrigo
  "32iAEBstCjauDhyKpGjTuq", # = - Ed Sheeran
  "4XLPYMERZZaBzkJg0mkdvO"  # Planet Her - Doja Cat
)

album_ids_2023 <- c(
  "3RQQmkQEvNCY4prGKE6oc5", # Un Verano Sin Ti - Bad Bunny
  "151w1FgRZfnKZA9FEcg9Z3", # Midnights - Taylor Swift
  "07w0rG5TETcyihsEIZR3qG", # SOS - SZA
  "2ODvWsOgouMbaA5xf0RkJe", # Starboy - The Weeknd
  "4kS7bSuU0Jm9LYMosFU2x5", # MAÑANA SERÁ BONITO - KAROL G
  "6i7mF7whyRJuLJ4ogbH2wh", # One Thing at a Time - Morgan Wallen
  "1NAmidJlEaVgA3MpcPFYGq", # Lover - Taylor Swift
  "7txGsnDSqVMoRl6RQ9XyZP", # HEROES & VILLAINS - Metro Boomin
  "4jox3ip1I39DFC2B7R5qLH", # GÉNESIS - Peso Pluma
  "5r36AJ6VOJtp00oxSkBZ5h"  # Harry's House - Harry Styles
)

album_ids_2024 <- c(
  "5H7ixXZfsNMGbIE5OBSpcb", # THE TORTURED POETS DEPARTMENT: THE ANTHOLOGY - Taylor Swift 
  "7aJuG4TFXa2hmE4z1yxc3n", # HIT ME HARD AND SOFT - Billie Eilish 
  "3iPSVi54hsacKKl1xIR2eH", # Short n’ Sweet - Sabrina Carpenter 
  "4kS7bSuU0Jm9LYMosFU2x5", # MAÑANA SERÁ BONITO - Karol G
  "5EYKrEDnKhhcNxGedaRQeK", # eternal sunshine - Ariana Grande
  "64LU4c1nfjz1t4VnGhagcg", # 1989 (Taylor’s Version) - Taylor Swift
  "07w0rG5TETcyihsEIZR3qG", # SOS - SZA
  "1NAmidJlEaVgA3MpcPFYGq", # Lover - Taylor Swift
  "168CdR21lfn0TTyw1Pkdcm", # Fireworks & Rollerblades - Benson Boone
  "2ODvWsOgouMbaA5xf0RkJe"  # Starboy - The Weeknd  
)


# Collecting album data for a given year via function
get_album_data <- function(album_ids, token) {
  album_chunks <- split(album_ids, ceiling(seq_along(album_ids) / 20))
  
  map_dfr(album_chunks, function(ids_chunk) {
    req <- request("https://api.spotify.com/v1/albums") |>
      req_url_query(ids = paste(ids_chunk, collapse = ",")) |>
      req_headers(Authorization = paste("Bearer", token))
    
    resp <- req_perform(req)
    content <- resp_body_json(resp, simplifyVector = FALSE)
    
    map_dfr(content$albums, function(album) {
      tibble(
        album_id = album$id,
        album_name = album$name,
        release_date = album$release_date,
        total_tracks = album$total_tracks,
        popularity = album$popularity,
        album_type = album$album_type
      )
    })
  })
}


# Collecting track data for a given album via function
get_album_tracks <- function(album_id, token) {
  url <- paste0("https://api.spotify.com/v1/albums/", album_id, "/tracks")
  req <- request(url) |>
    req_headers(Authorization = paste("Bearer", token))
  resp <- req_perform(req)
  content <- resp_body_json(resp, simplifyVector = FALSE)
  
  map_dfr(content$items, function(track) {
    tibble(
      album_id = album_id,
      track_id = track$id,
      track_name = track$name,
      track_number = track$track_number,
      track_artists = str_c(map_chr(track$artists, "name"), collapse = ", "),
      track_duration_ms = track$duration_ms,
      track_explicit = track$explicit
    )
  })
}


# For loop for creating album_data, album_track_data, and combined_data for years 2018 to 2024

# Loop through each year to create album_data_YYYY, album_tracks_YYYY, combined_YYYY, and add charted_year
years <- 2018:2024

# Loop through each year to create album_data_YYYY and album_tracks_YYYY
for (year in years) {
  # Get the album_ids for the current year
  album_ids <- get(str_c("album_ids_", year))
  
  # Create album_data_YYYY
  assign(
    str_c("album_data_", year),
    get_album_data(album_ids, token)
  )
  
  # Create album_tracks_YYYY
  assign(
    str_c("album_tracks_", year),
    map_dfr(album_ids, get_album_tracks, token = token)
  )
  
  # Create combined_YYY
  assign(
    str_c("combined_", year), 
    left_join(get(str_c("album_data_", year)), get(str_c("album_tracks_", year)), by = "album_id")
  )
  
  # Add charted_year column to combined_YYYY
  assign(
    str_c("combined_", year),
    get(str_c("combined_", year)) %>% mutate(charted_year = year)
  )
}

combined_albums_tracks <- bind_rows(
  combined_2018,
  combined_2019,
  combined_2020,
  combined_2021,
  combined_2022,
  combined_2023,
  combined_2024
)

# Column for number of features on a song
combined_albums_tracks <- combined_albums_tracks %>%
  mutate(features = str_count(track_artists, ","))


# Get a page of new releases
get_new_releases <- function(token, country = "US", limit = 50, offset = 0) {
  url <- "https://api.spotify.com/v1/browse/new-releases"
  
  req <- request(url) |>
    req_url_query(country = country, limit = limit, offset = offset) |>
    req_headers(Authorization = paste("Bearer", token))
  
  resp <- req_perform(req)
  content <- resp_body_json(resp, simplifyVector = FALSE)
  
  map_dfr(content$albums$items, function(album) {
    tibble(
      album_id = album$id,
      album_name = album$name,
      artist_name = str_c(map_chr(album$artists, "name"), collapse = ", "),
      release_date = album$release_date,
      total_tracks = album$total_tracks,
      album_type = album$album_type,
      album_url = album$external_urls$spotify
    )
  })
}

# Get multiple pages of new releases
get_all_new_releases <- function(token, country = "US", max_albums = 100) {
  pages <- ceiling(max_albums / 50)
  map_dfr(seq_len(pages), function(i) {
    offset <- (i - 1) * 50
    get_new_releases(token, country = country, limit = 50, offset = offset)
  }) |> head(max_albums)
}

years <- 2018:2024

for (year in years) {
  album_ids <- get(str_c("album_ids_", year))
  
  assign(str_c("album_data_", year), get_album_data(album_ids, token))
  
  assign(str_c("album_tracks_", year),
         map_dfr(album_ids, get_album_tracks, token = token))
  
  combined_df <- left_join(
    get(str_c("album_data_", year)),
    get(str_c("album_tracks_", year)),
    by = "album_id"
  )
  
  combined_df <- combined_df %>%
    mutate(charted_year = as.integer(substr(release_date, 1, 4)))
  
  assign(str_c("combined_", year), combined_df)
}


# Get latest new releases
new_releases <- get_all_new_releases(token, max_albums = 100)

# Get detailed album info
new_album_data <- get_album_data(new_releases$album_id, token)

# Get track data from albums
new_album_tracks <- map_dfr(new_releases$album_id, get_album_tracks, token = token)

# Merge album + track + new release metadata
new_releases_combined <- new_album_tracks |>
  left_join(new_album_data %>% select(album_id, release_date, total_tracks, popularity, album_type), 
            by = "album_id") |>
  left_join(new_releases %>% select(album_id, album_name, artist_name, album_url), 
            by = "album_id") |>
  mutate(charted_year = as.integer(substr(release_date, 1, 4)))

new_releases_combined <- new_releases_combined %>%
  mutate(
    release_date = case_when(
      release_date == "year" ~ str_c(release_date, "-01-01"),
      release_date == "month" ~ str_c(release_date, "-01"),
      TRUE ~ release_date
    ),
    release_date = as.Date(release_date)
  )


# Write the combined dataset for artists to a CSV file
write_csv(combined_artists_tracks, "data/combined_artists_tracks_2018_2024.csv")

# Write combined dataset for albums to a CSV file
write_csv(combined_albums_tracks, "data/combined_albums_tracks_2018_2024.csv")

# Write new releases dataset (most updated from Spotify)
write_csv(new_releases_combined, "data/new_releases_combined.csv")


