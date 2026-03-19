# ==============================================================================
# 14_apa_tables.R — Publication-Quality APA 7th Edition Tables
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
#
# Generates 5 CSV tables for the manuscript:
#   Table 1: Sample Characteristics (Expanded)
#   Table 2: Logistic Regression Results
#   Table 3: First Step AME
#   Table 4: LPA Model Fit
#   Table 5: LPA Profile Characteristics
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)
library(broom)
library(mclust)

setwd("/Volumes/External SSD/Projects/Research/-CPS-Civic-Engagement-Volunteering-Supplement")
options(survey.lonely.psu = "adjust")
dir.create("tables", showWarnings = FALSE)

# --- Load data ----------------------------------------------------------------
cat("Loading data...\n")
data <- readRDS("data/cev_clean.rds")
models <- readRDS("data/logistic_models.rds")
data_lpa <- readRDS("data/cev_with_profiles.rds")
profile_summary <- readRDS("data/profile_summary.rds")

cat(sprintf("Main sample: N = %s\n", format(nrow(data), big.mark = ",")))

# --- Survey design ------------------------------------------------------------
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                 weights = ~VLSUPPWT, nest = TRUE, data = data)

# Ensure soc_factor is on the design for later use
svy <- update(svy, soc_factor = soc_factor)

# ==============================================================================
# TABLE 1: Sample Characteristics (Expanded)
# ==============================================================================
cat("\n========== TABLE 1: Sample Characteristics ==========\n")

# Define generation order
gen_order <- c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent")

# Helper: format M (SD)
fmt_msd <- function(m, s) sprintf("%.1f (%.1f)", m, s)

# Helper: format n (%)
fmt_npct <- function(n_val, pct_val) sprintf("%s (%.1f)", format(round(n_val), big.mark = ","), pct_val)

# --- Compute all statistics by generation and total ---------------------------

# Create a generation variable that includes "Total"
data_t1 <- data %>%
  mutate(
    min_soc = as.numeric(!is.na(soc_factor) & soc_factor %in% c("Not at all", "Few times/yr"))
  )

# Add to survey design
svy_t1 <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                     weights = ~VLSUPPWT, nest = TRUE, data = data_t1)

