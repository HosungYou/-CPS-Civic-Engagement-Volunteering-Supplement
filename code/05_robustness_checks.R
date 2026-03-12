# ==============================================================================
# 05_robustness_checks.R
# ROBUSTNESS ANALYSES for "Bowling Alone, Scrolling Together"
#
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Tests:
#   A. APC — Fixed age-band comparison (25-30 across waves; age²)
#   B. Membership as direct control in main model
#   C. Continuous socialization (log-linear) vs categorical First Step
#   D. Alternative generation boundaries (±2 years)
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)

set.seed(20260309)

# --- 0. Load Data & Survey Design --------------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Full sample: N = %s\n", format(nrow(data), big.mark = ",")))

options(survey.lonely.psu = "adjust")
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                  weights = ~VLSUPPWT, nest = TRUE, data = data)

# ==============================================================================
# A. APC TEST — Fixed Age-Band Comparison
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("A. APC TEST: Fixed Age-Band Across Waves\n")
cat(strrep("=", 70), "\n")

# Test A1: Ages 25-30 (Millennials in all waves — no Gen Z contamination)
cat("\n--- Test A1: Ages 25-30 across waves (all Millennials) ---\n")
data_2530 <- data %>% filter(AGE >= 25, AGE <= 30)
cat(sprintf("N (ages 25-30): %s\n", format(nrow(data_2530), big.mark = ",")))
cat("Wave x Generation:\n")
print(table(data_2530$wave, data_2530$generation))

svy_2530 <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                        weights = ~VLSUPPWT, nest = TRUE, data = data_2530)

m_2530 <- svyglm(
  volunteered ~ soc_factor * wave + AGE + female + race_eth + ba_plus +
    employed + married + faminc_log + metro + region,
  design = svy_2530,
  family = quasibinomial()
)

cat("\nWald test for soc_factor x wave interaction (ages 25-30):\n")
regTermTest(m_2530, ~ soc_factor:wave)

pred_2530 <- predictions(m_2530,
  newdata = datagrid(soc_factor = unique, wave = unique),
  type = "response"
)
cat("\nPredicted probabilities (ages 25-30 by wave):\n")
pred_2530_df <- as.data.frame(pred_2530[, c("soc_factor", "wave", "estimate", "conf.low", "conf.high")])
print(pred_2530_df)

# Test A2: Ages 18-24 across all waves
cat("\n--- Test A2: Ages 18-24 across waves ---\n")
data_1824 <- data %>% filter(AGE >= 18, AGE <= 24)
cat(sprintf("N (ages 18-24): %s\n", format(nrow(data_1824), big.mark = ",")))
cat("Wave x Generation:\n")
print(table(data_1824$wave, data_1824$generation))

svy_1824 <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                        weights = ~VLSUPPWT, nest = TRUE, data = data_1824)

m_1824 <- svyglm(
  volunteered ~ soc_factor * wave + AGE + female + race_eth + ba_plus +
    employed + married + faminc_log + metro + region,
  design = svy_1824,
  family = quasibinomial()
)

cat("\nWald test for soc_factor x wave interaction (ages 18-24):\n")
regTermTest(m_1824, ~ soc_factor:wave)

pred_1824 <- predictions(m_1824,
  newdata = datagrid(soc_factor = unique, wave = unique),
  type = "response"
)
cat("\nPredicted probabilities (ages 18-24 by wave):\n")
pred_1824_df <- as.data.frame(pred_1824[, c("soc_factor", "wave", "estimate", "conf.low", "conf.high")])
print(pred_1824_df)

# Test A3: Full model with age-squared
cat("\n--- Test A3: Full model with age-squared ---\n")
data$AGE_sq <- data$AGE^2
svy_agesq <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                         weights = ~VLSUPPWT, nest = TRUE, data = data)

m_agesq <- svyglm(
  volunteered ~ soc_factor * generation + AGE + AGE_sq +
    female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_agesq,
  family = quasibinomial()
)

cat("\nGeneration interaction with age-squared control:\n")
regTermTest(m_agesq, ~ soc_factor:generation)

