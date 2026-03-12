# ==============================================================================
# 00_data_preparation.R
# Data Cleaning Pipeline — IPUMS CPS-CEV 2017/2019/2021/2023
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Input:  data/cps_00002.csv (IPUMS CPS extract)
# Output: data/cev_clean.rds       (cleaned R data)
#         data/cev_for_shap.csv     (for Python GBM+SHAP)
# ==============================================================================

library(tidyverse)

set.seed(20260309)

# --- 1. Read IPUMS Extract ---------------------------------------------------
raw <- read_csv("data/cps_00002.csv", show_col_types = FALSE)
cat(sprintf("Raw IPUMS extract: N = %s rows, %d columns\n",
            format(nrow(raw), big.mark = ","), ncol(raw)))

# --- 2. Filter to 4-wave sample (2017/2019/2021/2023), Adults, Supplement Universe ----
data <- raw %>%
  filter(
    YEAR %in% c(2017, 2019, 2021, 2023),
    AGE >= 18,
    VLSUPPWT > 0,
    VLSTATUS %in% c(1, 2)   # Valid volunteering response only
  )

cat(sprintf("4-wave analytic sample (age >= 18, valid VLSTATUS): N = %s\n",
            format(nrow(data), big.mark = ",")))
cat("Wave counts:\n")
print(table(data$YEAR))

# --- 3. Recode Variables (IPUMS Harmonized Names) ----------------------------
data <- data %>%
  mutate(
    # ── Survey Design ──
    post_covid = ifelse(YEAR %in% c(2021, 2023), 1L, 0L),
    wave       = factor(YEAR),

    # ── DV ──
    volunteered = ifelse(VLSTATUS == 1, 1L, 0L),

    # ── Key IV: Socialization (1 = Not at all → 6 = Daily) ──
    soc_factor = factor(
      CESOCIALIZE,
      levels = 1:6,
      labels = c("Not at all", "Few times/yr", "Once/mo",
                 "Few times/mo", "Few times/wk", "Daily")
    ),

    # ── Generation (based on birth year) ──
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

    # ── Moderators ──
    ba_plus  = ifelse(EDUC >= 111, 1L, 0L),
    employed = ifelse(EMPSTAT %in% c(10, 12), 1L, 0L),
    # VLSOCMEDIA: 1=daily → 6=not at all (descending in IPUMS)
    # civic_sm = uses SM for civic purposes at least a few times/year
    civic_sm = ifelse(!is.na(VLSOCMEDIA) & VLSOCMEDIA <= 4, 1L, 0L),
    # Reverse-coded: higher = more SM use
    VLSOCMEDIA_rev = ifelse(VLSOCMEDIA %in% 1:6, 7L - VLSOCMEDIA, NA_integer_),

    # ── Demographics ──
    female = ifelse(SEX == 2, 1L, 0L),
    race_eth = factor(case_when(
      HISPAN >= 100 ~ "Hispanic",
      RACE == 100   ~ "White NH",
      RACE == 200   ~ "Black NH",
      RACE == 651   ~ "Asian NH",
      TRUE          ~ "Other"
    )),
    married = ifelse(MARST %in% c(1, 2), 1L, 0L),
    metro   = ifelse(METRO %in% c(2, 3, 4), 1L, 0L),

    # ── Region (from STATEFIP) ──
    region = factor(case_when(
      STATEFIP %in% c(9, 23, 25, 33, 34, 36, 42, 44, 50) ~ "Northeast",
      STATEFIP %in% c(17, 18, 19, 20, 26, 27, 29, 31, 38, 39, 46, 55) ~ "Midwest",
      STATEFIP %in% c(1, 5, 10, 11, 12, 13, 21, 22, 24, 28, 37, 40, 45, 47, 48, 51, 54) ~ "South",
      STATEFIP %in% c(2, 4, 6, 8, 15, 16, 30, 32, 35, 41, 49, 53, 56) ~ "West",
      TRUE ~ NA_character_
    )),

    # ── Family Income (continuous proxy, midpoints) ──
    faminc_mid = case_when(
      FAMINC == 100 ~ 2500,
      FAMINC == 210 ~ 6250,
      FAMINC == 300 ~ 8750,
      FAMINC == 430 ~ 13750,
      FAMINC == 470 ~ 17500,
      FAMINC == 500 ~ 22500,
      FAMINC == 600 ~ 27500,
      FAMINC == 710 ~ 32500,
      FAMINC == 720 ~ 37500,
      FAMINC == 730 ~ 45000,
      FAMINC == 740 ~ 55000,
      FAMINC == 820 ~ 67500,
      FAMINC == 830 ~ 87500,
      FAMINC == 841 ~ 125000,
      FAMINC %in% c(842, 843) ~ 175000,
      TRUE ~ NA_real_
    ),
    faminc_log = log(faminc_mid + 1),

    # ── LPA Indicators (recode to binary/ordinal) ──
    boycott    = ifelse(CEBOYCOTT == 2, 1L, 0L),   # 2 = Yes in IPUMS
    puboff     = ifelse(CEPUBOFF == 2, 1L, 0L),    # 2 = Yes in IPUMS
    polconv    = ifelse(CEPOLCONV %in% 1:6, CEPOLCONV, NA_integer_),
    socialize  = ifelse(CESOCIALIZE %in% 1:6, CESOCIALIZE, NA_integer_),
    # VLMEMBER=1 means non-member (coded 99 in VLMEMBERN); recode to membership count (0 for non-members)
    membership = case_when(
      VLMEMBER == 1            ~ 0L,          # Explicitly not a member → 0
      VLMEMBERN %in% 0:20      ~ as.integer(VLMEMBERN),
      TRUE                     ~ NA_integer_
    ),
    donated    = ifelse(VLDONATE == 2, 1L, 0L)      # 2 = Yes in IPUMS
  ) %>%
  # Remove rows with missing key variables
  filter(
    !is.na(CESOCIALIZE),
    !is.na(generation)
  )