# Function to compute stats for a subset
compute_stats <- function(svy_obj, label) {
  # Unweighted N
  n_uw <- nrow(svy_obj$variables)

  # Age: weighted M (SD)
  age_m <- coef(svymean(~AGE, svy_obj))
  age_v <- coef(svyvar(~AGE, svy_obj))
  age_sd <- sqrt(age_v)

  # Female: weighted n (%)
  female_p <- coef(svymean(~female, svy_obj)) * 100
  female_n <- sum(svy_obj$variables$female)

  # Race/ethnicity: weighted %
  race_p <- coef(svymean(~factor(race_eth), svy_obj)) * 100
  # Order: White NH, Black NH, Hispanic, Asian NH, Other
  race_names <- c("White NH", "Black NH", "Hispanic", "Asian NH", "Other")
  race_n <- table(svy_obj$variables$race_eth)[race_names]

  # BA+
  ba_p <- coef(svymean(~ba_plus, svy_obj)) * 100
  ba_n <- sum(svy_obj$variables$ba_plus)

  # Employed
  emp_p <- coef(svymean(~employed, svy_obj)) * 100
  emp_n <- sum(svy_obj$variables$employed)

  # Married
  mar_p <- coef(svymean(~married, svy_obj)) * 100
  mar_n <- sum(svy_obj$variables$married)

  # Metropolitan
  metro_p <- coef(svymean(~metro, svy_obj)) * 100
  metro_n <- sum(svy_obj$variables$metro)

  # Family income: weighted M (SD)
  inc_m <- coef(svymean(~faminc_mid, svy_obj))
  inc_v <- coef(svyvar(~faminc_mid, svy_obj))
  inc_sd <- sqrt(inc_v)

  # Socialization frequency: weighted M (SD) -- use socialize (1-6 numeric)
  soc_sub <- subset(svy_obj, !is.na(socialize))
  soc_m <- coef(svymean(~socialize, soc_sub))
  soc_v <- coef(svyvar(~socialize, soc_sub))
  soc_sd <- sqrt(soc_v)

  # Minimal socialization (Not at all or Few times/yr)
  min_soc_sub <- subset(svy_obj, !is.na(min_soc))
  min_soc_p <- coef(svymean(~min_soc, min_soc_sub)) * 100
  min_soc_n <- sum(svy_obj$variables$min_soc, na.rm = TRUE)

  # Civic SM
  csm_p <- coef(svymean(~civic_sm, svy_obj)) * 100
  csm_n <- sum(svy_obj$variables$civic_sm)

  # Volunteering
  vol_p <- coef(svymean(~volunteered, svy_obj)) * 100
  vol_n <- sum(svy_obj$variables$volunteered)

  # Build results
  tibble(
    Variable = c(
      "N (unweighted)",
      "Age, M (SD)",
      "Female, n (%)",
      "Race/ethnicity",
      "  White NH, n (%)",
      "  Black NH, n (%)",
      "  Hispanic, n (%)",
      "  Asian NH, n (%)",
      "  Other, n (%)",
      "Education BA+, n (%)",
      "Employed, n (%)",
      "Married, n (%)",
      "Metropolitan, n (%)",
      "Family income ($), M (SD)",
      "Socialization freq., M (SD)",
      "Minimal socialization, n (%)",
      "Civic social media use, n (%)",
      "Volunteered, n (%)"
    ),
    !!label := c(
      format(n_uw, big.mark = ","),
      fmt_msd(age_m, age_sd),
      fmt_npct(female_n, female_p),
      "",
      fmt_npct(race_n["White NH"], race_p[paste0("factor(race_eth)", "White NH")]),
      fmt_npct(race_n["Black NH"], race_p[paste0("factor(race_eth)", "Black NH")]),
      fmt_npct(race_n["Hispanic"], race_p[paste0("factor(race_eth)", "Hispanic")]),
      fmt_npct(race_n["Asian NH"], race_p[paste0("factor(race_eth)", "Asian NH")]),
      fmt_npct(race_n["Other"], race_p[paste0("factor(race_eth)", "Other")]),
      fmt_npct(ba_n, ba_p),
      fmt_npct(emp_n, emp_p),
      fmt_npct(mar_n, mar_p),
      fmt_npct(metro_n, metro_p),
      sprintf("%s (%s)", format(round(inc_m), big.mark = ","), format(round(inc_sd), big.mark = ",")),
      fmt_msd(soc_m, soc_sd),
      fmt_npct(min_soc_n, min_soc_p),
      fmt_npct(csm_n, csm_p),
      fmt_npct(vol_n, vol_p)
    )
  )
}

# Total
cat("  Computing total statistics...\n")
t1_total <- compute_stats(svy_t1, "Total")

# By generation
t1_gens <- list()
for (g in gen_order) {
  cat(sprintf("  Computing statistics for %s...\n", g))
  svy_sub <- subset(svy_t1, generation == g)
  t1_gens[[g]] <- compute_stats(svy_sub, g)
}

# Merge
table1 <- t1_total
for (g in gen_order) {
  table1 <- left_join(table1, t1_gens[[g]], by = "Variable")
}

# --- Test statistics ----------------------------------------------------------
cat("  Computing test statistics...\n")

# Helper: format p-value with significance stars
fmt_p <- function(p) {
  stars <- ifelse(p < .001, "***", ifelse(p < .01, "**", ifelse(p < .05, "*", "")))
  return(stars)
}

test_stats <- character(nrow(table1))

# Row indices (1-based)
# 1: N -- no test
# 2: Age -- F test (continuous)
# 3: Female -- chi-sq
# 4: Race header -- no test
# 5-9: Race breakdowns -- single chi-sq for race_eth
# 10: BA+ -- chi-sq
# 11: Employed -- chi-sq
# 12: Married -- chi-sq
# 13: Metro -- chi-sq
# 14: Family income -- F test
# 15: Socialization freq -- F test
# 16: Minimal socialization -- chi-sq
# 17: Civic SM -- chi-sq
# 18: Volunteered -- chi-sq

