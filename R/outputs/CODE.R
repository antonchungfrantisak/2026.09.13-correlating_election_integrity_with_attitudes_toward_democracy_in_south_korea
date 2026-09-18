# PACKAGES AND INITIALIZATION ----
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

# DOWNSIZING THE DATA SET TO ONLY THE REQUIRED VARIABLES ----
clean_data <- raw_data |> 
  dplyr::select(
    D_INTERVIEW,
    Q224:Q232, # election integrity
    Q238, # measures of democracy 
    Q250:Q252, # measure of democracy
    Q260, # sex
    W_WEIGHT,
    Q262, # age
    Q275R, # education
    Q240, # political orientation
    Q223 # preference for political party
  ) |> 
  
    # removing possible duplicated data entries
  dplyr::filter( 
    is.na(D_INTERVIEW) | !duplicated(D_INTERVIEW)
  ) |> 
  
  # making the variables numerics
  dplyr::mutate(
    dplyr::across(
      c(Q224:Q232, Q238, Q250:Q252, Q260),
      as.numeric
    )

  )

## flipping the axis of the variables so the correlations can be uniformly interpreted ----
uniformly_cleaned_data <- clean_data |> 
  dplyr::mutate(
    dplyr::across(
      c(Q224, Q228, Q229, Q232, Q238),
      \(x) 5 - x
    )
  )
# CORRELATONS ----

correlation_results <- correlation::correlation(
  data = uniformly_cleaned_data,
  select = c("Q224", "Q225", "Q226", "Q227", "Q228", "Q229", "Q230", "Q231", "Q232"),
  select2 = c("Q238", "Q250", "Q251", "Q252"),
  method = "spearman",
  p_adjust = "holm"
)

## creating the heat map ----
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


# DENSITY PLOT ----

## PREPARING DATA FOR THE PLOT ----

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

## GENERATING GRAPHS ----

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

## FAIR PRACTICES IN ELECTIONS ----

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

## MALPRACTICES IN ELECTIONS ----

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

# BAR CHART FOR EACH INDIVIDUAL MEASURE DESCRIPTIVE STATISTICS ----

## BAR PLOT FUNCTION ----

create_bar_plot <- function(
  data, y, fill, colors, label_data = data, include_overall = TRUE
) {
  # Get the question's label for the title.
  y_name <- all.vars(substitute(y))[1]
  y_label <- attr(label_data[[y_name]], "label")
  if (is.null(y_label)) y_label <- y_name

  # Keep the selected question and subgroup.
  # Remove missing answers to the question.
  data <- dplyr::transmute(
    data,
    response = {{ y }},
    plot_group = {{ fill }}
  ) |>
    dplyr::filter(!is.na(response))

  # Keep the subgroup order specified in your factor().
  group_order <- if (is.factor(data$plot_group)) {
    levels(data$plot_group)
  } else {
    unique(as.character(data$plot_group))
  }

  data <- dplyr::mutate(
    data,
    plot_group = as.character(plot_group)
  )

  # Automatically add the overall group and its grey colour.
  if (include_overall) {
    data <- dplyr::bind_rows(
      dplyr::mutate(data, plot_group = "All respondents"),
      data
    )

    group_order <- c("All respondents", group_order)
    colors <- c("All respondents" = "#A0A0A0", colors)
  }

  # Calculate percentages separately within each group.
  # Keep categories with zero responses.
  plot_data <- data |>
    dplyr::filter(!is.na(plot_group)) |>
    dplyr::mutate(
      plot_group = factor(plot_group, levels = group_order)
    ) |>
    dplyr::count(plot_group, response, .drop = FALSE) |>
    dplyr::group_by(plot_group) |>
    dplyr::mutate(group_n = sum(n)) |>
    dplyr::filter(group_n > 0) |>
    dplyr::mutate(proportion = n / group_n) |>
    dplyr::ungroup()

  if (nrow(plot_data) == 0) stop("No valid responses to plot.")

  # Automatically calculate the valid counts for the caption.
  group_counts <- dplyr::distinct(
    plot_data, plot_group, group_n
  )

  caption <- paste0(
    "Valid responses: ",
    paste(
      group_counts$plot_group,
      group_counts$group_n,
      sep = " = ",
      collapse = "; "
    ),
    "."
  )

  # Use the same positioning for bars and labels.
  dodge <- position_dodge(width = 0.9, orientation = "y")

  ggplot(
    plot_data,
    aes(
      x = proportion,
      y = response,
      fill = plot_group
    )
  ) +
    geom_col(position = dodge) +

    geom_text(
      aes(
        x = proportion / 2,
        label = ifelse(
          proportion < .05,
          "",
          scales::percent(proportion, accuracy = 0.1)
        )
      ),
      position = dodge,
      color = "white",
      size = 3.5,
      show.legend = FALSE
    ) +

    scale_x_continuous(
      limits = c(0, 1),
      labels = scales::label_percent()
    ) +

    scale_fill_manual(values = colors) +

    labs(
      title = y_label,
      x = "Percentage within each group",
      y = NULL,
      fill = "Group",
      caption = caption
    )
}

## Q224 BY SEX ----

q224_bar_plot <- create_bar_plot(
  data = clean_data,
  label_data = raw_data,

  y = factor(
    Q224,
    levels = c(1, 2, 3, 4),
    labels = c(
      "Very Often",
      "Fairly Often",
      "Not Often",
      "Not At All Often"
    )
  ),

  fill = factor(
    Q260,
    levels = c(1, 2),
    labels = c("Men", "Women")
  ),

  colors = c(
    "Men" = "#355F4A",
    "Women" = "#72947F"
  )
)

q224_bar_plot