ame_agesq <- avg_slopes(m_agesq, variables = "soc_factor", by = "generation")
cat("\nAME with age-squared control (First Step contrasts):\n")
ame_first <- ame_agesq %>% filter(contrast == "Few times/yr - Not at all")
print(as.data.frame(ame_first[, c("generation", "estimate", "conf.low", "conf.high", "p.value")]))


# ==============================================================================
# B. MEMBERSHIP AS DIRECT CONTROL
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("B. MEMBERSHIP CONTROL — Testing Institutional Sorting Confound\n")
cat(strrep("=", 70), "\n")

data_mem <- data %>% filter(!is.na(membership))
cat(sprintf("N with valid membership: %s\n", format(nrow(data_mem), big.mark = ",")))

svy_mem <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                      weights = ~VLSUPPWT, nest = TRUE, data = data_mem)

# Model without membership
m_nomem <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_mem,
  family = quasibinomial()
)

# Model with membership
m_withmem <- svyglm(
  volunteered ~ soc_factor * generation + membership +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_mem,
  family = quasibinomial()
)

cat("\n--- Without membership control ---\n")
ame_nomem <- avg_slopes(m_nomem, variables = "soc_factor", by = "generation")
first_nomem <- ame_nomem %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, conf.low, conf.high)
cat("First Step AME:\n")
print(as.data.frame(first_nomem))

cat("\n--- With membership control ---\n")
ame_withmem <- avg_slopes(m_withmem, variables = "soc_factor", by = "generation")
first_withmem <- ame_withmem %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, conf.low, conf.high)
cat("First Step AME:\n")
print(as.data.frame(first_withmem))

cat("\n--- First Step Effect attenuation with membership control ---\n")
comparison <- first_nomem %>%
  rename(est_no_mem = estimate, lo_no = conf.low, hi_no = conf.high) %>%
  left_join(
    first_withmem %>%
      rename(est_w_mem = estimate, lo_w = conf.low, hi_w = conf.high),
    by = "generation"
  ) %>%
  mutate(
    attenuation_pct = round((1 - est_w_mem / est_no_mem) * 100, 1)
  )
print(as.data.frame(comparison))


# ==============================================================================
# C. CONTINUOUS SOCIALIZATION — First Step Threshold Test
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("C. CONTINUOUS SOCIALIZATION — Threshold vs Concavity\n")
cat(strrep("=", 70), "\n")

# Model 1: Linear continuous
m_linear <- svyglm(
  volunteered ~ CESOCIALIZE * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy,
  family = quasibinomial()
)

# Model 2: Log-transformed continuous
data$soc_log <- log(data$CESOCIALIZE)
svy_log <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                      weights = ~VLSUPPWT, nest = TRUE, data = data)

m_log <- svyglm(
  volunteered ~ soc_log * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_log,
  family = quasibinomial()
)

# Model 3: Quadratic continuous
data$soc_sq <- data$CESOCIALIZE^2
svy_sq <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                     weights = ~VLSUPPWT, nest = TRUE, data = data)

m_quad <- svyglm(
  volunteered ~ (CESOCIALIZE + soc_sq) * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_sq,
  family = quasibinomial()
)

# Predicted probabilities at each level
cat("\n--- Predicted probabilities: Categorical vs Continuous models ---\n")

# Categorical (reference)
m_cat <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy,
  family = quasibinomial()
)
pred_cat <- predictions(m_cat,
  newdata = datagrid(soc_factor = unique, generation = unique),
  type = "response"
)

pred_lin <- predictions(m_linear,
  newdata = datagrid(CESOCIALIZE = 1:6, generation = unique),
  type = "response"
)

pred_grid_log <- datagrid(model = m_log, CESOCIALIZE = 1:6, generation = unique)
pred_grid_log$soc_log <- log(pred_grid_log$CESOCIALIZE)
pred_logmod <- predictions(m_log, newdata = pred_grid_log, type = "response")

pred_grid_quad <- datagrid(model = m_quad, CESOCIALIZE = 1:6, generation = unique)
pred_grid_quad$soc_sq <- pred_grid_quad$CESOCIALIZE^2
pred_quadmod <- predictions(m_quad, newdata = pred_grid_quad, type = "response")

