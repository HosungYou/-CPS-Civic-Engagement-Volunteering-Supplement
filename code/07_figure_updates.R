# ==============================================================================
# 07_figure_updates.R
# Generate improved figures for NVSQ manuscript
#
# 1. LPA Profile Heatmap (new Figure 2)
# 2. Fix lpa_vol_rate_profile_gen.png (profile names on x-axis)
# ==============================================================================

library(tidyverse)
library(ggplot2)

# --- Load Data ----------------------------------------------------------------
profile_summary <- readRDS("data/profile_summary.rds")
data_lpa <- readRDS("data/cev_with_profiles.rds")

cat("Profile summary:\n")
print(profile_summary, width = Inf)

# Profile name mappings
profile_names <- c(
  "1" = "Isolated Disengaged",
  "2" = "Politically Aware Isolated",
  "3" = "Socially Active Non-Donors",
  "4" = "Mainstream Donors",
  "5" = "Activist Boycotters",
  "6" = "Fully Engaged"
)

profile_names_wrap <- c(
  "1" = "Isolated\nDisengaged",
  "2" = "Politically Aware\nIsolated",
  "3" = "Socially Active\nNon-Donors",
  "4" = "Mainstream\nDonors",
  "5" = "Activist\nBoycotters",
  "6" = "Fully\nEngaged"
)

# ==============================================================================
# FIGURE: LPA Profile Heatmap
# ==============================================================================

heatmap_data <- profile_summary %>%
  select(profile_ordered, boycott_pct, puboff_pct, polconv_mean,
         socialize_mean, membership_mean, donated_pct) %>%
  pivot_longer(-profile_ordered, names_to = "indicator", values_to = "value") %>%
  mutate(
    indicator_label = case_when(
      indicator == "boycott_pct" ~ "Boycotting\n(%)",
      indicator == "puboff_pct" ~ "Contact\nOfficials (%)",
      indicator == "polconv_mean" ~ "Political\nConv. (1\u20136)",
      indicator == "socialize_mean" ~ "Socialization\n(1\u20136)",
      indicator == "membership_mean" ~ "Org.\nMembership",
      indicator == "donated_pct" ~ "Charitable\nGiving (%)"
    ),
    profile_label = profile_names_wrap[as.character(profile_ordered)]
  ) %>%
  group_by(indicator) %>%
  mutate(value_norm = (value - min(value)) / (max(value) - min(value) + 1e-10)) %>%
  ungroup() %>%
  mutate(
    display_value = case_when(
      indicator %in% c("boycott_pct", "puboff_pct", "donated_pct") ~
        sprintf("%.0f%%", value),
      indicator %in% c("polconv_mean", "socialize_mean") ~
        sprintf("%.1f", value),
      indicator == "membership_mean" ~ sprintf("%.2f", value)
    )
  )

# Order indicators
indicator_order <- c(
  "Socialization\n(1\u20136)", "Political\nConv. (1\u20136)",
  "Org.\nMembership", "Boycotting\n(%)",
  "Contact\nOfficials (%)", "Charitable\nGiving (%)"
)
heatmap_data$indicator_label <- factor(heatmap_data$indicator_label,
                                        levels = indicator_order)

# Order profiles by engagement level (low to high, bottom to top)
profile_order_wrap <- c(
  "Isolated\nDisengaged", "Politically Aware\nIsolated",
  "Socially Active\nNon-Donors", "Mainstream\nDonors",
  "Activist\nBoycotters", "Fully\nEngaged"
)
heatmap_data$profile_label <- factor(heatmap_data$profile_label,
                                      levels = rev(profile_order_wrap))

# Determine text color (dark on light, white on dark)
heatmap_data <- heatmap_data %>%
  mutate(text_color = ifelse(value_norm > 0.65, "white", "black"))

p_heatmap <- ggplot(heatmap_data,
       aes(x = indicator_label, y = profile_label, fill = value_norm)) +
  geom_tile(color = "white", linewidth = 1.5) +
  geom_text(aes(label = display_value, color = text_color),
            size = 4, fontface = "bold", show.legend = FALSE) +
  scale_color_identity() +
  scale_fill_gradient2(
    low = "#F7F7F7", mid = "#7FBADC", high = "#08519C",
    midpoint = 0.5, guide = "none"
  ) +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(size = 10, face = "bold", lineheight = 1.1),
    axis.text.y = element_text(size = 11, face = "bold", lineheight = 1.1),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(face = "bold", size = 14, hjust = 0),
    plot.subtitle = element_text(size = 11, hjust = 0, color = "gray40"),
    plot.margin = margin(10, 15, 10, 10)
  ) +
  labs(
    title = "Civic Engagement Profile Characteristics",
    subtitle = "Indicator Means by Latent Profile (CPS-CEV 2017\u20132023, N = 201,168)"
  )

ggsave("figures/lpa_profile_heatmap.png", p_heatmap,
       width = 10, height = 6, dpi = 300)
cat("Saved: figures/lpa_profile_heatmap.png\n")


# ==============================================================================
# FIGURE: Volunteering Rate by Profile and Generation (with profile names)
# ==============================================================================

gen_colors <- c(
  "Gen Z"       = "#E63946",
  "Millennial"  = "#457B9D",
  "Gen X"       = "#2A9D8F",
  "Boomer"      = "#E9C46A",
  "Silent"      = "#264653"
)

profile_vol <- data_lpa %>%
  group_by(profile_ordered, generation) %>%
  summarise(vol_rate = mean(volunteered, na.rm = TRUE) * 100,
            n = n(), .groups = "drop") %>%
  filter(n >= 50) %>%
  mutate(profile_name = profile_names[as.character(profile_ordered)])

profile_name_order <- c(
  "Isolated Disengaged", "Politically Aware Isolated",
  "Socially Active Non-Donors", "Mainstream Donors",
  "Activist Boycotters", "Fully Engaged"
)
profile_vol$profile_name <- factor(profile_vol$profile_name,
                                    levels = profile_name_order)

p_vol <- ggplot(profile_vol,
       aes(x = profile_name, y = vol_rate, fill = generation)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.85) +
  scale_fill_manual(values = gen_colors, name = "Generation") +
  theme_minimal(base_size = 13) +
  theme(
    axis.text.x = element_text(size = 9, angle = 25, hjust = 1),
    legend.position = "top",
    plot.title = element_text(face = "bold", size = 14),
    plot.subtitle = element_text(size = 11, color = "gray40")
  ) +
  labs(
    title = "Volunteering Rate by Profile and Generation",
    subtitle = "CPS-CEV 2017\u20132023",
    x = "", y = "Volunteering Rate (%)"
  )

ggsave("figures/lpa_vol_rate_profile_gen.png", p_vol,
       width = 12, height = 7, dpi = 300)
cat("Saved: figures/lpa_vol_rate_profile_gen.png\n")

cat("\nAll figure updates complete.\n")
