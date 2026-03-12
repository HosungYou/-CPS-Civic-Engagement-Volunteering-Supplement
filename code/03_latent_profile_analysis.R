# ==============================================================================
# 03_latent_profile_analysis.R
# SUPPLEMENTARY ANALYSIS A: Latent Profile Analysis (LPA)
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Design: 4-wave pooled (2017/2019/2021/2023), N ~ 201,000
#
# Purpose: Identify civic engagement typologies using 6 indicators.
#          Provide person-centered context for logistic regression findings.
#
# 6 LPA Indicators:
#   1. boycott    -- Consumer political action (binary)
#   2. puboff     -- Contacting public officials (binary)
#   3. polconv    -- Political conversation frequency (1-6)
#   4. socialize  -- In-person socialization frequency (1-6)
#   5. membership -- Organizational membership count (0+)
#   6. donated    -- Charitable donation (binary)
#
# Note: Uses mclust directly (not tidyLPA) for better control over
#       model specification with mixed variable types.
# ==============================================================================

library(tidyverse)
library(mclust)
library(survey)
library(ggplot2)
library(patchwork)

set.seed(20260309)

# --- 1. Load Cleaned Data (4-wave pooled) -------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Total sample size: N = %s\n", format(nrow(data), big.mark = ",")))

# --- 2. Prepare LPA Indicators ------------------------------------------------
lpa_vars <- c("boycott", "puboff", "polconv", "socialize", "membership", "donated")

data_lpa <- data %>%
  filter(
    !is.na(boycott) & !is.na(puboff) & !is.na(polconv) &
    !is.na(socialize) & !is.na(membership) & !is.na(donated)
  )

cat(sprintf("LPA analytic sample: N = %s\n", format(nrow(data_lpa), big.mark = ",")))

# Standardize for LPA
data_lpa <- data_lpa %>%
  mutate(across(all_of(lpa_vars), ~ scale(.)[,1], .names = "{.col}_z"))

lpa_z_vars <- paste0(lpa_vars, "_z")

# Check distributions
lpa_label_map <- c(
  "boycott_z" = "Boycotting",
  "puboff_z" = "Contacting Officials",
  "polconv_z" = "Political Conversation",
  "socialize_z" = "In-Person Socialization",
  "membership_z" = "Org. Membership",
  "donated_z" = "Charitable Donation"
)
data_lpa %>%
  select(all_of(lpa_z_vars)) %>%
  pivot_longer(everything()) %>%
  mutate(name = recode(name, !!!lpa_label_map)) %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~name, scales = "free") +
  theme_minimal() +
  labs(title = "Distribution of Standardized LPA Indicators (4-wave pooled)")

ggsave("figures/lpa_indicator_distributions.png", width = 12, height = 8, dpi = 300)

# --- 3. Model Selection with mclust (subsample) ------------------------------
SUBSAMPLE_N <- 20000

cat(sprintf("Using random subsample of %s for model selection...\n",
            format(SUBSAMPLE_N, big.mark = ",")))
set.seed(20260309)
idx <- sample(nrow(data_lpa), SUBSAMPLE_N)
data_select <- data_lpa[idx, ]

# Use EII model (spherical, equal volume) -- robust for mixed binary/ordinal
lpa_mat <- as.matrix(data_select[, lpa_z_vars])

cat("\nFitting EII models with 2-10 profiles...\n")
bic_results <- mclustBIC(lpa_mat, G = 2:10, modelNames = "EII")

cat("\n=== BIC Comparison ===\n")
bic_vals <- bic_results[, "EII"]
bic_for_plot <- data.frame(
  Classes = 2:10,
  BIC = as.numeric(bic_vals)
)
print(bic_for_plot)

# BIC improvement
cat("\nBIC improvement per additional class:\n")
for (i in 2:nrow(bic_for_plot)) {
  cat(sprintf("  %d -> %d: %+.1f\n",
              bic_for_plot$Classes[i-1], bic_for_plot$Classes[i],
              bic_for_plot$BIC[i] - bic_for_plot$BIC[i-1]))
}

# Select K=6: largest BIC improvement at 5->6, interpretable
SELECTED_K <- 6
best_type <- "EII"
cat(sprintf("\nSelected K = %d (largest BIC improvement + interpretability)\n", SELECTED_K))