# Age: svyglm with generation as predictor
cat("    Age F-test...\n")
m_age <- svyglm(AGE ~ generation, design = svy_t1)
rt_age <- regTermTest(m_age, ~generation)
test_stats[2] <- sprintf("F(%.0f, %.0f) = %.1f%s", as.numeric(rt_age$df), as.numeric(rt_age$ddf), as.numeric(rt_age$Ftest), fmt_p(as.numeric(rt_age$p)))

# Female: chi-sq
cat("    Female chi-sq...\n")
chi_female <- svychisq(~female + generation, svy_t1, statistic = "F")
test_stats[3] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_female$parameter[1], chi_female$parameter[2], chi_female$statistic, fmt_p(chi_female$p.value))

# Race/ethnicity: chi-sq (put on the header row)
cat("    Race chi-sq...\n")
chi_race <- svychisq(~race_eth + generation, svy_t1, statistic = "F")
test_stats[4] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_race$parameter[1], chi_race$parameter[2], chi_race$statistic, fmt_p(chi_race$p.value))

# BA+
cat("    BA+ chi-sq...\n")
chi_ba <- svychisq(~ba_plus + generation, svy_t1, statistic = "F")
test_stats[10] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_ba$parameter[1], chi_ba$parameter[2], chi_ba$statistic, fmt_p(chi_ba$p.value))

# Employed
cat("    Employed chi-sq...\n")
chi_emp <- svychisq(~employed + generation, svy_t1, statistic = "F")
test_stats[11] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_emp$parameter[1], chi_emp$parameter[2], chi_emp$statistic, fmt_p(chi_emp$p.value))

# Married
cat("    Married chi-sq...\n")
chi_mar <- svychisq(~married + generation, svy_t1, statistic = "F")
test_stats[12] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_mar$parameter[1], chi_mar$parameter[2], chi_mar$statistic, fmt_p(chi_mar$p.value))

# Metro
cat("    Metro chi-sq...\n")
chi_met <- svychisq(~metro + generation, svy_t1, statistic = "F")
test_stats[13] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_met$parameter[1], chi_met$parameter[2], chi_met$statistic, fmt_p(chi_met$p.value))

# Family income: F test
cat("    Income F-test...\n")
m_inc <- svyglm(faminc_mid ~ generation, design = svy_t1)
rt_inc <- regTermTest(m_inc, ~generation)
test_stats[14] <- sprintf("F(%.0f, %.0f) = %.1f%s", as.numeric(rt_inc$df), as.numeric(rt_inc$ddf), as.numeric(rt_inc$Ftest), fmt_p(as.numeric(rt_inc$p)))

# Socialization freq: F test
cat("    Socialization F-test...\n")
svy_t1_soc <- subset(svy_t1, !is.na(socialize))
m_soc <- svyglm(socialize ~ generation, design = svy_t1_soc)
rt_soc <- regTermTest(m_soc, ~generation)
test_stats[15] <- sprintf("F(%.0f, %.0f) = %.1f%s", as.numeric(rt_soc$df), as.numeric(rt_soc$ddf), as.numeric(rt_soc$Ftest), fmt_p(as.numeric(rt_soc$p)))

# Minimal socialization: chi-sq
cat("    Min soc chi-sq...\n")
svy_t1_ms <- subset(svy_t1, !is.na(min_soc))
chi_ms <- svychisq(~min_soc + generation, svy_t1_ms, statistic = "F")
test_stats[16] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_ms$parameter[1], chi_ms$parameter[2], chi_ms$statistic, fmt_p(chi_ms$p.value))

# Civic SM: chi-sq
cat("    Civic SM chi-sq...\n")
chi_csm <- svychisq(~civic_sm + generation, svy_t1, statistic = "F")
test_stats[17] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_csm$parameter[1], chi_csm$parameter[2], chi_csm$statistic, fmt_p(chi_csm$p.value))

# Volunteered: chi-sq
cat("    Volunteered chi-sq...\n")
chi_vol <- svychisq(~volunteered + generation, svy_t1, statistic = "F")
test_stats[18] <- sprintf("F(%.0f, %.0f) = %.1f%s", chi_vol$parameter[1], chi_vol$parameter[2], chi_vol$statistic, fmt_p(chi_vol$p.value))

