# ==============================================================================
# 03_causal_forest.R
# Phase 2: Causal Forest (Generalized Random Forest)
#
# Study: Heterogeneous Effects of Organized Volunteering on Civic Engagement
# Authors: Hosung You & Suzanna Windon
# ==============================================================================

library(tidyverse)
library(grf)
library(survey)
library(ggplot2)
library(patchwork)

set.seed(20240224)

# --- 1. Load Data with Profiles -----------------------------------------------
data <- readRDS("data/cev_with_profiles.rds")

cat(sprintf("Analytic sample: %d observations\n", nrow(data)))

# --- 2. Prepare Matrices for GRF ---------------------------------------------

# Covariate matrix (X)
covariate_vars <- c(
  "age", "age_sq", "female", "married", "has_children",
  "employed", "homeowner", "is_rural",
  "profile"  # LPA profile as moderator
)

# One-hot encode categorical variables
X <- model.matrix(~ age + age_sq + female + married + has_children +
                     employed + homeowner + is_rural +
                     race_eth + educ_level + faminc_cat + wave +
                     factor(profile) - 1,
                   data = data)

# Treatment vector (W)
W <- data$volunteered_org

# Survey weights
sample_weights <- data$VLSUPPWT / mean(data$VLSUPPWT)  # Normalize weights

# --- 3. Outcome Variables -----------------------------------------------------

outcomes <- list(
  political = data$political_participation_z,
  giving = data$charitable_giving_z,
  community = data$community_interaction_z,
  membership = data$org_membership_z
)

# --- 4. Propensity Score Assessment -------------------------------------------

# Estimate propensity forest first
p_forest <- regression_forest(X, W, sample.weights = sample_weights,
                               num.trees = 2000)
e_hat <- predict(p_forest)$predictions

# Check overlap
overlap_data <- tibble(
  propensity = e_hat,
  treatment = factor(W, labels = c("Control", "Treated"))
)

ggplot(overlap_data, aes(x = propensity, fill = treatment)) +
  geom_density(alpha = 0.5) +
  scale_fill_manual(values = c("#457B9D", "#E63946")) +
  theme_minimal(base_size = 14) +
  labs(title = "Propensity Score Overlap",
       x = "Estimated Propensity Score",
       y = "Density",
       fill = "Group") +
  geom_vline(xintercept = c(0.05, 0.95), linetype = "dashed", color = "grey50")

ggsave("figures/cf_propensity_overlap.png", width = 10, height = 6, dpi = 300)

# Trim extreme propensity scores
trim_mask <- e_hat > 0.05 & e_hat < 0.95
cat(sprintf("Observations trimmed: %d (%.1f%%)\n",
            sum(!trim_mask), mean(!trim_mask) * 100))

X_trim <- X[trim_mask, ]
W_trim <- W[trim_mask]
weights_trim <- sample_weights[trim_mask]

# --- 5. Estimate Causal Forests -----------------------------------------------

cf_results <- list()

for (outcome_name in names(outcomes)) {
  cat(sprintf("\n--- Estimating Causal Forest for: %s ---\n", outcome_name))

  Y <- outcomes[[outcome_name]][trim_mask]

  # Remove missing outcomes
  valid <- !is.na(Y)

  cf <- causal_forest(
    X = X_trim[valid, ],
    Y = Y[valid],
    W = W_trim[valid],
    sample.weights = weights_trim[valid],
    num.trees = 5000,
    honesty = TRUE,
    honesty.fraction = 0.5,
    tune.parameters = "all",
    seed = 20240224
  )

  cf_results[[outcome_name]] <- list(
    forest = cf,
    valid_mask = valid,
    ate = average_treatment_effect(cf, target.sample = "all"),
    tau_hat = predict(cf)$predictions,
    var_imp = variable_importance(cf)
  )

  cat(sprintf("ATE = %.4f (SE = %.4f)\n",
              cf_results[[outcome_name]]$ate[1],
              cf_results[[outcome_name]]$ate[2]))
}

# --- 6. Average Treatment Effects Summary -------------------------------------

ate_summary <- tibble(
  Outcome = names(cf_results),
  ATE = sapply(cf_results, function(x) x$ate[1]),
  SE = sapply(cf_results, function(x) x$ate[2]),
  CI_lower = ATE - 1.96 * SE,
  CI_upper = ATE + 1.96 * SE,
  p_value = 2 * pnorm(-abs(ATE / SE))
)

print(ate_summary)

# Forest plot of ATEs
ggplot(ate_summary, aes(x = ATE, y = reorder(Outcome, ATE))) +
  geom_point(size = 3, color = "#264653") +
  geom_errorbarh(aes(xmin = CI_lower, xmax = CI_upper),
                 height = 0.2, color = "#264653") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
  theme_minimal(base_size = 14) +
  labs(title = "Average Treatment Effects of Organized Volunteering",
       x = "ATE (Standardized Units)",
       y = "")

ggsave("figures/cf_ate_forest_plot.png", width = 10, height = 6, dpi = 300)

# --- 7. Heterogeneous Effects by Profile and Rural/Urban ----------------------

# Extract data for subgroup analysis
data_trim <- data[trim_mask, ]

