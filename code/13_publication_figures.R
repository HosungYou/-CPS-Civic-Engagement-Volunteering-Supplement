# ==============================================================================
# 13_publication_figures.R
# Publication-Quality Figures for "Bowling Alone, Scrolling Together"
#
# Complete redesign with:
#   - Consistent professional theme across all figures
#   - Normalized heatmap values (0-100 scale)
#   - Corrected generational distribution stacking & annotations
#   - Uniform-color AME forest plot (no Gen Z highlighting)
#   - Polished predicted probability plot
#
# Outputs:
#   figures/fig1_pred_prob.png      (10x6, 300 DPI)
#   figures/fig2_lpa_heatmap.png    (10x6, 300 DPI)
#   figures/fig3_lpa_gen_dist.png   (10x6, 300 DPI)
#   figures/fig4_ame_first_step.png (10x5, 300 DPI)
# ==============================================================================

setwd("/Volumes/External SSD/Projects/Research/-CPS-Civic-Engagement-Volunteering-Supplement")

library(tidyverse)
library(survey)
library(marginaleffects)
library(scales)

# ==============================================================================
# DESIGN SYSTEM
# ==============================================================================

# --- Color Palette ---
# Main palette (muted, sophisticated)
pal_slate     <- "#4A5568"
pal_blue      <- "#2B6CB0"
pal_green     <- "#48BB78"
pal_amber     <- "#ED8936"
pal_rose      <- "#E53E3E"

# Navy for uniform elements
pal_navy      <- "#1A365D"
pal_navy_light <- "#2C5282"

# Heatmap sequential blues
heatmap_low   <- "#F0F4F8"
heatmap_mid   <- "#6BAED6"
heatmap_high  <- "#08306B"

# Volunteering column (green-gray)
vol_low       <- "#F0F4F0"
vol_mid       <- "#74C69D"
vol_high      <- "#1B4332"

# Generation colors (muted, distinguishable)
gen_colors <- c(
  "Gen Z"      = "#5B8DB8",
  "Millennial" = "#E8875B",
  "Gen X"      = "#6BAF7D",
  "Boomer"     = "#C9A84C",
  "Silent"     = "#8B7EB8"
)

# Profile colors (warm-to-cool gradient, low-to-high engagement)
profile_colors <- c(
  "Isolated\nDisengaged"           = "#C1666B",
  "Politically Aware\nIsolated"    = "#D4A276",
  "Socially Active\nNon-Donors"    = "#E8C547",
  "Mainstream\nDonors"             = "#7EC4A5",
  "Activist\nBoycotters"           = "#4E8098",
  "Fully\nEngaged"                 = "#2D4059"
)

# --- Custom Theme ---
theme_pub <- function(base_size = 11) {
  theme_minimal(base_size = base_size) %+replace%
    theme(
      # Text hierarchy
      text             = element_text(color = "gray20"),
      plot.title       = element_text(face = "bold", size = rel(1.1), hjust = 0,
                                      margin = margin(b = 3), color = "gray10"),
      plot.subtitle    = element_text(size = rel(0.9), hjust = 0, color = "gray45",
                                      margin = margin(b = 10)),
      plot.caption     = element_text(size = rel(0.72), hjust = 0, color = "gray55",
                                      margin = margin(t = 10), lineheight = 1.2),
      # Axes
      axis.title       = element_text(size = rel(0.9), color = "gray25"),
      axis.title.x     = element_text(margin = margin(t = 8)),
      axis.title.y     = element_text(margin = margin(r = 8)),
      axis.text        = element_text(size = rel(0.85), color = "gray35"),
      axis.ticks       = element_line(color = "gray80", linewidth = 0.3),
      axis.ticks.length = unit(3, "pt"),
      # Grid
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "gray92", linewidth = 0.4),
      # Legend
      legend.title     = element_text(size = rel(0.85), face = "bold", color = "gray25"),
      legend.text      = element_text(size = rel(0.8), color = "gray35"),
      legend.key.size  = unit(0.45, "cm"),
      legend.background = element_rect(fill = "transparent", color = NA),
      # Spacing
      plot.margin      = margin(14, 16, 10, 10),
      plot.title.position = "plot",
      plot.caption.position = "plot",
      # Panel
      panel.background = element_rect(fill = "white", color = NA),
      plot.background  = element_rect(fill = "white", color = NA),
      strip.text       = element_text(face = "bold", size = rel(0.9))
    )
}

