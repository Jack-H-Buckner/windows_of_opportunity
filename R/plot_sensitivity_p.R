source("R/theme.R")

df <- read_csv("data/sensitivity_p.csv", show_col_types = FALSE)

# Sort by absolute elasticity for each panel
df_open <- df %>%
  mutate(param_label = reorder(param_label, abs(elasticity_open)))

df_close <- df %>%
  mutate(param_label = reorder(param_label, abs(elasticity_close)))

# ── Left panel: beginning of window ─────────────────────────────────────────

p1 <- ggplot(df_open, aes(x = elasticity_open, y = param_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_segment(aes(xend = 0, yend = param_label), color = "grey70", linewidth = 0.5) +
  geom_point(size = 3, color = col_insured) +
  labs(x = "Elasticity (proportional effect)", y = NULL,
       title = "Beginning of window") +
  theme_pub

# ── Right panel: end of window ──────────────────────────────────────────────

p2 <- ggplot(df_close, aes(x = elasticity_close, y = param_label)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey50") +
  geom_segment(aes(xend = 0, yend = param_label), color = "grey70", linewidth = 0.5) +
  geom_point(size = 3, color = col_uninsured) +
  labs(x = "Elasticity (proportional effect)", y = NULL,
       title = "End of window") +
  theme_pub

# ── Combine and save ────────────────────────────────────────────────────────

fig <- p1 + p2

ggsave("figures/sensitivity_p.png", fig, dpi = 400, width = 7, height = 3.5)
cat("Saved figures/sensitivity_p.png\n")