for (outcome_name in names(cf_results)) {
  valid <- cf_results[[outcome_name]]$valid_mask
  tau_hat <- cf_results[[outcome_name]]$tau_hat

  data_subset <- data_trim[valid, ] %>%
    mutate(cate = tau_hat)

  # Profile × Rural/Urban GATE
  gate_results <- data_subset %>%
    group_by(profile_label, rural_urban) %>%
    summarise(
      n = n(),
      mean_cate = mean(cate),
      se_cate = sd(cate) / sqrt(n()),
      ci_lower = mean_cate - 1.96 * se_cate,
      ci_upper = mean_cate + 1.96 * se_cate,
      .groups = "drop"
    )

  p <- ggplot(gate_results, aes(x = profile_label, y = mean_cate,
                                 fill = rural_urban)) +
    geom_col(position = position_dodge(width = 0.8), width = 0.7) +
    geom_errorbar(aes(ymin = ci_lower, ymax = ci_upper),
                  position = position_dodge(width = 0.8), width = 0.25) +
    scale_fill_manual(values = c("Rural" = "#2A9D8F", "Urban" = "#457B9D")) +
    theme_minimal(base_size = 12) +
    labs(title = sprintf("CATE by Profile and Geography: %s", outcome_name),
         x = "Civic Engagement Profile",
         y = "Conditional Average Treatment Effect",
         fill = "") +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))

  ggsave(sprintf("figures/cf_gate_%s.png", outcome_name),
         p, width = 12, height = 7, dpi = 300)
}

# --- 8. CATE Distribution (Violin Plots) --------------------------------------

for (outcome_name in names(cf_results)) {
  valid <- cf_results[[outcome_name]]$valid_mask
  tau_hat <- cf_results[[outcome_name]]$tau_hat

  violin_data <- data_trim[valid, ] %>%
    mutate(cate = tau_hat)

  p <- ggplot(violin_data, aes(x = profile_label, y = cate, fill = rural_urban)) +
    geom_violin(alpha = 0.6, position = position_dodge(width = 0.9)) +
    geom_boxplot(width = 0.1, position = position_dodge(width = 0.9),
                 outlier.shape = NA) +
    scale_fill_manual(values = c("Rural" = "#2A9D8F", "Urban" = "#457B9D")) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "red") +
    theme_minimal(base_size = 12) +
    labs(title = sprintf("Distribution of Individual Treatment Effects: %s",
                         outcome_name),
         x = "Civic Engagement Profile",
         y = "Individual CATE (τ̂(x))",
         fill = "") +
    theme(axis.text.x = element_text(angle = 30, hjust = 1))

  ggsave(sprintf("figures/cf_violin_%s.png", outcome_name),
         p, width = 12, height = 7, dpi = 300)
}

# --- 9. Variable Importance ---------------------------------------------------

for (outcome_name in names(cf_results)) {
  var_imp <- cf_results[[outcome_name]]$var_imp
  var_names <- colnames(X_trim)

  imp_data <- tibble(
    variable = var_names,
    importance = as.numeric(var_imp)
  ) %>%
    arrange(desc(importance)) %>%
    slice_head(n = 15)

  p <- ggplot(imp_data, aes(x = importance, y = reorder(variable, importance))) +
    geom_col(fill = "#264653", alpha = 0.8) +
    theme_minimal(base_size = 12) +
    labs(title = sprintf("Variable Importance (Heterogeneity Drivers): %s",
                         outcome_name),
         x = "Variable Importance",
         y = "")

  ggsave(sprintf("figures/cf_varimp_%s.png", outcome_name),
         p, width = 10, height = 7, dpi = 300)
}

# --- 10. Best Linear Projection -----------------------------------------------

for (outcome_name in names(cf_results)) {
  cf <- cf_results[[outcome_name]]$forest
  valid <- cf_results[[outcome_name]]$valid_mask

  blp <- best_linear_projection(cf, X_trim[valid, ])
  cat(sprintf("\n--- Best Linear Projection: %s ---\n", outcome_name))
  print(blp)
}

# --- 11. Geographic CATE Map (State-Level) ------------------------------------

library(sf)
library(tigris)

us_states <- states(cb = TRUE) %>%
  filter(!STATEFP %in% c("02", "15", "60", "66", "69", "72", "78"))

for (outcome_name in names(cf_results)) {
  valid <- cf_results[[outcome_name]]$valid_mask
  tau_hat <- cf_results[[outcome_name]]$tau_hat

  state_cate <- data_trim[valid, ] %>%
    mutate(cate = tau_hat) %>%
    group_by(state_fips) %>%
    summarise(mean_cate = mean(cate), .groups = "drop") %>%
    mutate(STATEFP = sprintf("%02d", state_fips))

  map_data <- us_states %>%
    left_join(state_cate, by = "STATEFP")

  p <- ggplot(map_data) +
    geom_sf(aes(fill = mean_cate), color = "white", size = 0.2) +
    scale_fill_gradient2(
      low = "#457B9D", mid = "white", high = "#E63946",
      midpoint = 0, name = "Mean CATE"
    ) +
    theme_void(base_size = 14) +
    labs(title = sprintf("Geographic Distribution of Treatment Effects: %s",
                         outcome_name))

  ggsave(sprintf("figures/cf_map_%s.png", outcome_name),
         p, width = 12, height = 8, dpi = 300)
}

# --- 12. Save Results ---------------------------------------------------------

saveRDS(cf_results, "data/causal_forest_results.rds")

# Export CATE predictions for SHAP analysis in Python
for (outcome_name in names(cf_results)) {
  valid <- cf_results[[outcome_name]]$valid_mask
  tau_hat <- cf_results[[outcome_name]]$tau_hat

  export_data <- cbind(
    X_trim[valid, ],
    cate = tau_hat
  )

  write.csv(export_data,
            sprintf("data/cate_export_%s.csv", outcome_name),
            row.names = FALSE)
}

cat("\nPhase 2 (Causal Forest) complete. Results saved.\n")