table1$Test <- test_stats

# Write Table 1
write_csv(table1, "tables/table1_sample_characteristics.csv")
cat("\nTable 1 written to tables/table1_sample_characteristics.csv\n")
print(table1, n = 20, width = Inf)


# ==============================================================================
# TABLE 2: Logistic Regression Results
# ==============================================================================
cat("\n========== TABLE 2: Logistic Regression Results ==========\n")

m1 <- models$m1

# --- Part A: Model 1 coefficients as OR with 95% CI --------------------------
cat("  Extracting Model 1 coefficients...\n")

coefs <- coef(m1)
se_vals <- sqrt(diag(vcov(m1)))
ci_raw <- confint(m1)

# Build coefficient table
coef_names <- names(coefs)
or_vals <- exp(coefs)
ci_lo <- exp(ci_raw[, 1])
ci_hi <- exp(ci_raw[, 2])
z_vals <- coefs / se_vals
p_vals <- 2 * pnorm(-abs(z_vals))

# Create readable labels
label_map <- c(
  "(Intercept)" = "(Intercept)",
  "soc_factorFew times/yr" = "Socialization: Few times/yr (ref: Not at all)",
  "soc_factorOnce/mo" = "Socialization: Once/mo",
  "soc_factorFew times/mo" = "Socialization: Few times/mo",
  "soc_factorFew times/wk" = "Socialization: Few times/wk",
  "soc_factorDaily" = "Socialization: Daily",
  "generationMillennial" = "Generation: Millennial (ref: Gen Z)",
  "generationGen X" = "Generation: Gen X",
  "generationBoomer" = "Generation: Boomer",
  "generationSilent" = "Generation: Silent",
  "AGE" = "Age",
  "female" = "Female",
  "race_ethBlack NH" = "Race: Black NH (ref: Asian NH)",
  "race_ethHispanic" = "Race: Hispanic",
  "race_ethOther" = "Race: Other",
  "race_ethWhite NH" = "Race: White NH",
  "ba_plus" = "Education: BA+",
  "employed" = "Employed",
  "married" = "Married",
  "faminc_log" = "Family income (log)",
  "metro" = "Metropolitan",
  "regionNortheast" = "Region: Northeast (ref: Midwest)",
  "regionSouth" = "Region: South",
  "regionWest" = "Region: West",
  "post_covid" = "Post-COVID period"
)

# Format p-values (ensure scalar input)
fmt_pval <- function(p) {
  p <- as.numeric(p)
  sapply(p, function(x) {
    if (x < .001) return("< .001")
    return(sprintf("%.3f", x))
  })
}

# Build the main effects portion
main_vars <- names(label_map)
main_idx <- match(main_vars, coef_names)
main_idx <- main_idx[!is.na(main_idx)]

# Build full table (main effects + interactions)
reg_table <- tibble(
  Variable = character(),
  OR = character(),
  `95% CI` = character(),
  p = character()
)

# Main effects section
reg_table <- reg_table %>%
  add_row(Variable = "Main Effects", OR = "", `95% CI` = "", p = "")

for (v in coef_names) {
  lbl <- if (v %in% names(label_map)) label_map[v] else v
  # Clean up interaction labels
  if (grepl(":", v)) {
    lbl <- gsub("soc_factor", "Soc: ", lbl)
    lbl <- gsub("generation", "Gen: ", lbl)
    lbl <- gsub(":", " x ", lbl)
  }
  i <- which(coef_names == v)

  # Skip intercept in display but include for completeness
  if (v == "(Intercept)") next

  is_interaction <- grepl(":", v)
  if (!is_interaction) {
    reg_table <- reg_table %>%
      add_row(
        Variable = as.character(lbl),
        OR = sprintf("%.3f", or_vals[i]),
        `95% CI` = sprintf("[%.3f, %.3f]", ci_lo[i], ci_hi[i]),
        p = fmt_pval(p_vals[i])
      )
  }
}

