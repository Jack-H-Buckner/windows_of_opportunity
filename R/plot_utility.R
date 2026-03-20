source("R/theme.R")

df <- read_csv("data/baseline.csv", show_col_types = FALSE)

# Read alternative utility from the data (U_delta when window is closed and delta_plus == 0
# equals U_0 minus fixed costs; instead use the constant Ū from parameters)
# We back it out: when delta_plus == 0, U_delta = U_0 - c_f/(1-Q). But simpler to just
# identify U_bar as the threshold where the window closes.
# Actually, Ū is a parameter — we can infer it from where the window closes on the insured curve.
# For robustness, just use the value from parameters: Ū = 1.5
U_bar <- 1.5

# Identify window boundaries
window_rows <- df %>% filter(window_open)
if (nrow(window_rows) > 0) {
  p_open  <- min(window_rows$p_t)
  p_close <- max(window_rows$p_t)
  t_open  <- min(window_rows$t)
  t_close <- max(window_rows$t)
}

# Find where uninsured drops below U_bar
unins_below <- df %>% filter(U_0 < U_bar)
if (nrow(unins_below) > 0) {
  p_adapt_start <- min(unins_below$p_t)
  t_adapt_start <- min(unins_below$t)
} else {
  p_adapt_start <- p_close
  t_adapt_start <- t_close
}

# ── Left panel: utility vs probability ──────────────────────────────────────

p1 <- ggplot(df, aes(x = p_t)) +
  # Window of opportunity (grey)
  annotate("rect",
           xmin = p_open, xmax = p_close,
           ymin = -Inf, ymax = Inf,
           fill = "grey50", alpha = 0.1) +
  # Window of adaptation (purple)
  annotate("rect",
           xmin = p_adapt_start, xmax = p_close,
           ymin = -Inf, ymax = Inf,
           fill = "purple", alpha = 0.1) +
  # Utility curves
  geom_line(aes(y = U_0, color = "Uninsured"), linewidth = 0.8) +
  geom_line(aes(y = U_delta, color = "Insured"), linewidth = 0.8) +
  geom_hline(aes(yintercept = U_bar, color = "Alternative"), linetype = "dashed", linewidth = 0.8) +
  scale_color_manual(
    values = c("Uninsured" = col_uninsured, "Insured" = col_insured, "Alternative" = col_alternative),
    breaks = c("Uninsured", "Insured", "Alternative")
  ) +
  coord_cartesian(xlim = c(0, 0.5)) +
  labs(x = "Loss probability (p)", y = "Utility") +
  theme_pub

# ── Right panel: utility vs time ────────────────────────────────────────────

p2 <- ggplot(df, aes(x = t)) +
  # Window of opportunity (grey)
  annotate("rect",
           xmin = t_open, xmax = t_close,
           ymin = -Inf, ymax = Inf,
           fill = "grey50", alpha = 0.1) +
  # Window of adaptation (purple)
  annotate("rect",
           xmin = t_adapt_start, xmax = t_close,
           ymin = -Inf, ymax = Inf,
           fill = "purple", alpha = 0.1) +
  # Utility curves
  geom_line(aes(y = U_0, color = "Uninsured"), linewidth = 0.8) +
  geom_line(aes(y = U_delta, color = "Insured"), linewidth = 0.8) +
  geom_hline(aes(yintercept = U_bar, color = "Alternative"), linetype = "dashed", linewidth = 0.8) +
  scale_color_manual(
    values = c("Uninsured" = col_uninsured, "Insured" = col_insured, "Alternative" = col_alternative),
    breaks = c("Uninsured", "Insured", "Alternative")
  ) +
  coord_cartesian(xlim = c(2020, 2100)) +
  labs(x = "Year", y = "Utility") +
  theme_pub

# ── Combine and save ────────────────────────────────────────────────────────

fig <- p1 + p2 + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave("figures/utility_window.png", fig, dpi = 400, width = 7, height = 3)
cat("Saved figures/utility_window.png\n")
