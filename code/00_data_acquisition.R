# ==============================================================================
# 00_data_acquisition.R
# CPS-CEV Data Acquisition and Cleaning
#
# Study: Heterogeneous Effects of Organized Volunteering on Civic Engagement
# Authors: Hosung You & Suzanna Windon
# ==============================================================================

# --- 1. Load Libraries --------------------------------------------------------
library(ipumsr)
library(tidyverse)
library(survey)
library(haven)

# --- 2. Data Download via IPUMS -----------------------------------------------
# NOTE: You must register at https://cps.ipums.org and create an extract
# including the CEV supplement variables for September 2017, 2019, 2021, 2023
#
# Required variables:
#   - Core: YEAR, MONTH, CPSIDP, WTFINL, HWTFINL, STATEFIP, METRO, METAREA
#   - Demographics: AGE, SEX, RACE, HISPAN, MARST, NCHILD, EDUC, FAMINC
#   - Housing: OWNERSHP, DIFFMOVE
#   - Employment: EMPSTAT, OCC2010, IND1990
#   - CEV Supplement: All PES* and PRS* variables
#   - Supplement Weight: VLSUPPWT (Volunteer Supplement Weight)

# --- 3. Read IPUMS Extract ---------------------------------------------------
# After downloading your extract from IPUMS:
# ddi <- read_ipums_ddi("cps_cev_extract.xml")
# data_raw <- read_ipums_micro(ddi)

# --- 4. Alternative: Direct Census Download -----------------------------------
# CEV microdata also available from:
# https://www.census.gov/data/datasets/time-series/demo/cps/cps-supp_cps-repwgt/cps-volunteer.html

# --- 5. Data Cleaning Pipeline ------------------------------------------------

