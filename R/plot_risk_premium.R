source("R/theme.R")

df <- read_csv("data/baseline.csv", show_col_types = FALSE)

# ── Left panel: loss probability vs time ────────────────────────────────────

p1 <- ggplot(df, aes(x = t, y = p_t)) +
  geom_line(color = col_uninsured, linewidth = 0.8) +
  labs(x = "Year", y = "Loss probability (p)") +
  theme_pub

# ── Right panel: premium and expected claims vs time ────────────────────────

df_long <- df %>%
  select(t, premium, expected_claims) %>%
  tidyr::pivot_longer(cols = c(premium, expected_claims),
                      names_to = "variable", values_to = "value") %>%
  mutate(variable = case_when(
    variable == "premium"         ~ "Premium",
    variable == "expected_claims" ~ "Expected claims"
  ))

p2 <- ggplot(df_long, aes(x = t, y = value, color = variable)) +
  geom_line(linewidth = 0.8) +
  scale_color_manual(
    values = c("Premium" = col_insured, "Expected claims" = col_uninsured)
  ) +
  labs(x = "Year", y = "Cost") +
  theme_pub

# ── Combine and save ────────────────────────────────────────────────────────

fig <- p1 + p2 + plot_layout(guides = "collect") &
  theme(legend.position = "bottom")

ggsave("figures/risk_premium.png", fig, dpi = 400, width = 7, height = 3)
cat("Saved figures/risk_premium.png\n")
