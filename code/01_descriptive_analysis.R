# ==============================================================================
# 01_descriptive_analysis.R
# Descriptive Cross-Tabulations: Socialization × Generation × Volunteering
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Design: 4-wave pooled (2017/2019/2021/2023), N ≈ 201,000
# ==============================================================================

library(tidyverse)
library(survey)
library(gt)

# --- 1. Load Cleaned Data (4-wave) --------------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Analytic sample: N = %s\n", format(nrow(data), big.mark = ",")))

# --- 2. Survey Design Object --------------------------------------------------
# CPS uses stratified multistage cluster design.
# SERIAL provides household-level clustering; STATEFIP provides state stratification.
# IPUMS does not release actual PSU identifiers; this is the best available specification.
options(survey.lonely.psu = "adjust")
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                  weights = ~VLSUPPWT, nest = TRUE, data = data)

# --- 3. Table 1: Sample Characteristics by Generation -------------------------
cat("\n=== Table 1: Sample Characteristics by Generation ===\n")

gen_summary <- data %>%
  group_by(generation) %>%
  summarise(
    n = n(),
    age_mean = mean(AGE),
    female_pct = mean(female) * 100,
    ba_plus_pct = mean(ba_plus) * 100,
    employed_pct = mean(employed) * 100,
    married_pct = mean(married) * 100,
    metro_pct = mean(metro) * 100,
    vol_rate = mean(volunteered) * 100,
    soc_mean = mean(CESOCIALIZE, na.rm = TRUE),
    minimal_soc_pct = mean(CESOCIALIZE == 1, na.rm = TRUE) * 100,
    donated_pct = mean(donated, na.rm = TRUE) * 100,
    civic_sm_pct = mean(civic_sm) * 100,
    .groups = "drop"
  )

print(gen_summary, width = Inf)

# --- 4. Table 1b: Wave × Generation Distribution -----------------------------
cat("\n=== Table 1b: N by Wave × Generation ===\n")
wave_gen <- data %>%
  count(wave, generation) %>%
  pivot_wider(names_from = generation, values_from = n)
print(wave_gen)

# --- 5. Table 2: Minimal Socialization by Generation × Wave ------------------
table2 <- svyby(
  ~I(CESOCIALIZE == 1),
  ~generation + wave,
  svy,
  svymean,
  na.rm = TRUE
)

table2_wide <- table2 %>%
  mutate(pct = round(`I(CESOCIALIZE == 1)TRUE` * 100, 1)) %>%
  select(generation, wave, pct) %>%
  pivot_wider(names_from = wave, values_from = pct)

cat("\n=== Table 2: % Minimal Socialization (CESOCIALIZE=1) by Gen × Wave ===\n")
print(table2_wide)

# --- 6. Table 3: Volunteering by Socialization × Generation -------------------
svy <- update(svy, soc_label = factor(
  CESOCIALIZE,
  levels = 1:6,
  labels = c("Not at all", "A few times/year", "Once a month",
             "A few times/month", "A few times/week", "Basically every day")
))

table3 <- svyby(
  ~volunteered,
  ~soc_label + generation,
  svy,
  svymean,
  na.rm = TRUE
)

table3_wide <- table3 %>%
  mutate(pct = round(volunteered * 100, 1)) %>%
  select(soc_label, generation, pct) %>%
  pivot_wider(names_from = generation, values_from = pct)

cat("\n=== Table 3: Volunteering Rate by Socialization × Generation ===\n")
print(table3_wide)

# --- 7. Table 4: Pre/Post COVID Comparison -----------------------------------
cat("\n=== Table 4: Key Indicators Pre vs Post COVID ===\n")

svy <- update(svy, covid_label = ifelse(post_covid == 1, "Post-COVID", "Pre-COVID"))

covid_summary <- svyby(
  ~volunteered + I(CESOCIALIZE == 1),
  ~covid_label + generation,
  svy,
  svymean,
  na.rm = TRUE
)

covid_vol <- covid_summary %>%
  mutate(vol_pct = round(volunteered * 100, 1),
         iso_pct = round(`I(CESOCIALIZE == 1)TRUE` * 100, 1)) %>%
  select(covid_label, generation, vol_pct, iso_pct)

cat("Volunteering rate:\n")
covid_vol %>%
  select(covid_label, generation, vol_pct) %>%
  pivot_wider(names_from = covid_label, values_from = vol_pct) %>%
  print()

cat("\nMinimal socialization rate:\n")
covid_vol %>%
  select(covid_label, generation, iso_pct) %>%
  pivot_wider(names_from = covid_label, values_from = iso_pct) %>%
  print()

# --- 8. Social Media Compensation Among Isolated ------------------------------
svy_isolated <- subset(svy, CESOCIALIZE == 1)
svy_isolated <- update(svy_isolated,
                        civic_sm_label = ifelse(civic_sm == 1, "SM Use", "No SM"))

table5 <- svyby(
  ~volunteered,
  ~civic_sm_label + generation,
  svy_isolated,
  svymean,
  na.rm = TRUE
)

cat("\n=== Table 5: SM Compensation Among Isolated ===\n")
table5 %>%
  mutate(pct = round(volunteered * 100, 1)) %>%
  select(civic_sm_label, generation, pct) %>%
  pivot_wider(names_from = civic_sm_label, values_from = pct) %>%
  print()

# --- 9. Education × Socialization × Generation --------------------------------
svy <- update(svy, ba_label = ifelse(ba_plus == 1, "BA+", "<BA"))

table_edu <- svyby(
  ~I(CESOCIALIZE == 1),
  ~ba_label + generation,
  svy,
  svymean,
  na.rm = TRUE
)

cat("\n=== Table 6: Minimal Socialization by Education × Generation ===\n")
table_edu %>%
  mutate(pct = round(`I(CESOCIALIZE == 1)TRUE` * 100, 1)) %>%
  select(ba_label, generation, pct) %>%
  pivot_wider(names_from = generation, values_from = pct) %>%
  print()

# --- 10. Donation × Volunteering × Generation --------------------------------
table_donate <- svyby(
  ~volunteered,
  ~I(donated == 1) + generation,
  svy,
  svymean,
  na.rm = TRUE
)

cat("\n=== Table 7: Volunteering by Donation Status × Generation ===\n")
table_donate %>%
  mutate(pct = round(volunteered * 100, 1)) %>%
  print()

cat("\nDescriptive analysis complete.\n")
