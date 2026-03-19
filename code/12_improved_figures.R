# ==============================================================================
# 12_improved_figures.R
# Publication-Quality Figures for "Bowling Alone, Scrolling Together"
#
# Outputs:
#   1. figures/ame_first_step_forest.png  -- NEW: AME forest plot by generation
#   2. figures/pred_prob_improved.png     -- IMPROVED: predicted probability plot
#   3. figures/lpa_gen_dist_improved.png  -- IMPROVED: generational distribution
#   4. figures/lpa_heatmap_improved.png   -- IMPROVED: LPA heatmap w/ vol rate
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)
library(patchwork)
library(scales)

setwd("/Volumes/External SSD/Projects/Research/-CPS-Civic-Engagement-Volunteering-Supplement")

# --- Shared palette and theme ------------------------------------------------
gen_colors <- c(
  "Gen Z"      = "#E63946",
  "Millennial" = "#457B9D",
  "Gen X"      = "#2A9D8F",
  "Boomer"     = "#E9C46A",
  "Silent"     = "#264653"
)

# Muted versions for non-Gen Z
gen_colors_muted <- c(
  "Gen Z"      = "#E63946",
  "Millennial" = "#9BB8C9",
  "Gen X"      = "#8CC8BF",
  "Boomer"     = "#EDD9A0",
  "Silent"     = "#6D8790"
)

theme_pub <- function(base_size = 12) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      text = element_text(family = "sans"),
      plot.title = element_text(face = "bold", size = rel(1.15), hjust = 0,
                                margin = margin(b = 4)),
      plot.subtitle = element_text(size = rel(0.85), hjust = 0, color = "gray35",
                                   margin = margin(b = 10)),
      plot.caption = element_text(size = rel(0.7), hjust = 1, color = "gray50",
                                  margin = margin(t = 8)),
      axis.title = element_text(size = rel(0.9)),
      axis.text = element_text(size = rel(0.85)),
      legend.title = element_text(size = rel(0.85), face = "bold"),
      legend.text = element_text(size = rel(0.8)),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray92"),
      plot.margin = margin(12, 16, 12, 12)
    )
}

profile_names <- c(
  "1" = "Isolated Disengaged",
  "2" = "Politically Aware Isolated",
  "3" = "Socially Active Non-Donors",
  "4" = "Mainstream Donors",
  "5" = "Activist Boycotters",
  "6" = "Fully Engaged"
)

cat("Loading data...\n")
data <- readRDS("data/cev_clean.rds")
models <- readRDS("data/logistic_models.rds")
data_lpa <- readRDS("data/cev_with_profiles.rds")
profile_summary <- readRDS("data/profile_summary.rds")

# ==============================================================================
# 1. NEW: First Step AME Forest Plot
# ==============================================================================
cat("\n=== Figure: AME First Step Forest Plot ===\n")

# Reconstruct survey design for marginaleffects
options(survey.lonely.psu = "adjust")
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                 weights = ~VLSUPPWT, nest = TRUE, data = data)

m1 <- models$m1

# Extract AME for the first-step transition
cat("Computing AMEs...\n")
ame_m1 <- avg_slopes(m1, variables = "soc_factor", by = "generation")