# Interaction section header
reg_table <- reg_table %>%
  add_row(Variable = "", OR = "", `95% CI` = "", p = "") %>%
  add_row(Variable = "Socialization x Generation Interactions", OR = "", `95% CI` = "", p = "")

# Interaction terms
int_vars <- coef_names[grepl(":", coef_names)]
for (v in int_vars) {
  i <- which(coef_names == v)
  lbl <- v
  lbl <- gsub("soc_factor", "", lbl)
  lbl <- gsub("generation", "", lbl)
  lbl <- gsub(":", " x ", lbl)

  reg_table <- reg_table %>%
    add_row(
      Variable = paste0("  ", lbl),
      OR = sprintf("%.3f", or_vals[i]),
      `95% CI` = sprintf("[%.3f, %.3f]", ci_lo[i], ci_hi[i]),
      p = fmt_pval(p_vals[i])
    )
}

# --- Part B: Wald F tests for all 5 models -----------------------------------
cat("  Computing Wald F tests for all models...\n")

reg_table <- reg_table %>%
  add_row(Variable = "", OR = "", `95% CI` = "", p = "") %>%
  add_row(Variable = "Interaction Wald Tests", OR = "F", `95% CI` = "df", p = "p")

# Model 1: Soc x Gen
cat("    Model 1 Wald test...\n")
wt1 <- regTermTest(models$m1, ~ soc_factor:generation)
reg_table <- reg_table %>%
  add_row(
    Variable = "Model 1: Soc x Generation",
    OR = sprintf("%.2f", as.numeric(wt1$Ftest)),
    `95% CI` = sprintf("(%.0f, %.0f)", as.numeric(wt1$df), as.numeric(wt1$ddf)),
    p = fmt_pval(as.numeric(wt1$p))
  )

# Model 2: Soc x Gen x Education
cat("    Model 2 Wald test...\n")
wt2 <- regTermTest(models$m2_edu, ~ soc_factor:generation:ba_plus)
reg_table <- reg_table %>%
  add_row(
    Variable = "Model 2: Soc x Gen x Education",
    OR = sprintf("%.2f", as.numeric(wt2$Ftest)),
    `95% CI` = sprintf("(%.0f, %.0f)", as.numeric(wt2$df), as.numeric(wt2$ddf)),
    p = fmt_pval(as.numeric(wt2$p))
  )

# Model 3: Soc x Gen x Employment
cat("    Model 3 Wald test...\n")
wt3 <- regTermTest(models$m3_emp, ~ soc_factor:generation:employed)
reg_table <- reg_table %>%
  add_row(
    Variable = "Model 3: Soc x Gen x Employment",
    OR = sprintf("%.2f", as.numeric(wt3$Ftest)),
    `95% CI` = sprintf("(%.0f, %.0f)", as.numeric(wt3$df), as.numeric(wt3$ddf)),
    p = fmt_pval(as.numeric(wt3$p))
  )

# Model 4: Soc x Gen x Civic SM
cat("    Model 4 Wald test...\n")
wt4 <- regTermTest(models$m4_sm, ~ soc_factor:generation:civic_sm)
reg_table <- reg_table %>%
  add_row(
    Variable = "Model 4: Soc x Gen x Civic SM",
    OR = sprintf("%.2f", as.numeric(wt4$Ftest)),
    `95% CI` = sprintf("(%.0f, %.0f)", as.numeric(wt4$df), as.numeric(wt4$ddf)),
    p = fmt_pval(as.numeric(wt4$p))
  )

# Model 5: Soc x Gen x COVID
cat("    Model 5 Wald test...\n")
wt5 <- regTermTest(models$m5_covid, ~ soc_factor:generation:post_covid)
reg_table <- reg_table %>%
  add_row(
    Variable = "Model 5: Soc x Gen x Post-COVID",
    OR = sprintf("%.2f", as.numeric(wt5$Ftest)),
    `95% CI` = sprintf("(%.0f, %.0f)", as.numeric(wt5$df), as.numeric(wt5$ddf)),
    p = fmt_pval(as.numeric(wt5$p))
  )