# --- Profile names ---
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

# --- Source note ---
source_note <- "Source: CPS Civic Engagement and Volunteering Supplement, 2017\u20132023 (N = 201,168)"


# ==============================================================================
# LOAD DATA
# ==============================================================================
cat("Loading data...\n")
data <- readRDS("data/cev_clean.rds")
models <- readRDS("data/logistic_models.rds")
data_lpa <- readRDS("data/cev_with_profiles.rds")
profile_summary <- readRDS("data/profile_summary.rds")

m1 <- models$m1

# Survey design for marginaleffects
options(survey.lonely.psu = "adjust")


# ==============================================================================
# FIGURE 1: Predicted Probability of Volunteering
# ==============================================================================
cat("\n=== Figure 1: Predicted Probability ===\n")

pred_m1 <- predictions(m1,
  newdata = datagrid(soc_factor = unique, generation = unique),
  type = "response"
)

pred_df <- as_tibble(pred_m1) %>%
  select(soc_factor, generation, estimate, conf.low, conf.high) %>%
  mutate(
    soc_num = as.numeric(factor(soc_factor,
      levels = c("Not at all", "Few times/yr", "Once/mo",
                 "Few times/mo", "Few times/wk", "Daily"))),
    generation = factor(generation,
      levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent"))
  )

cat("Predicted probabilities (Gen Z):\n")
print(pred_df %>% filter(generation == "Gen Z") %>% arrange(soc_num))

# Gen Z values for annotations
genz_vals <- pred_df %>% filter(generation == "Gen Z") %>% arrange(soc_num)
genz_baseline <- genz_vals$estimate[1]
genz_first_step <- genz_vals$estimate[2]

# Endpoint labels for direct labeling (right-side)
label_df <- pred_df %>%
  filter(soc_num == max(soc_num)) %>%
  arrange(desc(estimate)) %>%
  mutate(
    # Nudge to avoid overlap
    y_adj = estimate
  )

# Check for label overlap and nudge if needed
for (i in 2:nrow(label_df)) {
  if (abs(label_df$y_adj[i] - label_df$y_adj[i-1]) < 0.018) {
    label_df$y_adj[i] <- label_df$y_adj[i-1] - 0.018
  }
}

p1 <- ggplot(pred_df,
       aes(x = soc_factor, y = estimate,
           color = generation, group = generation)) +
  # Confidence ribbons
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high, fill = generation),
              alpha = 0.07, color = NA) +
  # Lines
  geom_line(linewidth = 0.85) +
  # Points
  geom_point(size = 2, shape = 16) +
  # Direct labels at right end
  geom_text(data = label_df,
            aes(label = generation, y = y_adj),
            hjust = -0.12, size = 3.2, fontface = "bold",
            show.legend = FALSE) +
  # "First Step" bracket annotation
  annotate("segment",
           x = 1, xend = 2, y = -0.008, yend = -0.008,
           color = "gray40", linewidth = 0.5) +
  annotate("segment", x = 1, xend = 1, y = -0.008, yend = 0.002,
           color = "gray40", linewidth = 0.5) +
  annotate("segment", x = 2, xend = 2, y = -0.008, yend = 0.002,
           color = "gray40", linewidth = 0.5) +
  annotate("text", x = 1.5, y = -0.022,
           label = "\u201CFirst Step\u201D Effect",
           fontface = "italic", size = 3.0, color = "gray40") +
  # Gen Z baseline annotation
  annotate("text",
           x = 0.6, y = genz_baseline + 0.015,
           label = sprintf("Gen Z baseline: %.1f%%", genz_baseline * 100),
           size = 2.8, color = gen_colors["Gen Z"], fontface = "italic",
           hjust = 0) +
  # Gen Z plateau annotation (near the flat region)
  annotate("segment",
           x = 4.8, xend = 4.3,
           y = genz_vals$estimate[genz_vals$soc_num == 5] + 0.055,
           yend = genz_vals$estimate[genz_vals$soc_num == 5] + 0.012,
           arrow = arrow(length = unit(0.12, "cm"), type = "closed"),
           color = gen_colors["Gen Z"], linewidth = 0.4) +
  annotate("text",
           x = 4.8,
           y = genz_vals$estimate[genz_vals$soc_num == 5] + 0.065,
           label = "Gen Z plateau",
           size = 2.8, color = gen_colors["Gen Z"], fontface = "italic",
           hjust = 0.5) +
  # Scales
  scale_color_manual(values = gen_colors, guide = "none") +
  scale_fill_manual(values = gen_colors, guide = "none") +
  scale_y_continuous(
    labels = percent_format(accuracy = 1),
    limits = c(-0.035, NA),
    expand = expansion(mult = c(0, 0.05))
  ) +
  scale_x_discrete(expand = expansion(add = c(0.3, 1.6))) +
  theme_pub(base_size = 11) +
  theme(
    axis.text.x = element_text(size = 9.5),
    panel.grid.major.x = element_blank()
  ) +
  labs(
    title = "Predicted Probability of Volunteering by Socialization Frequency and Generation",
    subtitle = "Survey-weighted logistic regression with socialization \u00D7 generation interaction",
    x = "In-Person Socialization Frequency",
    y = "Predicted Probability of Volunteering",
    caption = paste0(source_note,
      "\nModel controls for age, sex, race/ethnicity, education, employment, marital status, income, urbanicity, region, and COVID period.")
  )