ame_first_step <- ame_m1 %>%
  as.data.frame() %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, conf.low, conf.high) %>%
  mutate(
    generation = factor(generation,
                        levels = rev(c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent"))),
    is_genz = generation == "Gen Z",
    ame_label = sprintf("%+.1f pp", estimate * 100)
  )

cat("AME first step data:\n")
print(ame_first_step)

p_forest <- ggplot(ame_first_step,
                   aes(x = estimate, y = generation,
                       color = is_genz)) +
  # Reference line at 0

geom_vline(xintercept = 0, linetype = "dashed", color = "gray50", linewidth = 0.5) +
  # CI segments
  geom_segment(aes(x = conf.low, xend = conf.high,
                   y = generation, yend = generation),
               linewidth = 1.5, lineend = "round") +
  # Point estimates
  geom_point(size = 4.5) +
  # AME labels
  geom_text(aes(label = ame_label, x = conf.high),
            hjust = -0.25, size = 3.8, fontface = "bold", show.legend = FALSE) +
  # Colors
  scale_color_manual(values = c("TRUE" = "#E63946", "FALSE" = "#457B9D"),
                     guide = "none") +
  scale_x_continuous(
    labels = label_percent(),
    expand = expansion(mult = c(0.05, 0.2))
  ) +
  theme_pub(base_size = 13) +
  theme(
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(size = 12, face = ifelse(
      rev(c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")) ==
        rev(c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")),
      "plain", "plain"
    )),
    plot.title.position = "plot"
  ) +
  labs(
    title = "First Step Effect: Marginal Gain from Initial Socialization",
    subtitle = "Average Marginal Effect of 'Not at all' \u2192 'Few times/year' transition on volunteering probability",
    x = "Change in Volunteering Probability",
    y = NULL,
    caption = "CPS-CEV 2017\u20132023 | Survey-weighted logistic regression (Model 1) | Error bars = 95% CI"
  )

# Make Gen Z label bold via grob manipulation isn't straightforward;
# instead use a manual approach with the y-axis text
p_forest <- p_forest +
  theme(
    axis.text.y = element_text(
      size = 12,
      face = c("plain", "plain", "plain", "plain", "bold"),  # Silent, Boomer, Gen X, Millennial, Gen Z (top)
      color = c("gray40", "gray40", "gray40", "gray40", "#E63946")
    )
  )

ggsave("figures/ame_first_step_forest.png", p_forest,
       width = 9, height = 5, dpi = 300, bg = "white")
cat("Saved: figures/ame_first_step_forest.png\n")


# ==============================================================================
# 2. IMPROVED: Figure 1 - Predicted Probability Plot
# ==============================================================================
cat("\n=== Figure: Predicted Probability (Improved) ===\n")

# Compute predicted probabilities
pred_m1 <- predictions(m1,
  newdata = datagrid(soc_factor = unique, generation = unique),
  type = "response"
)

pred_df <- as_tibble(pred_m1) %>%
  select(soc_factor, generation, estimate, conf.low, conf.high) %>%
  mutate(
    soc_num = as.numeric(factor(soc_factor,
      levels = c("Not at all", "Few times/yr", "Once/mo",
                 "Few times/mo", "Few times/wk", "Daily")))
  )

cat("Predicted probabilities:\n")
print(pred_df %>% filter(generation == "Gen Z"), n = 10)

# Get Gen Z baseline
genz_baseline <- pred_df %>%
  filter(generation == "Gen Z", soc_factor == "Not at all") %>%
  pull(estimate)

# Get Gen Z values for plateau detection
genz_vals <- pred_df %>%
  filter(generation == "Gen Z") %>%
  arrange(soc_num)

# Endpoint labels -- position at the right end of each line
label_df <- pred_df %>%
  filter(soc_num == max(soc_num)) %>%
  mutate(
    label = generation,
    nudge = case_when(
      generation == "Gen Z"      ~  0.000,
      generation == "Millennial" ~  0.000,
      generation == "Gen X"      ~  0.000,
      generation == "Boomer"     ~  0.000,
      generation == "Silent"     ~  0.000
    )
  )

# Check actual values to see if labels will overlap
cat("\nEndpoint values for direct labels:\n")
print(label_df %>% select(generation, estimate))

p_pred <- ggplot(pred_df,
       aes(x = soc_factor, y = estimate,
           color = generation, group = generation)) +
  # Confidence ribbons
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high, fill = generation),
              alpha = 0.08, color = NA) +
  # Lines -- Gen Z thicker
  geom_line(aes(linewidth = generation)) +
  scale_linewidth_manual(values = c("Gen Z" = 1.8, "Millennial" = 0.9,
                                     "Gen X" = 0.9, "Boomer" = 0.9,
                                     "Silent" = 0.9),
                          guide = "none") +
  # Points
  geom_point(aes(size = generation), shape = 16) +
  scale_size_manual(values = c("Gen Z" = 3.5, "Millennial" = 2,
                                "Gen X" = 2, "Boomer" = 2, "Silent" = 2),
                     guide = "none") +
  # Direct line labels at right end
  geom_text(data = label_df,
            aes(label = label, y = estimate + nudge),
            hjust = -0.1, size = 3.5, fontface = "bold",
            show.legend = FALSE) +
  # --- ANNOTATION: "First Step" bracket ---
  annotate("segment",
           x = 1, xend = 2, y = -0.005, yend = -0.005,
           color = "gray30", linewidth = 0.6) +
  annotate("segment", x = 1, xend = 1, y = -0.005, yend = 0.005,
           color = "gray30", linewidth = 0.6) +
  annotate("segment", x = 2, xend = 2, y = -0.005, yend = 0.005,
           color = "gray30", linewidth = 0.6) +
  annotate("text", x = 1.5, y = -0.02,
           label = '"First Step"', fontface = "italic",
           size = 3.3, color = "gray30") +
  # --- ANNOTATION: Gen Z baseline ---
  annotate("text",
           x = 0.65, y = genz_baseline + 0.02,
           label = sprintf("Gen Z baseline\n%.1f%%", genz_baseline * 100),
           size = 3, color = "#E63946", fontface = "italic",
           hjust = 0, lineheight = 0.9) +
  # --- ANNOTATION: Gen Z Plateau ---
  # Find the plateau region (once/mo through daily)
  annotate("segment",
           x = 4.7, xend = 4.2,
           y = genz_vals$estimate[genz_vals$soc_num == 5] + 0.06,
           yend = genz_vals$estimate[genz_vals$soc_num == 5] + 0.01,
           arrow = arrow(length = unit(0.15, "cm"), type = "closed"),
           color = "#E63946", linewidth = 0.5) +
  annotate("text",
           x = 4.7,
           y = genz_vals$estimate[genz_vals$soc_num == 5] + 0.07,
           label = "Gen Z plateau",
           size = 3, color = "#E63946", fontface = "italic",
           hjust = 0.5) +
  # Colors
  scale_color_manual(values = gen_colors, guide = "none") +
  scale_fill_manual(values = gen_colors, guide = "none") +
  scale_y_continuous(labels = percent_format(accuracy = 1),
                     limits = c(-0.03, NA),
                     expand = expansion(mult = c(0, 0.05))) +
  scale_x_discrete(expand = expansion(add = c(0.3, 1.5))) +
  theme_pub(base_size = 13) +
  theme(
    axis.text.x = element_text(size = 10),
    plot.title.position = "plot"
  ) +
  labs(
    title = "Predicted Probability of Volunteering by Socialization and Generation",
    subtitle = "Survey-weighted logistic regression with interaction (Model 1)",
    x = "In-Person Socialization Frequency",
    y = "Predicted Probability of Volunteering",
    caption = "CPS-CEV 2017\u20132023, N = 201,168 | Direct labels replace legend"
  )

ggsave("figures/pred_prob_improved.png", p_pred,
       width = 11, height = 7, dpi = 300, bg = "white")
cat("Saved: figures/pred_prob_improved.png\n")


# ==============================================================================
# 3. IMPROVED: Figure 3 - Generational Distribution Across Profiles
# ==============================================================================
cat("\n=== Figure: Generational Distribution (Improved) ===\n")

gen_profile <- data_lpa %>%
  count(generation, profile_ordered) %>%
  group_by(generation) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup() %>%
  mutate(
    profile_label = profile_names[as.character(profile_ordered)],
    profile_label = factor(profile_label,
      levels = c("Isolated Disengaged", "Politically Aware Isolated",
                 "Socially Active Non-Donors", "Mainstream Donors",
                 "Activist Boycotters", "Fully Engaged"))
  )

# Rich color palette (replacing washed-out Set2)
profile_colors <- c(
  "Isolated Disengaged"        = "#BC4749",
  "Politically Aware Isolated" = "#E8875B",
  "Socially Active Non-Donors" = "#F2CC8F",
  "Mainstream Donors"          = "#81B29A",
  "Activist Boycotters"        = "#3D5A80",
  "Fully Engaged"              = "#264653"
)

# Compute Gen Z specific stats
genz_disconnected <- gen_profile %>%
  filter(generation == "Gen Z",
         profile_label %in% c("Isolated Disengaged", "Politically Aware Isolated")) %>%
  summarise(total = sum(pct)) %>%
  pull(total)

genz_engaged <- gen_profile %>%
  filter(generation == "Gen Z", profile_label == "Fully Engaged") %>%
  pull(pct)

cat(sprintf("Gen Z disconnected: %.1f%%\n", genz_disconnected))
cat(sprintf("Gen Z fully engaged: %.1f%%\n", genz_engaged))

# Compute cumulative positions for annotation
gen_profile_cum <- gen_profile %>%
  group_by(generation) %>%
  arrange(generation, profile_ordered) %>%
  mutate(
    cum_pct = cumsum(pct),
    mid_pct = cum_pct - pct / 2
  ) %>%
  ungroup()

# Get midpoints for the Gen Z "socially disconnected" bracket
genz_p1 <- gen_profile_cum %>%
  filter(generation == "Gen Z", profile_ordered == 1)
genz_p2 <- gen_profile_cum %>%
  filter(generation == "Gen Z", profile_ordered == 2)
genz_p6 <- gen_profile_cum %>%
  filter(generation == "Gen Z", profile_ordered == 6)

# Bracket: x position for Gen Z
genz_x_num <- which(levels(factor(data_lpa$generation,
  levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent"))) == "Gen Z")

p_dist <- ggplot(gen_profile,
       aes(x = factor(generation,
                       levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")),
           y = pct, fill = profile_label)) +
  geom_col(position = "stack", width = 0.72, color = "white", linewidth = 0.3) +
  # Bracket for "Socially Disconnected" on Gen Z
  annotate("segment",
           x = 0.64, xend = 0.64,
           y = 0, yend = genz_p2$cum_pct,
           color = "#BC4749", linewidth = 0.8) +
  annotate("segment",
           x = 0.64, xend = 0.68,
           y = 0, yend = 0,
           color = "#BC4749", linewidth = 0.8) +
  annotate("segment",
           x = 0.64, xend = 0.68,
           y = genz_p2$cum_pct, yend = genz_p2$cum_pct,
           color = "#BC4749", linewidth = 0.8) +
  annotate("text",
           x = 0.52, y = genz_p2$cum_pct / 2,
           label = sprintf("%.1f%%\nSocially\nDisconnected", genz_disconnected),
           size = 2.6, color = "#BC4749", fontface = "bold",
           hjust = 1, lineheight = 0.85) +
  # Annotation for Gen Z Fully Engaged
  annotate("segment",
           x = 0.64, xend = 0.68,
           y = genz_p6$cum_pct - genz_p6$pct, yend = genz_p6$cum_pct - genz_p6$pct,
           color = "#264653", linewidth = 0.6) +
  annotate("segment",
           x = 0.64, xend = 0.64,
           y = genz_p6$cum_pct - genz_p6$pct, yend = genz_p6$cum_pct,
           color = "#264653", linewidth = 0.6) +
  annotate("segment",
           x = 0.64, xend = 0.68,
           y = genz_p6$cum_pct, yend = genz_p6$cum_pct,
           color = "#264653", linewidth = 0.6) +
  annotate("text",
           x = 0.52, y = genz_p6$mid_pct,
           label = sprintf("%.1f%%\nFully\nEngaged", genz_engaged),
           size = 2.6, color = "#264653", fontface = "bold",
           hjust = 1, lineheight = 0.85) +
  scale_fill_manual(values = profile_colors, name = "Civic Engagement Profile") +
  scale_x_discrete(expand = expansion(add = c(1.2, 0.6))) +
  theme_pub(base_size = 13) +
  theme(
    legend.position = "bottom",
    legend.key.size = unit(0.5, "cm"),
    legend.text = element_text(size = 9),
    plot.title.position = "plot",
    axis.text.x = element_text(size = 11, face = c("bold", rep("plain", 4)),
                               color = c("#E63946", rep("gray30", 4)))
  ) +
  guides(fill = guide_legend(nrow = 2, byrow = FALSE)) +
  labs(
    title = "Civic Engagement Profile Distribution by Generation",
    subtitle = "Latent Profile Analysis with 6 indicators (CPS-CEV 2017\u20132023, N = 197,497)",
    x = NULL,
    y = "Percentage of Generation (%)",
    caption = "Profiles ordered by volunteering rate (low \u2192 high) | Profiles 1 & 2 = Socially Disconnected"
  )

ggsave("figures/lpa_gen_dist_improved.png", p_dist,
       width = 10, height = 7.5, dpi = 300, bg = "white")
cat("Saved: figures/lpa_gen_dist_improved.png\n")


# ==============================================================================
# 4. IMPROVED: Figure 2 - LPA Heatmap with Volunteering Rate
# ==============================================================================
cat("\n=== Figure: LPA Heatmap (Improved) ===\n")

profile_names_wrap <- c(
  "1" = "Isolated\nDisengaged",
  "2" = "Politically Aware\nIsolated",
  "3" = "Socially Active\nNon-Donors",
  "4" = "Mainstream\nDonors",
  "5" = "Activist\nBoycotters",
  "6" = "Fully\nEngaged"
)

# Include vol_rate in heatmap data
heatmap_data <- profile_summary %>%
  select(profile_ordered, boycott_pct, puboff_pct, polconv_mean,
         socialize_mean, membership_mean, donated_pct, vol_rate) %>%
  pivot_longer(-profile_ordered, names_to = "indicator", values_to = "value") %>%
  mutate(
    indicator_label = case_when(
      indicator == "boycott_pct"     ~ "Boycotting\n(%)",
      indicator == "puboff_pct"      ~ "Contact\nOfficials (%)",
      indicator == "polconv_mean"    ~ "Political\nConv. (1\u20136)",
      indicator == "socialize_mean"  ~ "Socialization\n(1\u20136)",
      indicator == "membership_mean" ~ "Org.\nMembership",
      indicator == "donated_pct"     ~ "Charitable\nGiving (%)",
      indicator == "vol_rate"        ~ "Volunteering\nRate (%)"
    ),
    profile_label = profile_names_wrap[as.character(profile_ordered)],
    # Flag for special treatment of vol_rate column
    is_vol = indicator == "vol_rate"
  ) %>%
  group_by(indicator) %>%
  mutate(value_norm = (value - min(value)) / (max(value) - min(value) + 1e-10)) %>%
  ungroup() %>%
  mutate(
    display_value = case_when(
      indicator %in% c("boycott_pct", "puboff_pct", "donated_pct", "vol_rate") ~
        sprintf("%.0f%%", value),
      indicator %in% c("polconv_mean", "socialize_mean") ~
        sprintf("%.1f", value),
      indicator == "membership_mean" ~ sprintf("%.2f", value)
    )
  )

# Order indicators -- vol_rate at the end (right side)
indicator_order <- c(
  "Socialization\n(1\u20136)", "Political\nConv. (1\u20136)",
  "Org.\nMembership", "Boycotting\n(%)",
  "Contact\nOfficials (%)", "Charitable\nGiving (%)",
  "Volunteering\nRate (%)"
)
heatmap_data$indicator_label <- factor(heatmap_data$indicator_label,
                                        levels = indicator_order)

# Order profiles (low to high, bottom to top for display)
profile_order_wrap <- c(
  "Isolated\nDisengaged", "Politically Aware\nIsolated",
  "Socially Active\nNon-Donors", "Mainstream\nDonors",
  "Activist\nBoycotters", "Fully\nEngaged"
)
heatmap_data$profile_label <- factor(heatmap_data$profile_label,
                                      levels = rev(profile_order_wrap))

# Text color: white on dark tiles, black on light tiles
heatmap_data <- heatmap_data %>%
  mutate(text_color = ifelse(value_norm > 0.6, "white", "gray15"))

# Add profile sizes as right-side annotation (via y-axis labels)
profile_n <- profile_summary %>%
  arrange(profile_ordered) %>%
  mutate(
    label = sprintf("%s\n(n = %s, %.0f%%)",
                    profile_names_wrap[as.character(profile_ordered)],
                    format(n, big.mark = ","),
                    pct)
  )

# Update profile labels to include N
profile_label_with_n <- setNames(profile_n$label, profile_names_wrap[as.character(profile_n$profile_ordered)])
heatmap_data <- heatmap_data %>%
  mutate(profile_label_n = profile_label_with_n[as.character(profile_label)])

heatmap_data$profile_label_n <- factor(heatmap_data$profile_label_n,
  levels = rev(profile_label_with_n[profile_order_wrap]))

# Separate fill for vol_rate column vs others
# We'll use a single fill scale but with a gradient that works for both
# The blue gradient works well for the input indicators.
# For vol_rate, we can use the same blue scale -- it's also an "outcome" measure.
# To visually separate, we'll add a vertical line.

p_heatmap <- ggplot(heatmap_data,
       aes(x = indicator_label, y = profile_label_n)) +
  # Main heatmap tiles
  geom_tile(aes(fill = value_norm), color = "white", linewidth = 2) +
  # Cell values
  geom_text(aes(label = display_value, color = text_color),
            size = 4.2, fontface = "bold", show.legend = FALSE) +
  # Separator line between indicators and vol_rate
  geom_vline(xintercept = 6.5, color = "gray40", linewidth = 1.2, linetype = "solid") +
  scale_color_identity() +
  scale_fill_gradient2(
    low = "#F7F7F7", mid = "#7FBADC", high = "#08519C",
    midpoint = 0.5, guide = "none"
  ) +
  theme_pub(base_size = 13) +
  theme(
    axis.text.x = element_text(size = 9.5, face = "bold", lineheight = 1.0),
    axis.text.y = element_text(size = 9.5, face = "bold", lineheight = 1.0),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.title.position = "plot"
  ) +
  labs(
    title = "Civic Engagement Profile Characteristics",
    subtitle = "Indicator means by latent profile (CPS-CEV 2017\u20132023, N = 197,497)",
    caption = "Color intensity = within-indicator normalization (0\u20131) | Vertical line separates input indicators from outcome"
  )

ggsave("figures/lpa_heatmap_improved.png", p_heatmap,
       width = 11, height = 6.5, dpi = 300, bg = "white")
cat("Saved: figures/lpa_heatmap_improved.png\n")

cat("\n=== All improved figures generated successfully ===\n")
