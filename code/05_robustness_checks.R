# ==============================================================================
# 05_robustness_checks.R
# Robustness and Sensitivity Analyses
#
# Study: Heterogeneous Effects of Organized Volunteering on Civic Engagement
# Authors: Hosung You & Suzanna Windon
# ==============================================================================

library(tidyverse)
library(grf)
library(dbarts)       # BART
library(DoubleML)     # Double Machine Learning
library(mlr3)
library(mlr3learners)
library(ggplot2)

set.seed(20240224)

# --- 1. Load Data and Results -------------------------------------------------
data <- readRDS("data/cev_with_profiles.rds")
cf_results <- readRDS("data/causal_forest_results.rds")

cat("Robustness checks initialized.\n")

# ==============================================================================
# CHECK 1: BART Comparison
# ==============================================================================

run_bart_comparison <- function(X, Y, W, weights, outcome_name) {
  cat(sprintf("\n--- BART Comparison: %s ---\n", outcome_name))

  # Fit BART for treated and control separately
  treated_idx <- W == 1
  control_idx <- W == 0

  bart_treated <- bart(
    x.train = X[treated_idx, ],
    y.train = Y[treated_idx],
    x.test = X,
    ntree = 200,
    nskip = 100,
    ndpost = 1000,
    verbose = FALSE
  )

  bart_control <- bart(
    x.train = X[control_idx, ],
    y.train = Y[control_idx],
    x.test = X,
    ntree = 200,
    nskip = 100,
    ndpost = 1000,
    verbose = FALSE
  )

  # Individual treatment effects
  tau_bart <- colMeans(bart_treated$yhat.test) - colMeans(bart_control$yhat.test)
  ate_bart <- mean(tau_bart)
  se_bart <- sd(tau_bart) / sqrt(length(tau_bart))

  cat(sprintf("BART ATE = %.4f (SE = %.4f)\n", ate_bart, se_bart))

  return(list(tau = tau_bart, ate = ate_bart, se = se_bart))
}

# ==============================================================================
# CHECK 2: Double Machine Learning (DML)
# ==============================================================================

run_dml_comparison <- function(data_df, outcome_var, outcome_name) {
  cat(sprintf("\n--- DML Comparison: %s ---\n", outcome_name))

  # Prepare data for DoubleML
  dml_data <- data_df %>%
    select(Y = all_of(outcome_var),
           D = volunteered_org,
           age, female, married, has_children,
           employed, homeowner, is_rural) %>%
    drop_na()

  # Create DoubleML data object
  ml_data <- DoubleMLData$new(
    dml_data,
    y_col = "Y",
    d_cols = "D"
  )

  # Random forest learners
  ml_g <- lrn("regr.ranger", num.trees = 500)
  ml_m <- lrn("classif.ranger", num.trees = 500)

  # Partially Linear Regression Model
  dml_plr <- DoubleMLPLR$new(
    ml_data,
    ml_g = ml_g,
    ml_m = ml_m,
    n_folds = 5
  )

  dml_plr$fit()

  cat(sprintf("DML ATE = %.4f (SE = %.4f)\n",
              dml_plr$coef, dml_plr$se))

  return(list(
    coef = dml_plr$coef,
    se = dml_plr$se,
    ci = dml_plr$confint()
  ))
}

# ==============================================================================
# CHECK 3: Wave-Specific Analysis (Temporal Stability)
# ==============================================================================

run_wave_specific <- function(data, X_formula, outcome_name) {
  cat(sprintf("\n--- Wave-Specific Analysis: %s ---\n", outcome_name))

  waves <- unique(data$YEAR)
  wave_results <- list()

  for (w in waves) {
    cat(sprintf("  Wave %d...\n", w))

    data_w <- data %>% filter(YEAR == w)

    X_w <- model.matrix(X_formula, data = data_w)
    W_w <- data_w$volunteered_org
    Y_w <- data_w[[paste0(outcome_name, "_z")]]
    weights_w <- data_w$VLSUPPWT / mean(data_w$VLSUPPWT)

    valid <- !is.na(Y_w)

    cf_w <- causal_forest(
      X = X_w[valid, ],
      Y = Y_w[valid],
      W = W_w[valid],
      sample.weights = weights_w[valid],
      num.trees = 2000,
      honesty = TRUE,
      seed = 20240224
    )

    ate_w <- average_treatment_effect(cf_w)

    wave_results[[as.character(w)]] <- list(
      ate = ate_w[1],
      se = ate_w[2],
      n = sum(valid)
    )

    cat(sprintf("  ATE = %.4f (SE = %.4f), N = %d\n",
                ate_w[1], ate_w[2], sum(valid)))
  }

  return(wave_results)
}