cat("Categorical model (reference):\n")
cat_df <- as.data.frame(pred_cat[, c("soc_factor", "generation", "estimate")])
print(cat_df %>% pivot_wider(names_from = generation, values_from = estimate))

cat("\nLinear continuous:\n")
lin_df <- as.data.frame(pred_lin[, c("CESOCIALIZE", "generation", "estimate")])
print(lin_df %>% pivot_wider(names_from = generation, values_from = estimate))

cat("\nLog-transformed:\n")
log_df <- as.data.frame(pred_logmod[, c("CESOCIALIZE", "generation", "estimate")])
print(log_df %>% pivot_wider(names_from = generation, values_from = estimate))

cat("\nQuadratic:\n")
quad_df <- as.data.frame(pred_quadmod[, c("CESOCIALIZE", "generation", "estimate")])
print(quad_df %>% pivot_wider(names_from = generation, values_from = estimate))

# Key test: Does categorical 0->1 transition exceed smooth prediction?
cat("\n--- First Step Excess Test ---\n")
cat("Difference between categorical and log-smooth predicted probabilities:\n")
cat("(Positive = categorical jump exceeds smooth curve = genuine threshold)\n\n")

for (gen in levels(data$generation)) {
  cat_vals <- cat_df %>% filter(generation == gen) %>% pull(estimate)
  log_vals <- log_df %>% filter(generation == gen) %>% pull(estimate)
  cat_jump <- cat_vals[2] - cat_vals[1]  # categorical 0->1
  log_jump <- log_vals[2] - log_vals[1]  # smooth 0->1
  excess <- cat_jump - log_jump
  cat(sprintf("  %s: Cat jump=%.3f, Log jump=%.3f, Excess=%.3f (%s)\n",
              gen, cat_jump, log_jump, excess,
              ifelse(excess > 0.005, "THRESHOLD", "concavity")))
}


# ==============================================================================
# D. ALTERNATIVE GENERATION BOUNDARIES
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("D. SENSITIVITY TO GENERATION BOUNDARIES (+/-2 years)\n")
cat(strrep("=", 70), "\n")

data_alt <- data %>%
  mutate(
    gen_alt = factor(
      case_when(
        birth_year >= 1995 ~ "Gen Z (1995+)",
        birth_year >= 1979 ~ "Millennial",
        birth_year >= 1963 ~ "Gen X",
        birth_year >= 1944 ~ "Boomer",
        TRUE ~ "Silent"
      ),
      levels = c("Gen Z (1995+)", "Millennial", "Gen X", "Boomer", "Silent")
    )
  )

svy_alt <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                       weights = ~VLSUPPWT, nest = TRUE, data = data_alt)

m_alt <- svyglm(
  volunteered ~ soc_factor * gen_alt +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_alt,
  family = quasibinomial()
)

cat("\nInteraction test with shifted boundaries (Gen Z = 1995+):\n")
regTermTest(m_alt, ~ soc_factor:gen_alt)

ame_alt <- avg_slopes(m_alt, variables = "soc_factor", by = "gen_alt")
first_alt <- ame_alt %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(gen_alt, estimate, conf.low, conf.high)
cat("\nFirst Step AME with shifted boundaries:\n")
print(as.data.frame(first_alt))


# ==============================================================================
# SUMMARY
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("ROBUSTNESS CHECKS SUMMARY\n")
cat(strrep("=", 70), "\n")
cat("
A. APC Test:
   - Ages 25-30 (all Millennials): socialization-volunteering across waves
   - Ages 18-24: wave effects in youngest age band
   - Age-squared: generational effects with nonlinear age control

B. Membership Control:
   - Tests institutional sorting confound (Beyerlein & Hipp, 2006)
   - First Step Effect survival with membership controlled

C. Continuous Socialization:
   - Categorical vs linear, log, and quadratic specifications
   - First Step Excess Test: genuine threshold vs concavity

D. Generation Boundaries:
   - Gen Z boundary shifted to 1995 (from 1997)
")

cat("\nRobustness checks complete.\n")
