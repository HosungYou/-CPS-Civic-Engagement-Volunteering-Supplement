# ==============================================================================
# 03_latent_profile_analysis.R
# SUPPLEMENTARY ANALYSIS A: Latent Profile Analysis (LPA)
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Purpose: Identify 4-6 civic engagement typologies to provide person-centered
#          context for the primary logistic regression findings.
# ==============================================================================

library(tidyverse)
library(tidyLPA)
library(mclust)
library(survey)
library(ggplot2)
library(patchwork)
library(gt)

set.seed(20260309)

# --- 1. Load Cleaned Data -----------------------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Total sample size: N = %s\n", format(nrow(data), big.mark = ",")))

# --- 2. Prepare LPA Indicators ------------------------------------------------
# 5 indicators capturing multidimensional civic engagement:
#   1. CEBOYCOTT  — Consumer political action (binary: 0/1)
#   2. CEPUBOFF   — Contacting public officials (binary: 0/1)
#   3. CEPOLCONV  — Political conversation frequency (1-6, ascending)
#   4. CESOCIALIZE — In-person socialization frequency (1-6, ascending)
#   5. VLMEMBERN  — Organizational membership count

data_lpa <- data %>%
  mutate(
    boycott    = ifelse(CEBOYCOTT == 2, 1, 0),   # 2=Yes → 1
    puboff     = ifelse(CEPUBOFF == 2, 1, 0),    # 2=Yes → 1
    polconv    = CEPOLCONV,                        # 1=Never → 6=Daily
    socialize  = CESOCIALIZE,                      # 1=Not at all → 6=Daily
    membership = VLMEMBERN                         # Count of orgs
  ) %>%
  filter(
    !is.na(boycott) & !is.na(puboff) & !is.na(polconv) &
    !is.na(socialize) & !is.na(membership)
  )

cat(sprintf("LPA analytic sample: N = %s\n", format(nrow(data_lpa), big.mark = ",")))

# Standardize continuous indicators for LPA
lpa_vars <- c("boycott", "puboff", "polconv", "socialize", "membership")

data_lpa <- data_lpa %>%
  mutate(across(all_of(lpa_vars), ~ scale(.)[,1], .names = "{.col}_z"))

lpa_z_vars <- paste0(lpa_vars, "_z")

# Check distributions
data_lpa %>%
  select(all_of(lpa_z_vars)) %>%
  pivot_longer(everything()) %>%
  ggplot(aes(x = value)) +
  geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
  facet_wrap(~name, scales = "free") +
  theme_minimal() +
  labs(title = "Distribution of Standardized LPA Indicators")

ggsave("figures/lpa_indicator_distributions.png", width = 12, height = 8, dpi = 300)

# --- 3. Estimate LPA Models (2 to 7 classes) ----------------------------------
# Note: With N > 200,000, computation is intensive.
# Consider random subsample for model selection, then assign full sample.

# Option A: Full sample (slow but definitive)
# Option B: Random subsample for selection → full sample for assignment
USE_SUBSAMPLE <- TRUE
SUBSAMPLE_N <- 20000

if (USE_SUBSAMPLE) {
  cat(sprintf("Using random subsample of %s for model selection...\n",
              format(SUBSAMPLE_N, big.mark = ",")))
  set.seed(20260309)
  idx <- sample(nrow(data_lpa), SUBSAMPLE_N)
  data_select <- data_lpa[idx, ]
} else {
  data_select <- data_lpa
}

lpa_results <- data_select %>%
  select(all_of(lpa_z_vars)) %>%
  estimate_profiles(2:7,
                    variances = "varying",
                    covariances = "zero")

# --- 4. Model Selection -------------------------------------------------------
fit_stats <- get_fit(lpa_results)

fit_table <- fit_stats %>%
  select(Classes, LogLik, AIC, BIC, Entropy, BLRT_val, BLRT_p) %>%
  arrange(BIC)

