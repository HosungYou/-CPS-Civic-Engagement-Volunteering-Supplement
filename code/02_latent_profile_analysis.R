# ==============================================================================
# 02_latent_profile_analysis.R
# Phase 1: Latent Profile Analysis (LPA)
#
# Study: Heterogeneous Effects of Organized Volunteering on Civic Engagement
# Authors: Hosung You & Suzanna Windon
# ==============================================================================

library(tidyverse)
library(tidyLPA)
library(mclust)
library(ggplot2)
library(patchwork)
library(gt)

set.seed(20240224)

# --- 1. Load Data -------------------------------------------------------------
data_lpa <- readRDS("data/cev_lpa_ready.rds")

cat(sprintf("Total sample size: %d\n", nrow(data_lpa)))
cat(sprintf("Rural: %d (%.1f%%)\n",
            sum(data_lpa$is_rural == 1, na.rm = TRUE),
            mean(data_lpa$is_rural == 1, na.rm = TRUE) * 100))

# --- 2. LPA Indicator Selection -----------------------------------------------
lpa_vars <- c("vol_hours_log_z", "political_participation_z",
              "charitable_giving_z", "community_interaction_z",
              "org_membership_z")

# Check distributions
data_lpa %>%
  select(all_of(lpa_vars)) %>%
  pivot_longer(everything()) %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~name, scales = "free") +
  theme_minimal() +
  labs(title = "Distribution of Standardized LPA Indicators")

ggsave("figures/lpa_indicator_distributions.png", width = 12, height = 8, dpi = 300)

# --- 3. Estimate LPA Models (1 to 7 classes) ---------------------------------

# Model comparison across profiles and variance structures
lpa_results <- data_lpa %>%
  select(all_of(lpa_vars)) %>%
  estimate_profiles(1:7,
                    variances = c("equal", "varying"),
                    covariances = c("zero", "equal"))

# Extract fit statistics
fit_stats <- get_fit(lpa_results)
print(fit_stats)

# --- 4. Model Selection -------------------------------------------------------

# Create comparison table
fit_table <- fit_stats %>%
  select(Model, Classes, LogLik, AIC, BIC, Entropy,
         BLRT_val, BLRT_p) %>%
  arrange(BIC)

print(fit_table)

# Elbow plot for BIC
fit_stats %>%
  filter(Model == 1) %>%  # Varying variances, zero covariances (Model 2)
  ggplot(aes(x = Classes, y = BIC)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  scale_x_continuous(breaks = 1:7) +
  theme_minimal(base_size = 14) +
  labs(title = "BIC by Number of Latent Profiles",
       x = "Number of Profiles",
       y = "Bayesian Information Criterion (BIC)")

ggsave("figures/lpa_bic_elbow.png", width = 8, height = 6, dpi = 300)

# --- 5. Select Best Model and Extract Profiles --------------------------------
# Example: Assuming 5-profile model is selected (adjust based on actual results)

best_model <- data_lpa %>%
  select(all_of(lpa_vars)) %>%
  estimate_profiles(5, variances = "varying", covariances = "zero")

# Get profile assignments
profile_assignments <- get_data(best_model)

data_with_profiles <- data_lpa %>%
  bind_cols(
    profile = profile_assignments$Class,
    profile_prob = profile_assignments$Class_prob
  ) %>%
  # Quality filter: posterior probability >= 0.70

  filter(profile_prob >= 0.70)

cat(sprintf("Retained after probability filter: %d (%.1f%%)\n",
            nrow(data_with_profiles),
            nrow(data_with_profiles) / nrow(data_lpa) * 100))

# --- 6. Profile Characterization ----------------------------------------------

# Profile means on original indicators
profile_means <- data_with_profiles %>%
  group_by(profile) %>%
  summarise(
    n = n(),
    pct = n() / nrow(data_with_profiles) * 100,
    vol_hours = mean(vol_hours_log_z, na.rm = TRUE),
    political = mean(political_participation_z, na.rm = TRUE),
    giving = mean(charitable_giving_z, na.rm = TRUE),
    community = mean(community_interaction_z, na.rm = TRUE),
    membership = mean(org_membership_z, na.rm = TRUE),
    .groups = "drop"
  )

print(profile_means)

# Assign profile labels (adjust based on actual results)
profile_labels <- c(
  "1" = "Disengaged",
  "2" = "Passive Donors",
  "3" = "Community Connectors",
  "4" = "Active Volunteers",
  "5" = "Civic All-Rounders"
)

data_with_profiles <- data_with_profiles %>%
  mutate(profile_label = factor(profile_labels[as.character(profile)],
                                levels = profile_labels))

# --- 7. Radar Chart Visualization ---------------------------------------------

library(fmsb)

# Prepare radar data
radar_data <- profile_means %>%
  select(profile, vol_hours:membership) %>%
  column_to_rownames("profile")

# Add max/min rows for fmsb
radar_data <- rbind(
  rep(max(radar_data) + 0.5, ncol(radar_data)),  # max
  rep(min(radar_data) - 0.5, ncol(radar_data)),  # min
  radar_data
)

colnames(radar_data) <- c("Volunteering", "Political\nParticipation",
                           "Charitable\nGiving", "Community\nInteraction",
                           "Org\nMembership")

png("figures/lpa_radar_profiles.png", width = 1200, height = 1000, res = 150)
par(mfrow = c(2, 3), mar = c(1, 1, 2, 1))

colors <- c("#E63946", "#457B9D", "#2A9D8F", "#E9C46A", "#264653")

for (i in 1:5) {
  radarchart(radar_data[c(1, 2, i + 2), ],
             axistype = 1,
             pcol = colors[i], pfcol = adjustcolor(colors[i], alpha.f = 0.3),
             plwd = 2, cglcol = "grey80", cglty = 1,
             title = profile_labels[i])
}
dev.off()

# --- 8. Rural/Urban Distribution by Profile -----------------------------------

rural_profile_dist <- data_with_profiles %>%
  count(profile_label, rural_urban) %>%
  group_by(rural_urban) %>%
  mutate(pct = n / sum(n) * 100)

ggplot(rural_profile_dist, aes(x = rural_urban, y = pct, fill = profile_label)) +
  geom_col(position = "stack", width = 0.7) +
  scale_fill_manual(values = colors, name = "Profile") +
  theme_minimal(base_size = 14) +
  labs(title = "Civic Engagement Profile Distribution by Rural/Urban Status",
       x = "", y = "Percentage (%)") +
  coord_flip()

ggsave("figures/lpa_rural_urban_distribution.png", width = 10, height = 6, dpi = 300)

# --- 9. Chi-Square Test -------------------------------------------------------

chisq_result <- chisq.test(
  table(data_with_profiles$profile_label, data_with_profiles$rural_urban)
)
print(chisq_result)

# Cramér's V
n <- sum(chisq_result$observed)
k <- min(nrow(chisq_result$observed), ncol(chisq_result$observed))
cramers_v <- sqrt(chisq_result$statistic / (n * (k - 1)))
cat(sprintf("Cramér's V = %.4f\n", cramers_v))

# --- 10. Save Results ---------------------------------------------------------

saveRDS(data_with_profiles, "data/cev_with_profiles.rds")
saveRDS(profile_means, "data/profile_means.rds")

cat("Phase 1 (LPA) complete. Data with profile assignments saved.\n")