# BIC elbow plot
ggplot(bic_for_plot, aes(x = Classes, y = BIC)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  geom_point(data = bic_for_plot[bic_for_plot$Classes == SELECTED_K, ],
             size = 5, color = "red", shape = 1, stroke = 2) +
  scale_x_continuous(breaks = 2:7) +
  theme_minimal(base_size = 14) +
  labs(title = "BIC by Number of Latent Profiles (EII model)",
       subtitle = "6 Indicators, 4-Wave Pooled (20K subsample)",
       x = "Number of Profiles", y = "BIC")

ggsave("figures/lpa_bic_elbow.png", width = 8, height = 6, dpi = 300)

# --- 4. Fit Selected Model to Full Sample ------------------------------------
cat(sprintf("\nFitting %d-profile %s model to full sample (N=%s)...\n",
            SELECTED_K, best_type,
            format(nrow(data_lpa), big.mark = ",")))

full_mat <- as.matrix(data_lpa[, lpa_z_vars])
full_model <- Mclust(full_mat, G = SELECTED_K, modelNames = best_type)

# Get profile assignments
data_lpa$profile <- full_model$classification
data_lpa$profile_prob <- apply(full_model$z, 1, max)

# Entropy
entropy <- 1 - (-sum(full_model$z * log(full_model$z + 1e-10)) /
                  (nrow(full_mat) * log(SELECTED_K)))
cat(sprintf("Entropy: %.3f\n", entropy))
cat(sprintf("Posterior probability >= 0.70: %d (%.1f%%)\n",
            sum(data_lpa$profile_prob >= 0.70),
            mean(data_lpa$profile_prob >= 0.70) * 100))

# --- 5. Profile Characterization (original scale) ----------------------------
profile_summary <- data_lpa %>%
  group_by(profile) %>%
  summarise(
    n = n(),
    pct = n() / nrow(data_lpa) * 100,
    boycott_pct      = mean(boycott, na.rm = TRUE) * 100,
    puboff_pct       = mean(puboff, na.rm = TRUE) * 100,
    polconv_mean     = mean(polconv, na.rm = TRUE),
    socialize_mean   = mean(socialize, na.rm = TRUE),
    membership_mean  = mean(membership, na.rm = TRUE),
    donated_pct      = mean(donated, na.rm = TRUE) * 100,
    vol_rate         = mean(volunteered, na.rm = TRUE) * 100,
    .groups = "drop"
  )

cat("\n=== Profile Summary ===\n")
print(profile_summary, width = Inf)

# --- 6. Reorder profiles by engagement level (vol_rate) ----------------------
profile_order <- profile_summary %>% arrange(vol_rate) %>% pull(profile)
profile_map <- setNames(seq_along(profile_order), profile_order)
data_lpa$profile_ordered <- profile_map[as.character(data_lpa$profile)]

# Recompute with ordered profiles
profile_summary_ord <- data_lpa %>%
  group_by(profile_ordered) %>%
  summarise(
    n = n(),
    pct = n() / nrow(data_lpa) * 100,
    boycott_pct      = mean(boycott, na.rm = TRUE) * 100,
    puboff_pct       = mean(puboff, na.rm = TRUE) * 100,
    polconv_mean     = mean(polconv, na.rm = TRUE),
    socialize_mean   = mean(socialize, na.rm = TRUE),
    membership_mean  = mean(membership, na.rm = TRUE),
    donated_pct      = mean(donated, na.rm = TRUE) * 100,
    vol_rate         = mean(volunteered, na.rm = TRUE) * 100,
    .groups = "drop"
  )

cat("\n=== Profile Summary (ordered by engagement level) ===\n")
print(profile_summary_ord, width = Inf)

# --- 7. Generational Distribution by Profile ---------------------------------
gen_profile <- data_lpa %>%
  dplyr::count(generation, profile_ordered) %>%
  group_by(generation) %>%
  mutate(pct = n / sum(n) * 100)

cat("\n=== Generational Distribution Across Profiles ===\n")
gen_profile %>%
  select(generation, profile_ordered, pct) %>%
  pivot_wider(names_from = profile_ordered, values_from = pct) %>%
  print()

# Stacked bar chart
gen_colors <- c(
  "Gen Z"       = "#E63946",
  "Millennial"  = "#457B9D",
  "Gen X"       = "#2A9D8F",
  "Boomer"      = "#E9C46A",
  "Silent"      = "#264653"
)

profile_labels <- c(
  "1" = "Isolated Disengaged",
  "2" = "Politically Aware Isolated",
  "3" = "Socially Active Non-Donors",
  "4" = "Mainstream Donors",
  "5" = "Activist Boycotters",
  "6" = "Fully Engaged"
)

ggplot(gen_profile, aes(x = generation, y = pct, fill = factor(profile_ordered))) +
  geom_col(position = "stack", width = 0.7) +
  scale_fill_brewer(palette = "Set2", name = "Profile",
                    labels = profile_labels) +
  theme_minimal(base_size = 14) +
  theme(legend.text = element_text(size = 10)) +
  labs(title = "Civic Engagement Profile Distribution by Generation",
       subtitle = "CPS-CEV 2017-2023, 4-Wave Pooled",
       x = "", y = "Percentage (%)") +
  coord_flip()

ggsave("figures/lpa_generation_distribution.png", width = 10, height = 6, dpi = 300)

# --- 8. Profile x Volunteering x Generation ----------------------------------
profile_vol <- data_lpa %>%
  group_by(profile_ordered, generation) %>%
  summarise(vol_rate = mean(volunteered, na.rm = TRUE) * 100,
            n = n(), .groups = "drop") %>%
  filter(n >= 50)

ggplot(profile_vol, aes(x = factor(profile_ordered), y = vol_rate,
                        fill = generation)) +
  geom_col(position = "dodge", width = 0.7, alpha = 0.8) +
  scale_fill_manual(values = gen_colors, name = "Generation") +
  theme_minimal(base_size = 14) +
  labs(title = "Volunteering Rate by Profile and Generation",
       subtitle = "CPS-CEV 2017-2023",
       x = "Civic Engagement Profile", y = "Volunteering Rate (%)")

ggsave("figures/lpa_vol_rate_profile_gen.png", width = 12, height = 7, dpi = 300)

# --- 9. Profile Distribution: Pre vs Post COVID ------------------------------
covid_profile <- data_lpa %>%
  mutate(period = ifelse(post_covid == 0, "Pre-COVID", "Post-COVID")) %>%
  dplyr::count(period, generation, profile_ordered) %>%
  group_by(period, generation) %>%
  mutate(pct = n / sum(n) * 100)

cat("\n=== Profile Distribution Shift: Pre vs Post COVID ===\n")
covid_profile %>%
  select(period, generation, profile_ordered, pct) %>%
  pivot_wider(names_from = profile_ordered, values_from = pct) %>%
  arrange(generation, period) %>%
  print(n = 20)

# --- 10. Save Results ---------------------------------------------------------
saveRDS(data_lpa, "data/cev_with_profiles.rds")
saveRDS(profile_summary_ord, "data/profile_summary.rds")

cat("\nLPA supplementary analysis complete.\n")