# --- Part C: Pseudo R-squared ------------------------------------------------
cat("  Computing pseudo R-squared...\n")

# McFadden pseudo R² for survey models
# Use the deviance ratio: 1 - deviance(model)/deviance(null)
calc_pseudo_r2 <- function(model, svy_design) {
  null_model <- svyglm(volunteered ~ 1, design = svy_design, family = quasibinomial())
  1 - (deviance(model) / deviance(null_model))
}

pr2_m1 <- calc_pseudo_r2(models$m1, svy)
cat(sprintf("  Model 1 McFadden pseudo R²: %.4f\n", pr2_m1))

reg_table <- reg_table %>%
  add_row(Variable = "", OR = "", `95% CI` = "", p = "") %>%
  add_row(
    Variable = "Model Fit",
    OR = "", `95% CI` = "", p = ""
  ) %>%
  add_row(
    Variable = sprintf("McFadden pseudo R² = %.4f", pr2_m1),
    OR = "", `95% CI` = "", p = ""
  ) %>%
  add_row(
    Variable = sprintf("N = %s", format(nrow(data), big.mark = ",")),
    OR = "", `95% CI` = "", p = ""
  )

write_csv(reg_table, "tables/table2_regression.csv")
cat("\nTable 2 written to tables/table2_regression.csv\n")
print(reg_table, n = 80, width = Inf)


# ==============================================================================
# TABLE 3: First Step AME
# ==============================================================================
cat("\n========== TABLE 3: First Step Average Marginal Effects ==========\n")

cat("  Computing AME from Model 1...\n")
ame_m1 <- avg_slopes(m1, variables = "soc_factor", by = "generation")

# Filter for the "first step" contrast: Few times/yr - Not at all
ame_first <- ame_m1 %>%
  as_tibble() %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, std.error, conf.low, conf.high, p.value)

# Also compute a pooled (total) first step AME without the by= argument
cat("  Computing pooled AME...\n")
ame_pooled <- avg_slopes(m1, variables = "soc_factor")

ame_pooled_first <- ame_pooled %>%
  as_tibble() %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(estimate, std.error, conf.low, conf.high, p.value)

# Build table
table3 <- tibble(
  Generation = c("Total (pooled)", gen_order),
  `AME (pp)` = c(
    sprintf("%.1f", ame_pooled_first$estimate * 100),
    sprintf("%.1f", ame_first$estimate * 100)
  ),
  SE = c(
    sprintf("%.2f", ame_pooled_first$std.error * 100),
    sprintf("%.2f", ame_first$std.error * 100)
  ),
  `95% CI` = c(
    sprintf("[%.1f, %.1f]", ame_pooled_first$conf.low * 100, ame_pooled_first$conf.high * 100),
    sprintf("[%.1f, %.1f]", ame_first$conf.low * 100, ame_first$conf.high * 100)
  ),
  p = c(
    fmt_pval(ame_pooled_first$p.value),
    fmt_pval(ame_first$p.value)
  )
)

write_csv(table3, "tables/table3_first_step_ame.csv")
cat("\nTable 3 written to tables/table3_first_step_ame.csv\n")
print(table3, width = Inf)


# ==============================================================================
# TABLE 4: LPA Model Fit
# ==============================================================================
cat("\n========== TABLE 4: LPA Model Fit ==========\n")

# Re-run LPA model selection on 20K subsample
cat("  Preparing LPA data...\n")
lpa_vars <- c("boycott", "puboff", "polconv", "socialize", "membership", "donated")
lpa_z_vars <- paste0(lpa_vars, "_z")

# Use the data_lpa which already has z-scored variables
set.seed(20260309)
idx <- sample(nrow(data_lpa), 20000)
lpa_mat <- as.matrix(data_lpa[idx, lpa_z_vars])

cat("  Fitting EII models (2-7 profiles) on 20K subsample...\n")
bic_results <- mclustBIC(lpa_mat, G = 2:7, modelNames = "EII")

bic_vals <- as.numeric(bic_results[, "EII"])
profiles_range <- 2:7