# ==============================================================================
# CHECK 4: Propensity Score Trimming Sensitivity
# ==============================================================================

run_trimming_sensitivity <- function(cf_result, e_hat, thresholds) {
  cat("\n--- Trimming Sensitivity Analysis ---\n")

  trim_results <- tibble()

  for (thresh in thresholds) {
    mask <- e_hat > thresh & e_hat < (1 - thresh)
    n_retained <- sum(mask)
    pct_retained <- mean(mask) * 100

    # This is a simplified version - in practice, re-estimate the forest
    tau_trimmed <- cf_result$tau_hat[mask]
    ate_trimmed <- mean(tau_trimmed)
    se_trimmed <- sd(tau_trimmed) / sqrt(length(tau_trimmed))

    trim_results <- bind_rows(trim_results, tibble(
      threshold = thresh,
      n = n_retained,
      pct = pct_retained,
      ate = ate_trimmed,
      se = se_trimmed
    ))

    cat(sprintf("  Threshold = %.2f: ATE = %.4f, N = %d (%.1f%%)\n",
                thresh, ate_trimmed, n_retained, pct_retained))
  }

  return(trim_results)
}

# ==============================================================================
# CHECK 5: Comparison Summary Table
# ==============================================================================

create_comparison_table <- function(cf_ate, bart_ate, dml_ate, outcome_name) {
  comparison <- tibble(
    Method = c("Causal Forest (GRF)", "BART", "Double ML (PLR)"),
    ATE = c(cf_ate[1], bart_ate$ate, dml_ate$coef),
    SE = c(cf_ate[2], bart_ate$se, dml_ate$se),
    CI_lower = ATE - 1.96 * SE,
    CI_upper = ATE + 1.96 * SE
  )

  cat(sprintf("\n--- Method Comparison: %s ---\n", outcome_name))
  print(comparison)

  # Visualization
  p <- ggplot(comparison, aes(x = ATE, y = Method)) +
    geom_point(size = 3, color = "#264653") +
    geom_errorbarh(aes(xmin = CI_lower, xmax = CI_upper),
                   height = 0.2, color = "#264653") +
    geom_vline(xintercept = 0, linetype = "dashed", color = "red") +
    theme_minimal(base_size = 14) +
    labs(title = sprintf("Method Comparison: %s", outcome_name),
         x = "Average Treatment Effect",
         y = "")

  ggsave(sprintf("figures/robustness_comparison_%s.png", outcome_name),
         p, width = 10, height = 5, dpi = 300)

  return(comparison)
}

# ==============================================================================
# EXECUTE ALL ROBUSTNESS CHECKS
# ==============================================================================

cat("\n")
cat("================================================================\n")
cat("  ROBUSTNESS AND SENSITIVITY ANALYSES\n")
cat("================================================================\n")

# Note: Actual execution requires the full data pipeline to be run first.
# The functions above provide the complete framework for all robustness checks.

cat("\nRobustness check framework ready.\n")
cat("Run after completing Phase 1 (LPA) and Phase 2 (Causal Forest).\n")

# Example execution flow:
# bart_results <- run_bart_comparison(X_trim, Y_trim, W_trim, weights_trim, "political")
# dml_results <- run_dml_comparison(data, "political_participation_z", "political")
# wave_results <- run_wave_specific(data, formula, "political_participation")
# trim_results <- run_trimming_sensitivity(cf_results[["political"]], e_hat,
#                                           c(0.01, 0.05, 0.10, 0.15, 0.20))
# comparison <- create_comparison_table(cf_ate, bart_results, dml_results, "political")
