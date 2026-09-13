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
  

  dplyr::filter(
    is.na(D_INTERVIEW) | !duplicated(D_INTERVIEW)
  ) |> 
  
  dplyr::mutate(
    # removing possible duplicated data entries
    dplyr::across(
      c(Q224:Q232, Q238, Q250:Q252),
      as.numeric
    ),
    # flipping the axis of the variables so the correlations can be uniformly interpreted
    dplyr::across(
      c(Q224, Q228, Q229, Q232, Q238),
      \(x) 5 - x
    )
  )

# CORRELATONS
## 

correlation_results <- correlation::correlation(
  data = clean_data,
  select = c("Q224", "Q225", "Q226", "Q227", "Q228", "Q229", "Q230", "Q231", "Q232"),
  select2 = c("Q238", "Q250", "Q251", "Q252"),
  method = "spearman",
  p_adjust = "holm"
)

correlation_heatmap <- ggplot(
  data = as.data.frame(correlation_results),
  aes(
    x = Parameter1,
    y = Parameter2,
    fill = rho
  ) 
) +
geom_tile(color = "white") +
geom_text(
  aes(
    label = sprintf("%.2f", rho)
  )
) + 
scale_fill_gradient2(
  low = "#B35806",
  mid = "white",
  high = "#2166AC",
  midpoint = 0,
  limits = c(-1, 1),
  name = "Spearman RHO"
) +
labs(
  x = "Attitudes toward democracy",
  y = "Perceptions about integrity in Elections"
) +
theme_minimal()

correlation_heatmap