cat("\n=== Model Fit Comparison ===\n")
print(fit_table)

# BIC Elbow plot
fit_stats %>%
  ggplot(aes(x = Classes, y = BIC)) +
  geom_line(linewidth = 1.2, color = "steelblue") +
  geom_point(size = 3, color = "steelblue") +
  scale_x_continuous(breaks = 2:7) +
  theme_minimal(base_size = 14) +
  labs(title = "BIC by Number of Latent Profiles",
       x = "Number of Profiles", y = "BIC")

ggsave("figures/lpa_bic_elbow.png", width = 8, height = 6, dpi = 300)

# --- 5. Fit Selected Model to Full Sample -------------------------------------
# Adjust K based on model selection results (expect 5-6)
SELECTED_K <- 6  # UPDATE after reviewing fit_table

cat(sprintf("\nFitting %d-profile model to full sample...\n", SELECTED_K))

best_model <- data_lpa %>%
  select(all_of(lpa_z_vars)) %>%
  estimate_profiles(SELECTED_K, variances = "varying", covariances = "zero")

# Get profile assignments
assignments <- get_data(best_model)

data_lpa <- data_lpa %>%
  mutate(
    profile = assignments$Class,
    profile_prob = assignments$Class_prob
  )

# Quality filter
cat(sprintf("Posterior probability >= 0.70: %d (%.1f%%)\n",
            sum(data_lpa$profile_prob >= 0.70),
            mean(data_lpa$profile_prob >= 0.70) * 100))

# --- 6. Profile Characterization (on original scale) --------------------------
profile_summary <- data_lpa %>%
  group_by(profile) %>%
  summarise(
    n = n(),
    pct = n() / nrow(data_lpa) * 100,
    boycott_pct    = mean(boycott, na.rm = TRUE) * 100,
    puboff_pct     = mean(puboff, na.rm = TRUE) * 100,
    polconv_mean   = mean(polconv, na.rm = TRUE),
    socialize_mean = mean(socialize, na.rm = TRUE),
    membership_mean = mean(membership, na.rm = TRUE),
    vol_rate       = mean(ifelse(VLSTATUS == 1, 1, 0), na.rm = TRUE) * 100,
    .groups = "drop"
  )

cat("\n=== Profile Summary ===\n")
print(profile_summary, width = Inf)

# --- 7. Generational Distribution by Profile ----------------------------------
data_lpa <- data_lpa %>%
  mutate(
    birth_year = YEAR - AGE,
    generation = factor(
      case_when(
        birth_year >= 1997 ~ "Gen Z",
        birth_year >= 1981 ~ "Millennial",
        birth_year >= 1965 ~ "Gen X",
        birth_year >= 1946 ~ "Boomer",
        TRUE ~ "Silent"
      ),
      levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")
    )
  )

gen_profile <- data_lpa %>%
  count(generation, profile) %>%
  group_by(generation) %>%
  mutate(pct = n / sum(n) * 100)

cat("\n=== Generational Distribution Across Profiles ===\n")
gen_profile %>%
  select(generation, profile, pct) %>%
  pivot_wider(names_from = profile, values_from = pct) %>%
  print()

# Stacked bar chart
ggplot(gen_profile, aes(x = generation, y = pct, fill = factor(profile))) +
  geom_col(position = "stack", width = 0.7) +
  scale_fill_brewer(palette = "Set2", name = "Profile") +
  theme_minimal(base_size = 14) +
  labs(title = "Civic Engagement Profile Distribution by Generation",
       x = "", y = "Percentage (%)") +
  coord_flip()

ggsave("figures/lpa_generation_distribution.png", width = 10, height = 6, dpi = 300)

# --- 8. Save Results ----------------------------------------------------------
saveRDS(data_lpa, "data/cev_with_profiles.rds")
saveRDS(profile_summary, "data/profile_summary.rds")

cat("\nLPA supplementary analysis complete.\n")
