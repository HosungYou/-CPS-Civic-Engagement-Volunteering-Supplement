# ==============================================================================
# 02_logistic_regression.R
# PRIMARY ANALYSIS: Survey-Weighted Logistic Regression
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# RQ1: Socialization × Generation interaction (nonlinear threshold)
# RQ2: Three-way interactions (× Education, × Employment, × Social Media)
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)
library(broom)
library(gt)

set.seed(20260309)

# --- 1. Load Cleaned Data -----------------------------------------------------
data <- readRDS("data/cev_clean.rds")

# --- 2. Variable Preparation --------------------------------------------------
data <- data %>%
  mutate(
    # DV
    volunteered = ifelse(VLSTATUS == 1, 1, 0),

    # Key IV: Socialization as factor (reference = "Not at all")
    soc_factor = factor(
      CESOCIALIZE,
      levels = 1:6,
      labels = c("Not at all", "Few times/yr", "Once/mo",
                  "Few times/mo", "Few times/wk", "Daily")
    ),

    # Generation
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
    ),

    # Moderators
    ba_plus = ifelse(PEEDUCA >= 43, 1, 0),
    employed = ifelse(PEMLR %in% c(1, 2, 3, 4), 1, 0),
    civic_sm = ifelse(!is.na(VLSOCMEDIA) & VLSOCMEDIA <= 4, 1, 0),

    # Controls
    female = ifelse(PESEX == 2, 1, 0),
    race_eth = factor(case_when(
      PTDTRACE == 1 & PEHSPNON == 1 ~ "White NH",
      PTDTRACE == 2 & PEHSPNON == 1 ~ "Black NH",
      PEHSPNON == 2 ~ "Hispanic",
      PTDTRACE == 4 & PEHSPNON == 1 ~ "Asian NH",
      TRUE ~ "Other"
    )),
    married = ifelse(PEMARITL == 1, 1, 0),
    metro = ifelse(GTMETSTA == 1, 1, 0),
    region = factor(case_when(
      GEREG == 1 ~ "Northeast",
      GEREG == 2 ~ "Midwest",
      GEREG == 3 ~ "South",
      GEREG == 4 ~ "West"
    )),
    wave = factor(YEAR)
  )

# --- 3. Survey Design ---------------------------------------------------------
svy <- svydesign(ids = ~1, weights = ~VLSUPPWT, data = data)

# --- 4. Model 1: RQ1 — Socialization × Generation ----------------------------
cat("=== Model 1: Socialization × Generation Interaction ===\n")

m1 <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + HEFAMINC + metro + region + wave,
  design = svy,
  family = quasibinomial()
)

cat("\nInteraction test (Wald):\n")
regTermTest(m1, ~ soc_factor:generation)

# Average Marginal Effects by generation
cat("\nAverage Marginal Effects of Socialization by Generation:\n")
ame_m1 <- avg_slopes(m1, variables = "soc_factor", by = "generation")
print(ame_m1)

# Predicted probabilities
pred_m1 <- predictions(m1,
  newdata = datagrid(soc_factor = unique, generation = unique),
  type = "response"
)
cat("\nPredicted Volunteering Probabilities:\n")
pred_m1 %>%
  select(soc_factor, generation, estimate, conf.low, conf.high) %>%
  print(n = 30)

# --- 5. Model 2: RQ2 — Three-Way Interaction (Education) ---------------------
cat("\n=== Model 2: Socialization × Generation × Education ===\n")

m2_edu <- svyglm(
  volunteered ~ soc_factor * generation * ba_plus +
    AGE + female + race_eth + employed +
    married + HEFAMINC + metro + region + wave,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m2_edu, ~ soc_factor:generation:ba_plus)

# --- 6. Model 3: RQ2 — Three-Way Interaction (Employment) --------------------
cat("\n=== Model 3: Socialization × Generation × Employment ===\n")

m3_emp <- svyglm(
  volunteered ~ soc_factor * generation * employed +
    AGE + female + race_eth + ba_plus +
    married + HEFAMINC + metro + region + wave,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m3_emp, ~ soc_factor:generation:employed)

# --- 7. Model 4: RQ2 — Three-Way Interaction (Civic Social Media) ------------
cat("\n=== Model 4: Socialization × Generation × Civic SM ===\n")

m4_sm <- svyglm(
  volunteered ~ soc_factor * generation * civic_sm +
    AGE + female + race_eth + ba_plus + employed +
    married + HEFAMINC + metro + region + wave,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m4_sm, ~ soc_factor:generation:civic_sm)

# --- 8. Export Results --------------------------------------------------------
saveRDS(list(m1 = m1, m2_edu = m2_edu, m3_emp = m3_emp, m4_sm = m4_sm),
        "data/logistic_models.rds")

cat("\nAll models saved to data/logistic_models.rds\n")
cat("Primary analysis complete.\n")
