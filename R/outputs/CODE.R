# PACKAGES AND INITIALIZATION
if (!require("pacman")) 
  install.packages("pacman")
library(pacman)

pacman::p_load(
  "haven",
  "here",
  "tidyverse",
  "correlation"
)

here::i_am("R/outputs/CODE.R")

RAW_DATA_FILE <- here(
  "world_values_survey_data/raw_data",
  "WVS_Wave_7_South_Korea_Stata_v5.1.dta"
)

raw_data <- read_dta(RAW_DATA_FILE)

# DOWNSIZING THE DATA SET TO ONLY THE REQUIRED VARIABLES
clean_data <- raw_data |> 

  dplyr::select(
    D_INTERVIEW,
    Q224:Q232,
    Q238,
    Q250:Q252,
    W_WEIGHT
  ) |> 
  
  # removing possible duplicated data entries
  dplyr::filter(
    is.na(D_INTERVIEW) | !duplicated(D_INTERVIEW)
  )

# CORRELATONS
## 

cor.test(
  x = clean_data$Q229, 
  y = clean_data$Q252, 
  method = "spearman", 
  exact = FALSE)

correlation::correlation(
  data = clean_data,
  select = c("Q224", "Q225", "Q226", "Q227", "Q228", "Q229", "Q230", "Q231", "Q232"),
  select2 = c("Q238", "Q250", "Q251", "Q252"),
  method = "spearman",
  p_adjust = "holm"
)