# Compute entropy for the selected model (6 profiles) on full data
cat("  Fitting selected 6-profile model on full sample for entropy...\n")
full_mat <- as.matrix(data_lpa[, lpa_z_vars])
full_model <- Mclust(full_mat, G = 6, modelNames = "EII")

entropy <- 1 - (-sum(full_model$z * log(full_model$z + 1e-10)) /
                  (nrow(full_mat) * log(6)))

# Build table
delta_bic <- c(NA, diff(bic_vals))

table4 <- tibble(
  Profiles = profiles_range,
  BIC = sprintf("%.1f", bic_vals),
  `Delta BIC` = ifelse(is.na(delta_bic), "--", sprintf("%.1f", delta_bic)),
  Entropy = ifelse(profiles_range == 6, sprintf("%.3f", entropy), "--"),
  Selected = ifelse(profiles_range == 6, "Yes", "")
)

write_csv(table4, "tables/table4_lpa_fit.csv")
cat("\nTable 4 written to tables/table4_lpa_fit.csv\n")
print(table4, width = Inf)


# ==============================================================================
# TABLE 5: LPA Profile Characteristics (Reformatted)
# ==============================================================================
cat("\n========== TABLE 5: LPA Profile Characteristics ==========\n")

# Profile labels (ordered by engagement level)
profile_labels <- c(
  "1" = "Isolated Disengaged",
  "2" = "Politically Aware Isolated",
  "3" = "Socially Active Non-Donors",
  "4" = "Mainstream Donors",
  "5" = "Activist Boycotters",
  "6" = "Fully Engaged"
)

table5 <- data_lpa %>%
  group_by(profile_ordered) %>%
  summarise(
    n = n(),
    pct = n() / nrow(data_lpa) * 100,
    boycott_pct      = mean(boycott, na.rm = TRUE) * 100,
    puboff_pct       = mean(puboff, na.rm = TRUE) * 100,
    polconv_m        = mean(polconv, na.rm = TRUE),
    polconv_sd       = sd(polconv, na.rm = TRUE),
    socialize_m      = mean(socialize, na.rm = TRUE),
    socialize_sd     = sd(socialize, na.rm = TRUE),
    membership_m     = mean(membership, na.rm = TRUE),
    membership_sd    = sd(membership, na.rm = TRUE),
    donated_pct      = mean(donated, na.rm = TRUE) * 100,
    vol_rate         = mean(volunteered, na.rm = TRUE) * 100,
    .groups = "drop"
  ) %>%
  mutate(
    Profile = paste0(profile_ordered, ": ", profile_labels[as.character(profile_ordered)]),
    n_fmt = format(n, big.mark = ","),
    pct_fmt = sprintf("%.1f", pct),
    `n (%)` = sprintf("%s (%.1f)", format(n, big.mark = ","), pct),
    `Boycott (%)` = sprintf("%.1f", boycott_pct),
    `Contact Officials (%)` = sprintf("%.1f", puboff_pct),
    `Political Conv., M (SD)` = fmt_msd(polconv_m, polconv_sd),
    `Socialization, M (SD)` = fmt_msd(socialize_m, socialize_sd),
    `Org. Membership, M (SD)` = fmt_msd(membership_m, membership_sd),
    `Donated (%)` = sprintf("%.1f", donated_pct),
    `Volunteering (%)` = sprintf("%.1f", vol_rate)
  ) %>%
  select(Profile, `n (%)`, `Boycott (%)`, `Contact Officials (%)`,
         `Political Conv., M (SD)`, `Socialization, M (SD)`,
         `Org. Membership, M (SD)`, `Donated (%)`, `Volunteering (%)`)

write_csv(table5, "tables/table5_lpa_profiles.csv")
cat("\nTable 5 written to tables/table5_lpa_profiles.csv\n")
print(table5, width = Inf)

cat("\n========== ALL TABLES COMPLETE ==========\n")
cat("Files written:\n")
cat("  tables/table1_sample_characteristics.csv\n")
cat("  tables/table2_regression.csv\n")
cat("  tables/table3_first_step_ame.csv\n")
cat("  tables/table4_lpa_fit.csv\n")
cat("  tables/table5_lpa_profiles.csv\n")
