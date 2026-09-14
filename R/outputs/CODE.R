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
    )

  )

# flipping the axis of the variables so the correlations can be uniformly interpreted
uniformly_cleaned_data <- clean_data |> 
  dplyr::mutate(
    dplyr::across(
      c(Q224, Q228, Q229, Q232, Q238),
      \(x) 5 - x
    )
  )
# CORRELATONS
## 

correlation_results <- correlation::correlation(
  data = uniformly_cleaned_data,
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
    label = paste0(
      sprintf("%.2f", rho),
      "\n",
      ifelse(
        p < 0.001,
        "p < .001",
        sprintf("p = %.3f", p)
      )
    )
  )
) +

scale_fill_gradient2(
  low = "#9006b3",
  mid = "white",
  high = "#21acaa",
  midpoint = 0,
  limits = c(-0.4, 0.4),
  breaks = c(-0.5, -0.25, 0, 0.25, 0.5),
  name = "Spearman's Correlation"
) +
labs(
  x = "Perceptions about integrity in elections",
  y = "Attitudes toward democracy",
  caption = "Holm-adjusted p-values: * p < .05; ** p < .01; *** p < .001."
) +
theme_minimal()

correlation_heatmap


# DENSITY PLOT

density_plot_data <- clean_data |> 
# correct format for the plot
  tidyr::pivot_longer(
    cols = Q224:Q232,
    names_to = "question_variable",
    values_to = "response"
  ) |> 
# mapping mal/fair practices
  dplyr::mutate(
    type = dplyr::if_else(
      question_variable %in% c("Q224", "Q228", "Q229", "Q232"),
      "Fair Practices in Elections",
      "Malpractices in Elections"
    ),
    # labels
    response = factor(
      response,
      levels = 1:4,
      labels = c(
        "Very Often",
        "Fairly Often",
        "Not Often",
        "Not At All Often"
      )
    )
  )

## GENERATING GRAPHS

create_density_plot <- function(data, x, y, group, color, colors) {
  density_plot <- ggplot(
    data,
    aes(
      x = {{ x }},
      y = {{ y }},
      group = {{ group }},
      color = {{ color }}
    )
  ) +

  geom_count(
    aes(
      size = after_stat(prop),
      fill = after_scale(scales::alpha(colour, 0.55))
    ),
    shape = 21,
    stroke = 0.4
  ) +
    
  scale_color_manual(
    values = colors
  ) +

  scale_size_area(
    max_size = 40,
    name = "<10% Legend",
    breaks = c(0.01, 0.05),
    labels = scales::label_percent(),
    limits = c(0, 1)
  ) +
    
  geom_text(
    stat = "sum",
    aes(
      group = {{ group }},
      size = stage(
        after_stat = prop,
        after_scale = size * 0.20
      ),
      label = after_stat(
        ifelse(
          prop < 0.01,
          "",
          scales::percent(prop, accuracy = 1)
        )
      )
    ),
    color = "black",
    show.legend = FALSE,
    fontface = "bold"
  ) +

  theme_classic(
    base_family = "Helvetica Neue",
    base_size = 12
  ) +
  theme(
  legend.position = "none"
  )
}

fair_practices_density_plot <- create_density_plot(
  data = dplyr::filter(
    density_plot_data,
    type == "Fair Practices in Elections"
  ),
  x = response,
  y = question_variable,
  group = question_variable,
  color = type,
  colors = c("Fair Practices in Elections" = "#648570")
)

fair_practices_density_plot

malpractices_density_plot <- create_density_plot(
  data = dplyr::filter(
    density_plot_data,
    type == "Malpractices in Elections"
  ),
  x = response,
  y = question_variable,
  group = question_variable,
  color = type,
  colors = c("Malpractices in Elections" = "#B66565")
)

malpractices_density_plot