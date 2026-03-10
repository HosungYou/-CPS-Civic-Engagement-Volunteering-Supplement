# ==============================================================================
# 01_descriptive_analysis.R
# Descriptive Cross-Tabulations: Socialization × Generation × Volunteering
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
# ==============================================================================

library(tidyverse)
library(survey)
library(gt)

# --- 1. Load Cleaned Data -----------------------------------------------------
# Output from 00_data_preparation.R
data <- readRDS("data/cev_clean.rds")

cat(sprintf("Analytic sample: N = %s\n", format(nrow(data), big.mark = ",")))

# --- 2. Define Generations ----------------------------------------------------
data <- data %>%
  mutate(
    birth_year = YEAR - AGE,
    generation = case_when(
      birth_year >= 1997 ~ "Gen Z",
      birth_year >= 1981 ~ "Millennial",
      birth_year >= 1965 ~ "Gen X",
      birth_year >= 1946 ~ "Boomer",
      TRUE ~ "Silent"
    ),
    generation = factor(generation,
                        levels = c("Gen Z", "Millennial", "Gen X", "Boomer", "Silent"))
  )

# --- 3. Survey Design Object --------------------------------------------------
svy <- svydesign(
  ids = ~1,
  weights = ~VLSUPPWT,
  data = data
)

# --- 4. Table 1: Minimal Socialization by Generation × Wave -------------------
# CESOCIALIZE = 1 corresponds to "Not at all"
table1 <- svyby(
  ~I(CESOCIALIZE == 1),
  ~generation + YEAR,
  svy,
  svymean,
  na.rm = TRUE
)

table1_wide <- table1 %>%
  mutate(pct = round(`I(CESOCIALIZE == 1)TRUE` * 100, 1)) %>%
  select(generation, YEAR, pct) %>%
  pivot_wider(names_from = YEAR, values_from = pct)

cat("\n=== Table 1: % Reporting Minimal Socialization (CESOCIALIZE=1) ===\n")
print(table1_wide)

# --- 5. Table 2: Volunteering by Socialization × Generation -------------------
# Recode VLSTATUS: 1 = Volunteered, 2 = Did not
data$volunteered <- ifelse(data$VLSTATUS == 1, 1, 0)
svy <- update(svy, volunteered = ifelse(VLSTATUS == 1, 1, 0))

# Create socialization labels
svy <- update(svy, soc_label = factor(
  CESOCIALIZE,
  levels = 1:6,
  labels = c("Not at all", "A few times/year", "Once a month",
             "A few times/month", "A few times/week", "Basically every day")
))

table2 <- svyby(
  ~volunteered,
  ~soc_label + generation,
  svy,
  svymean,
  na.rm = TRUE
)

table2_wide <- table2 %>%
  mutate(pct = round(volunteered * 100, 1)) %>%
  select(soc_label, generation, pct) %>%
  pivot_wider(names_from = generation, values_from = pct)

cat("\n=== Table 2: Volunteering Rate by Socialization × Generation ===\n")
print(table2_wide)

# --- 6. Cohort Effect Test: Same-Age Comparison --------------------------------
# Millennials aged 20-25 in 2017 vs Gen Z aged 20-25 in 2023
cohort_test <- data %>%
  filter(
    (generation == "Millennial" & YEAR == 2017 & AGE >= 20 & AGE <= 25) |
    (generation == "Gen Z" & YEAR == 2023 & AGE >= 20 & AGE <= 25)
  )

svy_cohort <- svydesign(ids = ~1, weights = ~VLSUPPWT, data = cohort_test)

cat("\n=== Same-Age Comparison (ages 20-25) ===\n")
svyby(~I(CESOCIALIZE == 1), ~generation, svy_cohort, svymean, na.rm = TRUE) %>%
  print()
svyby(~volunteered, ~generation, svy_cohort, svymean, na.rm = TRUE) %>%
  print()

# --- 7. Social Media Compensation Effect --------------------------------------
# Among socially isolated (CESOCIALIZE = 1)
# VLSOCMEDIA: 1 = daily → 6 = not at all (descending)
# Civic SM user: VLSOCMEDIA <= 4 (at least a few times/year)

svy_isolated <- subset(svy, CESOCIALIZE == 1)
svy_isolated <- update(svy_isolated,
                        civic_sm = ifelse(VLSOCMEDIA <= 4, "SM Use", "No SM"))

table3 <- svyby(
  ~volunteered,
  ~civic_sm + generation,
  svy_isolated,
  svymean,
  na.rm = TRUE
)

cat("\n=== Table 3: SM Compensation Among Isolated ===\n")
table3 %>%
  mutate(pct = round(volunteered * 100, 1)) %>%
  select(civic_sm, generation, pct) %>%
  pivot_wider(names_from = civic_sm, values_from = pct) %>%
  print()

# --- 8. Education × Socialization × Generation --------------------------------
svy <- update(svy, ba_plus = ifelse(PEEDUCA >= 43, "BA+", "<BA"))

table_edu <- svyby(
  ~I(CESOCIALIZE == 1),
  ~ba_plus + generation,
  svy,
  svymean,
  na.rm = TRUE
)

cat("\n=== Minimal Socialization by Education × Generation ===\n")
table_edu %>%
  mutate(pct = round(`I(CESOCIALIZE == 1)TRUE` * 100, 1)) %>%
  select(ba_plus, generation, pct) %>%
  pivot_wider(names_from = generation, values_from = pct) %>%
  print()

cat("\nDescriptive analysis complete.\n")
