source("R/theme.R")

# ── Load data ───────────────────────────────────────────────────────────────

df_base <- read_csv("data/baseline.csv", show_col_types = FALSE)
df_sens <- read_csv("data/sensitivity_p.csv", show_col_types = FALSE)

U_bar <- 1.5

# Window boundaries
window_rows <- df_base %>% filter(window_open)
p_open  <- min(window_rows$p_t)
p_close <- max(window_rows$p_t)

# Where uninsured drops below U_bar
unins_below <- df_base %>% filter(U_0 < U_bar)
p_adapt_start <- if (nrow(unins_below) > 0) min(unins_below$p_t) else p_close

# ── Top panel: utility vs probability ───────────────────────────────────────

p_top <- ggplot(df_base, aes(x = p_t)) +
  annotate("rect",
           xmin = p_open, xmax = p_close,
           ymin = -Inf, ymax = Inf,
           fill = "grey50", alpha = 0.1) +
  annotate("rect",
           xmin = p_adapt_start, xmax = p_close,
           ymin = -Inf, ymax = Inf,
           fill = "purple", alpha = 0.1) +
  geom_line(aes(y = U_0, color = "Uninsured"), linewidth = 0.8) +
  geom_line(aes(y = U_delta, color = "Insured"), linewidth = 0.8) +
  geom_hline(aes(yintercept = U_bar, color = "Alternative"), linetype = "dashed", linewidth = 0.8) +
  scale_color_manual(
    values = c("Uninsured" = col_uninsured, "Insured" = col_insured, "Alternative" = col_alternative),
    breaks = c("Uninsured", "Insured", "Alternative")
  ) +
  coord_cartesian(xlim = c(0, 0.5)) +
  labs(x = "Loss probability (p)", y = "Utility") +
  theme_pub +
  theme(legend.position = "bottom")

# ── Bottom-left: sensitivity of window opening ──────────────────────────────

df_open <- df_sens %>%
  mutate(param_label = reorder(param_label, abs(elasticity_open)))

p_bl <- ggplot(df_open, aes(x = elasticity_open, y = param_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_segment(aes(xend = 0, yend = param_label), color = "grey70", linewidth = 0.5) +
  geom_point(size = 3, color = col_insured) +
  labs(x = "Elasticity (proportional effect)", y = NULL,
       title = "Beginning of window") +
  theme_pub +
  theme(legend.position = "none")

# ── Bottom-right: sensitivity of window closing ─────────────────────────────

df_close <- df_sens %>%
  mutate(param_label = reorder(param_label, abs(elasticity_close)))

p_br <- ggplot(df_close, aes(x = elasticity_close, y = param_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_segment(aes(xend = 0, yend = param_label), color = "grey70", linewidth = 0.5) +
  geom_point(size = 3, color = col_uninsured) +
  labs(x = "Elasticity (proportional effect)", y = NULL,
       title = "End of window") +
  theme_pub +
  theme(legend.position = "none")

# ── Stacked layout: utility on top, sensitivity below ────────────────────────

fig_stacked <- p_top / (p_bl + p_br) +
  plot_layout(heights = c(1, 1)) +
  plot_annotation(tag_levels = "A")

ggsave("figures/combined_p.png", fig_stacked, dpi = 400, width = 7, height = 6.5)
cat("Saved figures/combined_p.png\n")

# ── Row layout: all three panels side by side ────────────────────────────────

p_top_row <- p_top + theme(legend.justification = "center")
fig_row <- p_top_row + p_bl + p_br +
  plot_layout(widths = c(1.4, 1, 1)) +
  plot_annotation(tag_levels = "A")

ggsave("figures/combined_p_row.png", fig_row, dpi = 400, width = 10.5, height = 3.5)
cat("Saved figures/combined_p_row.png\n")
