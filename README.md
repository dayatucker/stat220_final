# stat220_final
Repo for final project for Stat220

## Files
- combined.R: makes graphs from all_tracks dataset
- combinedplaylists.Rmd: gets all top songs from 2014-2024
- explicit.R: makes bar graph of all explicit songs from 2014-2024
- final_proj_sketch.Rmd: turn in for project sketch
- final_proj_checkin.R: shiny of Rmd ^^
- followers_popularity.R: makes a plot that shows followers v. popularity for each song
- test.R: gets arists & playlists data and combines into 1 dataset to make a shiny (Doesnt work rn)
- topartists.R: gets all_tracks dataset and displays as shiny interactive

## Datasets
### all_tracks
Top 10 songs from top 10 artists in 2024
- (chr) track name
- (chr) album name
- (int) popularity score (number out of 100 calculated by algorithm based on # plays and how recent they are)
- (chr) artist name
- (bool) explicit
- (int) duration of track in milliseconds

### arists_data
Top 10 most streamed artists from 2024
- (chr) artist name
- (chr) genre (this is a bad variable, do not use)
- (int) popularity in number of followers
