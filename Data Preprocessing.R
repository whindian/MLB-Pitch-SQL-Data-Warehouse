### --- Term Project----
#CS779
#Summer 2 2022
#James Bloor
#preprocessing data to move into SQL
#load libs needed\
library(caret)
library(tidyverse)
library(tm)
library(stringdist)
library(proxy)
library(RecordLinkage)
library(proxy)   
library(wordcloud)
library(cluster)
library(stringi)
library(dendextend)
library(SnowballC)
library(textstem)
library(clusterCrit)
library("ape")
library(quanteda)
library(ggplot2)
library(plotly)
library(igraph)
library(textstem)
library(dplyr)
library(tidytext)
library(lsa)
library(e1071)
library(caTools)
library(caret)


#set wd
setwd("C:\\Users\\James Bloor\\Desktop\\BU\\779\\Project")
#load in game file
game_data_2019_raw <- read.csv("2019_games.csv", header = TRUE, sep = ",")
#at bats file
atBat_data_2019_raw <- read.csv("2019_atbats.csv", header = TRUE, sep = ",")
#pitches file
pitch_data_2019_raw <- read.csv("2019_pitches.csv", header = TRUE, sep = ",")
#player names file
player_names_raw <- read.csv("player_names.csv", header = TRUE, sep = ",")


#------games file, shave off unwanted columns and rename columns--------
#select columns desired
game_data_2019 <- game_data_2019_raw[c("g_id","home_team","away_team","home_final_score","away_final_score",
                                       "date","venue_name")]
game_data_2019 <- as.data.frame(game_data_2019)

#edit column names
names(game_data_2019)[names(game_data_2019) == 'g_id'] <- "game_id"

#------at bat file, shave off unwanted columns and rename columns--------
#select columns desired
atBat_data_2019 <- atBat_data_2019_raw[c("ab_id","g_id","batter_id","pitcher_id","inning","top","stand","p_throws","o","event")]
atBat_data_2019 <- as.data.frame(atBat_data_2019)

#edit column names
names(atBat_data_2019)[names(atBat_data_2019) == 'top'] <- "top_of_inning"
names(atBat_data_2019)[names(atBat_data_2019) == 'ab_id'] <- "at_bat_id"
names(atBat_data_2019)[names(atBat_data_2019) == 'g_id'] <- "game_id"
names(atBat_data_2019)[names(atBat_data_2019) == 'stand'] <- "batter_stance"
names(atBat_data_2019)[names(atBat_data_2019) == 'p_throws'] <- "pitcher_throws"
names(atBat_data_2019)[names(atBat_data_2019) == 'o'] <- "outs"

#------pitches file, shave off unwanted columns and rename columns--------
#select columns desired
pitch_data_2019 <- pitch_data_2019_raw[c("start_speed","end_speed","code","pitch_type","b_score","ab_id","b_count","s_count",
                                         "outs","pitch_num","on_1b","on_2b","on_3b")]
pitch_data_2019 <- as.data.frame(pitch_data_2019)

#edit column names
names(pitch_data_2019)[names(pitch_data_2019) == 'code'] <- "pitch_result"
names(pitch_data_2019)[names(pitch_data_2019) == 'b_score'] <- "batter_team_score"
names(pitch_data_2019)[names(pitch_data_2019) == 'ab_id'] <- "at_bat_id"
names(pitch_data_2019)[names(pitch_data_2019) == 'b_count'] <- "ball_count"
names(pitch_data_2019)[names(pitch_data_2019) == 's_count'] <- "strike_count"
names(pitch_data_2019)[names(pitch_data_2019) == 'pitch_num'] <- "at_bat_pitch_count"
#unique(atBat_data_2019$at_bat_id)

#create unique ID here
pitch_data_2019$pitch_id <-  paste0(pitch_data_2019$at_bat_id, "-", pitch_data_2019$at_bat_pitch_count)

#organize columns 
pitch_data_2019 <- pitch_data_2019[c("pitch_id","at_bat_id","start_speed","end_speed","pitch_result","pitch_type","batter_team_score",
                                         "ball_count","strike_count","outs","at_bat_pitch_count","on_1b","on_2b","on_3b")]


#------player file, shave off unwanted columns and rename columns--------
#select columns desired
player_names <- player_names_raw[c("id","first_name","last_name")]
player_names <- as.data.frame(player_names)

#edit column names
names(player_names)[names(player_names) == 'id'] <- "player_id"

#write four files out to folder desired 
setwd("C:\\Users\\James Bloor\\Desktop\\BU\\779\\Project\\SQL Tables upload")
write.csv(player_names,"PLAYERNAMES.csv", row.names=FALSE)
write.csv(pitch_data_2019,"PITCH.csv", row.names=FALSE)
write.csv(atBat_data_2019,"ATBAT.csv", row.names=FALSE)
write.csv(game_data_2019,"GAME.csv", row.names=FALSE)






