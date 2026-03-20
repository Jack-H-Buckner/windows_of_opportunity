library(ggplot2)
library(dplyr)
library(readr)
library(patchwork)

# Color palette
col_insured     <- "#2171B5"
col_uninsured   <- "#E6550D"
col_alternative <- "#31A354"

# Common theme
theme_pub <- theme_classic() +
  theme(
    text = element_text(size = 12),
    axis.text = element_text(size = 10),
    axis.title = element_text(size = 12),
    legend.position = "bottom",
    legend.title = element_blank(),
    legend.text = element_text(size = 12),
    legend.key.size = unit(1.2, "lines"),
    plot.margin = margin(5, 10, 5, 5)
  )