clean_cev_data <- function(data_raw) {

  data_clean <- data_raw %>%
    # Filter to CEV supplement months (September)
    filter(MONTH == 9) %>%
    # Filter to adults 18+
    filter(AGE >= 18) %>%
    # Filter to those with supplement weight > 0 (in supplement universe)
    filter(VLSUPPWT > 0) %>%

    # --- Recode Treatment Variable ---
    mutate(
      volunteered_org = case_when(
        PES1 == 1 ~ 1L,  # Yes, volunteered through organization
        PES1 == 2 ~ 0L,  # No
        TRUE ~ NA_integer_
      )
    ) %>%

    # --- Recode Civic Engagement Indicators ---
    mutate(
      # Volunteering intensity (hours in past 12 months)
      vol_hours = ifelse(PES5 >= 0, PES5, NA_real_),
      vol_hours_log = log1p(vol_hours),

      # Political participation index (0-4)
      pol_voted = ifelse(PRS1 == 1, 1L, 0L),
      pol_contacted = ifelse(PRS2 == 1, 1L, 0L),
      pol_boycott = ifelse(PRS3 == 1, 1L, 0L),
      pol_meeting = ifelse(PRS4 == 1, 1L, 0L),
      political_participation = pol_voted + pol_contacted + pol_boycott + pol_meeting,

      # Charitable giving
      charitable_giving = ifelse(PRS13 == 1, 1L, 0L),

      # Community interaction
      community_neighbors = case_when(
        PRS5 >= 1 & PRS5 <= 5 ~ PRS5,
        TRUE ~ NA_real_
      ),
      community_meetings = case_when(
        PRS6 >= 1 & PRS6 <= 5 ~ PRS6,
        TRUE ~ NA_real_
      ),
      community_interaction = (community_neighbors + community_meetings) / 2,

      # Organizational membership count
      org_membership = rowSums(across(starts_with("PRS9"), ~ . == 1), na.rm = TRUE),

      # Online civic engagement (2023 wave proxy)
      online_civic = ifelse(YEAR == 2023 & PRS_VIRTUAL == 1, 1L, 0L)
    ) %>%

    # --- Recode Covariates ---
    mutate(
      # Rural/Urban
      rural_urban = case_when(
        METRO %in% c(2, 3) ~ "Urban",
        METRO == 1 ~ "Rural",
        TRUE ~ NA_character_
      ),
      is_rural = ifelse(rural_urban == "Rural", 1L, 0L),

      # Demographics
      age = AGE,
      age_sq = AGE^2,
      female = ifelse(SEX == 2, 1L, 0L),

      race_eth = case_when(
        HISPAN >= 100 ~ "Hispanic",
        RACE == 100 ~ "White",
        RACE == 200 ~ "Black",
        RACE %in% c(651, 652) ~ "Asian",
        TRUE ~ "Other"
      ),

      married = ifelse(MARST %in% c(1, 2), 1L, 0L),
      has_children = ifelse(NCHILD > 0, 1L, 0L),

      # Education
      educ_level = case_when(
        EDUC <= 71 ~ "Less than HS",
        EDUC == 73 ~ "High School",
        EDUC %in% c(81, 91, 92) ~ "Some College",
        EDUC == 111 ~ "Bachelor's",
        EDUC >= 123 ~ "Graduate",
        TRUE ~ NA_character_
      ),
      educ_level = factor(educ_level, levels = c(
        "Less than HS", "High School", "Some College", "Bachelor's", "Graduate"
      )),

      # Income
      faminc_cat = case_when(
        FAMINC <= 600 ~ "Under $25K",
        FAMINC <= 740 ~ "$25K-$49K",
        FAMINC <= 830 ~ "$50K-$74K",
        FAMINC <= 841 ~ "$75K-$99K",
        FAMINC >= 842 ~ "$100K+",
        TRUE ~ NA_character_
      ),

      # Employment
      employed = ifelse(EMPSTAT %in% c(10, 12), 1L, 0L),

      # Housing
      homeowner = ifelse(OWNERSHP == 10, 1L, 0L),

      # State
      state_fips = STATEFIP,

      # Survey wave
      wave = factor(YEAR)
    ) %>%

    # --- Remove cases missing on key variables ---
    filter(!is.na(volunteered_org)) %>%
    filter(!is.na(rural_urban)) %>%
    filter(rowSums(is.na(select(., vol_hours_log, political_participation,
                                 charitable_giving, community_interaction,
                                 org_membership))) < 5)  # Keep if at least 1 indicator non-missing

  return(data_clean)
}

# --- 6. Create Survey Design Object ------------------------------------------

create_survey_design <- function(data_clean) {
  svy_design <- svydesign(
    ids = ~1,                    # No cluster variable in public use
    strata = NULL,               # Stratification handled by weights
    weights = ~VLSUPPWT,         # CEV supplement weight
    data = data_clean
  )
  return(svy_design)
}

# --- 7. Standardize LPA Indicators -------------------------------------------

standardize_lpa_indicators <- function(data_clean) {
  lpa_indicators <- c("vol_hours_log", "political_participation",
                       "charitable_giving", "community_interaction",
                       "org_membership")

  data_lpa <- data_clean %>%
    mutate(across(all_of(lpa_indicators),
                  ~ scale(.)[, 1],
                  .names = "{.col}_z")) %>%
    select(CPSIDP, YEAR, VLSUPPWT,
           ends_with("_z"),
           volunteered_org, is_rural, rural_urban,
           age, age_sq, female, race_eth, married, has_children,
           educ_level, faminc_cat, employed, homeowner,
           state_fips, wave)

  return(data_lpa)
}

# --- 8. Save Cleaned Data ----------------------------------------------------

# data_raw <- read_ipums_micro(ddi)
# data_clean <- clean_cev_data(data_raw)
# svy_design <- create_survey_design(data_clean)
# data_lpa <- standardize_lpa_indicators(data_clean)
#
# saveRDS(data_clean, "data/cev_clean.rds")
# saveRDS(data_lpa, "data/cev_lpa_ready.rds")
# saveRDS(svy_design, "data/cev_survey_design.rds")

cat("Data acquisition script ready. Register at https://cps.ipums.org to download data.\n")