ggsave("figures/fig1_pred_prob.png", p1,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("Saved: figures/fig1_pred_prob.png\n")


# ==============================================================================
# FIGURE 2: LPA Heatmap (Normalized 0-100 Scale)
# ==============================================================================
cat("\n=== Figure 2: LPA Heatmap (Normalized) ===\n")

# Compute normalized values on 0-100 scale
# - Binary % variables: keep as-is (already 0-100)
# - Ordinal 1-6: ((value - 1) / 5) * 100
# - Count (membership): (value / max) * 100
# Color intensity: within-indicator normalization (0-1)

membership_max <- max(profile_summary$membership_mean)
cat(sprintf("Membership max: %.4f\n", membership_max))

heatmap_long <- profile_summary %>%
  select(profile_ordered, boycott_pct, puboff_pct, polconv_mean,
         socialize_mean, membership_mean, donated_pct, vol_rate) %>%
  pivot_longer(-profile_ordered, names_to = "indicator", values_to = "raw_value") %>%
  mutate(
    # Normalize to 0-100 common scale
    norm_100 = case_when(
      indicator %in% c("boycott_pct", "puboff_pct", "donated_pct") ~ raw_value,
      indicator %in% c("polconv_mean", "socialize_mean") ~ ((raw_value - 1) / 5) * 100,
      indicator == "membership_mean" ~ (raw_value / membership_max) * 100,
      indicator == "vol_rate" ~ raw_value
    ),
    # Display value (normalized, rounded)
    display_value = sprintf("%.0f", round(norm_100)),
    # Indicator labels
    indicator_label = case_when(
      indicator == "socialize_mean"  ~ "Socialization",
      indicator == "polconv_mean"    ~ "Political\nConversation",
      indicator == "membership_mean" ~ "Organizational\nMembership",
      indicator == "boycott_pct"     ~ "Boycotting",
      indicator == "puboff_pct"      ~ "Contacting\nOfficials",
      indicator == "donated_pct"     ~ "Charitable\nGiving",
      indicator == "vol_rate"        ~ "Volunteering\nRate"
    ),
    # Flag vol_rate for separate color treatment
    is_vol = indicator == "vol_rate",
    # Profile labels
    profile_label = profile_names_wrap[as.character(profile_ordered)]
  ) %>%
  # Within-indicator normalization for color intensity (0-1)
  group_by(indicator) %>%
  mutate(
    color_intensity = (norm_100 - min(norm_100)) / (max(norm_100) - min(norm_100) + 1e-10)
  ) %>%
  ungroup()

# Indicator order (vol_rate last, separated)
indicator_order <- c(
  "Socialization", "Political\nConversation",
  "Organizational\nMembership", "Boycotting",
  "Contacting\nOfficials", "Charitable\nGiving",
  "Volunteering\nRate"
)
heatmap_long$indicator_label <- factor(heatmap_long$indicator_label,
                                        levels = indicator_order)

# Profile order (Fully Engaged at top)
profile_order_wrap <- c(
  "Isolated\nDisengaged", "Politically Aware\nIsolated",
  "Socially Active\nNon-Donors", "Mainstream\nDonors",
  "Activist\nBoycotters", "Fully\nEngaged"
)

# Build profile labels with N and %
profile_labels_with_n <- profile_summary %>%
  arrange(profile_ordered) %>%
  mutate(
    wrap = profile_names_wrap[as.character(profile_ordered)],
    full_label = sprintf("%s\n(n = %s, %.1f%%)",
                         wrap, format(n, big.mark = ","), pct)
  )
label_mapping <- setNames(profile_labels_with_n$full_label,
                           profile_labels_with_n$wrap)

heatmap_long <- heatmap_long %>%
  mutate(profile_label_n = label_mapping[profile_label])

heatmap_long$profile_label_n <- factor(
  heatmap_long$profile_label_n,
  levels = rev(label_mapping[profile_order_wrap])
)

# Text color: white on dark tiles
heatmap_long <- heatmap_long %>%
  mutate(text_color = ifelse(color_intensity > 0.55, "white", "gray15"))

# Separate data for two fill scales (indicators vs volunteering)
heatmap_indicators <- heatmap_long %>% filter(!is_vol)
heatmap_vol <- heatmap_long %>% filter(is_vol)

cat("Heatmap normalized values:\n")
print(heatmap_long %>%
  select(profile_ordered, indicator, raw_value, norm_100) %>%
  pivot_wider(names_from = indicator, values_from = c(raw_value, norm_100)) %>%
  as.data.frame())

# Build the heatmap using two geom_tile layers with manual fill
# Since ggplot2 doesn't support two fill aesthetics easily,
# we'll compute the actual fill colors manually

# Color interpolation function
interp_color <- function(intensity, low, mid, high) {
  sapply(intensity, function(v) {
    if (v <= 0.5) {
      colorRampPalette(c(low, mid))(100)[max(1, round(v * 2 * 99) + 1)]
    } else {
      colorRampPalette(c(mid, high))(100)[max(1, round((v - 0.5) * 2 * 99) + 1)]
    }
  })
}

heatmap_long <- heatmap_long %>%
  mutate(
    tile_fill = ifelse(
      is_vol,
      interp_color(color_intensity, vol_low, vol_mid, vol_high),
      interp_color(color_intensity, heatmap_low, heatmap_mid, heatmap_high)
    )
  )

p2 <- ggplot(heatmap_long,
       aes(x = indicator_label, y = profile_label_n)) +
  # Tiles with manual fill
  geom_tile(aes(fill = tile_fill), color = "white", linewidth = 2.2) +
  scale_fill_identity() +
  # Cell values
  geom_text(aes(label = display_value, color = text_color),
            size = 4.5, fontface = "bold", show.legend = FALSE) +
  scale_color_identity() +
  # Separator between indicators and volunteering
  geom_vline(xintercept = 6.5, color = "gray50", linewidth = 1, linetype = "solid") +
  # Column header annotations
  annotate("text", x = 3.5, y = 7.2, label = "Civic Engagement Indicators",
           size = 3.3, fontface = "bold", color = "gray35") +
  annotate("text", x = 7, y = 7.2, label = "Outcome",
           size = 3.3, fontface = "bold", color = "#1B4332") +
  coord_cartesian(ylim = c(0.5, 7), clip = "off") +
  theme_pub(base_size = 11) +
  theme(
    axis.text.x = element_text(size = 9, face = "bold", lineheight = 1.0),
    axis.text.y = element_text(size = 9, face = "bold", lineheight = 1.0),
    panel.grid = element_blank(),
    axis.ticks = element_blank(),
    plot.margin = margin(20, 16, 10, 10)
  ) +
  labs(
    title = "Civic Engagement Profile Characteristics",
    subtitle = "All values normalized to 0\u2013100 scale for cross-indicator comparability",
    x = NULL,
    y = NULL,
    caption = paste0(source_note, " (LPA subsample: N = 197,497)",
      "\nNormalization: Binary indicators shown as %. Ordinal 1\u20136 scales: ((value \u2013 1) / 5) \u00D7 100. Membership count: (value / max) \u00D7 100.",
      "\nColor intensity reflects within-indicator relative magnitude. Green column = volunteering rate (outcome, not used in LPA).")
  )

ggsave("figures/fig2_lpa_heatmap.png", p2,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("Saved: figures/fig2_lpa_heatmap.png\n")


# ==============================================================================
# FIGURE 3: LPA Generational Distribution (Corrected Stacking)
# ==============================================================================
cat("\n=== Figure 3: LPA Generational Distribution ===\n")

gen_profile <- data_lpa %>%
  mutate(
    generation = factor(generation,
      levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")),
    profile_label = profile_names_wrap[as.character(profile_ordered)],
    # Reverse factor levels: ggplot2 stacks LAST level at BOTTOM.
    # We want Isolated Disengaged at bottom, so it must be LAST in factor levels.
    profile_label = factor(profile_label, levels = rev(profile_order_wrap))
  ) %>%
  count(generation, profile_label) %>%
  group_by(generation) %>%
  mutate(pct = n / sum(n) * 100) %>%
  ungroup()

# Compute Gen Z stats
genz_disconnected <- gen_profile %>%
  filter(generation == "Gen Z",
         profile_label %in% c("Isolated\nDisengaged", "Politically Aware\nIsolated")) %>%
  summarise(total = sum(pct)) %>%
  pull(total)

genz_engaged <- gen_profile %>%
  filter(generation == "Gen Z", profile_label == "Fully\nEngaged") %>%
  pull(pct)

cat(sprintf("Gen Z disconnected (P1+P2): %.1f%%\n", genz_disconnected))
cat(sprintf("Gen Z fully engaged (P6): %.1f%%\n", genz_engaged))

# Compute actual visual stacking positions using ggplot_build
# Since ggplot2 stacks last-level-at-bottom, the visual bottom-to-top order is:
# Isolated Disengaged (bottom) -> ... -> Fully Engaged (top)
# We need to compute the visual positions for annotations

# The visual stacking order (bottom to top) for reversed levels:
# Level 6 (Fully Engaged) gets stacked first (bottom) ... NO:
# With rev(profile_order_wrap), levels are:
# [1] "Fully\nEngaged" [2] "Activist\nBoycotters" ... [6] "Isolated\nDisengaged"
# ggplot2 puts level 6 (Isolated Disengaged) at bottom, level 1 (Fully Engaged) at top.
# Wait, ggplot2 reversal: LAST level is at BOTTOM.
# So level 6 = "Isolated\nDisengaged" -> BOTTOM. Level 1 = "Fully\nEngaged" -> TOP.
# That is EXACTLY what we want.

# Compute cumulative positions matching visual stacking (bottom to top):
# Bottom-to-top order: Isolated Disengaged, Politically Aware Isolated, ..., Fully Engaged
gen_cum <- gen_profile %>%
  group_by(generation) %>%
  # Sort by the VISUAL stacking order (bottom to top = profile_order_wrap order)
  arrange(generation, factor(profile_label, levels = profile_order_wrap)) %>%
  mutate(
    cum_pct = cumsum(pct),
    y_bottom = cum_pct - pct,
    y_mid = y_bottom + pct / 2
  ) %>%
  ungroup()

# Gen Z bracket positions
genz_p2_top <- gen_cum %>%
  filter(generation == "Gen Z", profile_label == "Politically Aware\nIsolated") %>%
  pull(cum_pct)
genz_p6_bottom <- gen_cum %>%
  filter(generation == "Gen Z", profile_label == "Fully\nEngaged") %>%
  pull(y_bottom)
genz_p6_top <- gen_cum %>%
  filter(generation == "Gen Z", profile_label == "Fully\nEngaged") %>%
  pull(cum_pct)
genz_p6_mid <- gen_cum %>%
  filter(generation == "Gen Z", profile_label == "Fully\nEngaged") %>%
  pull(y_mid)

# Bracket midpoint for "Socially Disconnected"
disc_mid <- genz_p2_top / 2

cat(sprintf("Gen Z P2 top (bracket end): %.1f\n", genz_p2_top))
cat(sprintf("Gen Z P6 bottom: %.1f, top: %.1f\n", genz_p6_bottom, genz_p6_top))

p3 <- ggplot(gen_profile,
       aes(x = generation, y = pct, fill = profile_label)) +
  geom_col(width = 0.7, color = "white", linewidth = 0.4) +
  # "Socially Disconnected" bracket on Gen Z (covers P1 + P2 at the bottom)
  # Left bracket
  annotate("segment",
           x = 0.62, xend = 0.62,
           y = 0, yend = genz_p2_top,
           color = "#9B2C2C", linewidth = 0.7) +
  # Bracket ticks
  annotate("segment",
           x = 0.62, xend = 0.67,
           y = 0, yend = 0,
           color = "#9B2C2C", linewidth = 0.7) +
  annotate("segment",
           x = 0.62, xend = 0.67,
           y = genz_p2_top, yend = genz_p2_top,
           color = "#9B2C2C", linewidth = 0.7) +
  # Label
  annotate("text",
           x = 0.48, y = disc_mid,
           label = sprintf("%.1f%%\nSocially\nDisconnected", genz_disconnected),
           size = 2.5, color = "#9B2C2C", fontface = "bold",
           hjust = 1, lineheight = 0.85) +
  # "Fully Engaged" annotation on Gen Z (top segment) - arrow pointing to segment
  annotate("segment",
           x = 1.45, xend = 1.12,
           y = genz_p6_mid - 2, yend = genz_p6_mid,
           arrow = arrow(length = unit(0.12, "cm"), type = "closed"),
           color = "#2D4059", linewidth = 0.4) +
  annotate("text",
           x = 1.5, y = genz_p6_mid - 2,
           label = sprintf("%.1f%% Fully Engaged", genz_engaged),
           size = 2.8, color = "#2D4059", fontface = "bold",
           hjust = 0, lineheight = 0.85) +
  # Fill - legend should show in logical order (low -> high engagement)
  scale_fill_manual(
    values = profile_colors,
    name = "Civic Engagement Profile",
    # breaks in display order (low to high)
    breaks = profile_order_wrap,
    guide = guide_legend(nrow = 1)
  ) +
  scale_y_continuous(
    expand = expansion(mult = c(0, 0.02)),
    labels = function(x) paste0(x, "%")
  ) +
  scale_x_discrete(expand = expansion(add = c(1.2, 0.5))) +
  theme_pub(base_size = 11) +
  theme(
    legend.position = "bottom",
    legend.text = element_text(size = 8, lineheight = 0.9),
    legend.key.size = unit(0.4, "cm"),
    legend.margin = margin(t = 2),
    axis.text.x = element_text(size = 10),
    panel.grid.major.x = element_blank()
  ) +
  labs(
    title = "Civic Engagement Profile Distribution by Generation",
    subtitle = "Latent Profile Analysis with 6 indicators of civic and political engagement",
    x = NULL,
    y = "Percentage of Generation",
    caption = paste0(source_note, " (LPA subsample: N = 197,497)",
      "\nProfiles 1\u20132 (\u201CSocially Disconnected\u201D) = Isolated Disengaged + Politically Aware Isolated.")
  )

ggsave("figures/fig3_lpa_gen_dist.png", p3,
       width = 10, height = 6, dpi = 300, bg = "white")
cat("Saved: figures/fig3_lpa_gen_dist.png\n")


# ==============================================================================
# FIGURE 4: First Step AME Forest Plot (Uniform Color)
# ==============================================================================
cat("\n=== Figure 4: AME First Step Forest Plot ===\n")

cat("Computing AMEs by generation...\n")
ame_m1 <- avg_slopes(m1, variables = "soc_factor", by = "generation")

ame_first_step <- ame_m1 %>%
  as.data.frame() %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, conf.low, conf.high) %>%
  mutate(
    generation = factor(generation,
      levels = rev(c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent"))),
    ame_pp = estimate * 100,
    ci_lo_pp = conf.low * 100,
    ci_hi_pp = conf.high * 100,
    ame_label = sprintf("%+.1f pp", ame_pp)
  )

cat("AME first step data:\n")
print(as.data.frame(ame_first_step))

# Compute the overall mean AME for a reference line
mean_ame <- mean(ame_first_step$ame_pp)

p4 <- ggplot(ame_first_step,
       aes(x = ame_pp, y = generation)) +
  # Reference band showing the range of AMEs (emphasizes universality)
  annotate("rect",
           xmin = min(ame_first_step$ame_pp),
           xmax = max(ame_first_step$ame_pp),
           ymin = -Inf, ymax = Inf,
           fill = pal_navy, alpha = 0.04) +
  # Reference line at zero
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray60", linewidth = 0.4) +
  # Mean AME reference line
  geom_vline(xintercept = mean_ame, linetype = "dotted", color = pal_navy,
             linewidth = 0.5, alpha = 0.6) +
  # CI segments
  geom_segment(aes(x = ci_lo_pp, xend = ci_hi_pp,
                   y = generation, yend = generation),
               linewidth = 1.8, lineend = "round", color = pal_navy, alpha = 0.7) +
  # Point estimates
  geom_point(size = 4.5, color = pal_navy, shape = 16) +
  # AME labels (right of CI)
  geom_text(aes(label = ame_label, x = ci_hi_pp),
            hjust = -0.2, size = 3.5, fontface = "bold", color = pal_navy) +
  # Mean label (inside plot area, between Silent and bottom axis)
  annotate("text",
           x = mean_ame, y = 0.6,
           label = sprintf("Mean: %+.1f pp", mean_ame),
           size = 2.8, color = pal_navy, fontface = "italic",
           hjust = 0.5) +
  coord_cartesian(ylim = c(0.5, 5.5), clip = "off") +
  scale_x_continuous(
    labels = function(x) paste0(x, " pp"),
    expand = expansion(mult = c(0.05, 0.22))
  ) +
  theme_pub(base_size = 11) +
  theme(
    panel.grid.major.y = element_blank(),
    axis.text.y = element_text(size = 10.5, face = "bold"),
    axis.ticks.y = element_blank()
  ) +
  labs(
    title = "The First Step Effect is Universal Across Generations",
    subtitle = "Average Marginal Effect of transitioning from \u201CNot at all\u201D to \u201CFew times/year\u201D socialization on volunteering probability",
    x = "Change in Volunteering Probability (Percentage Points)",
    y = NULL,
    caption = paste0(source_note,
      "\nSurvey-weighted logistic regression (Model 1). Error bars = 95% confidence intervals. Shaded band = range of generational AMEs.")
  )

ggsave("figures/fig4_ame_first_step.png", p4,
       width = 10, height = 5, dpi = 300, bg = "white")
cat("Saved: figures/fig4_ame_first_step.png\n")


# ==============================================================================
cat("\n=== All publication figures generated successfully ===\n")
cat("Output files:\n")
cat("  figures/fig1_pred_prob.png\n")
cat("  figures/fig2_lpa_heatmap.png\n")
cat("  figures/fig3_lpa_gen_dist.png\n")
cat("  figures/fig4_ame_first_step.png\n")