cat(sprintf("After cleaning: N = %s\n", format(nrow(data), big.mark = ",")))
cat("Post-COVID breakdown:\n")
print(table(Wave = data$YEAR, PostCOVID = data$post_covid))

# --- 4. Diagnostics ----------------------------------------------------------
cat("\n=== Sample Summary (4-wave pooled) ===\n")
cat(sprintf("Volunteering rate: %.1f%%\n", mean(data$volunteered) * 100))
cat(sprintf("Post-COVID observations: %.1f%%\n", mean(data$post_covid) * 100))
cat("\nWave distribution:\n")
print(table(data$wave))
cat("\nGeneration distribution:\n")
print(table(data$generation))
cat("\nSocialization distribution:\n")
print(table(data$soc_factor))
cat(sprintf("\nBA+: %.1f%%\n", mean(data$ba_plus) * 100))
cat(sprintf("Employed: %.1f%%\n", mean(data$employed) * 100))
cat(sprintf("Civic SM user: %.1f%%\n", mean(data$civic_sm) * 100))
cat(sprintf("Donated: %.1f%%\n", mean(data$donated, na.rm = TRUE) * 100))

# --- 5. Export for Python (GBM+SHAP) ----------------------------------------
# Create dummy variables for Python
shap_df <- data %>%
  mutate(
    female      = as.integer(female),
    married     = as.integer(married),
    employed    = as.integer(employed),
    metro       = as.integer(metro),
    region_Northeast = ifelse(region == "Northeast", 1L, 0L),
    region_Midwest   = ifelse(region == "Midwest", 1L, 0L),
    region_South     = ifelse(region == "South", 1L, 0L),
    gen_Millennial   = ifelse(generation == "Millennial", 1L, 0L),
    gen_GenX         = ifelse(generation == "Gen X", 1L, 0L),
    gen_Boomer       = ifelse(generation == "Boomer", 1L, 0L),
    gen_Silent       = ifelse(generation == "Silent", 1L, 0L)
  ) %>%
  select(
    volunteered, CESOCIALIZE, EDUC, AGE, faminc_log,
    VLSOCMEDIA_rev, female, married, employed, metro,
    region_Northeast, region_Midwest, region_South,
    gen_Millennial, gen_GenX, gen_Boomer, gen_Silent,
    post_covid, wave,
    VLSUPPWT, generation
  ) %>%
  drop_na()

write_csv(shap_df, "data/cev_for_shap.csv")
cat(sprintf("\nExported for Python: N = %s → data/cev_for_shap.csv\n",
            format(nrow(shap_df), big.mark = ",")))

# --- 6. Save Cleaned Data ----------------------------------------------------
saveRDS(data, "data/cev_clean.rds")
cat(sprintf("Saved cleaned data: N = %s → data/cev_clean.rds\n",
            format(nrow(data), big.mark = ",")))

cat("\nData preparation complete.\n")
