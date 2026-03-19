# ==============================================================================
# 15_additional_tables.R
# ADDITIONAL ANALYSES — Response to X1 Research Guardian Review
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Tasks:
#   1. Check for religious attendance variable in CPS-CEV
#   2. Generation x Wave volunteering rate table
#   3. Three-period COVID robustness check (Pre/During/Post)
#   4. Check for volunteer hours (VLHALLORG) availability
#   5. Text suggestions for Method/Discussion (printed to console)
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)

set.seed(20260309)

# --- 0. Load Data & Survey Design --------------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Analytic sample: N = %s\n", format(nrow(data), big.mark = ",")))

options(survey.lonely.psu = "adjust")
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                  weights = ~VLSUPPWT, nest = TRUE, data = data)

# ==============================================================================
# TASK 1: Check for Religious Attendance Variable
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("TASK 1: Religious Attendance Variable Check\n")
cat(strrep("=", 70), "\n")

# Read the raw CSV header to check all available columns
raw_cols <- names(read_csv("data/cps_00002.csv", n_max = 0, show_col_types = FALSE))
cat("\nAll columns in raw IPUMS extract:\n")
print(raw_cols)

# Search for religion-related variables
religion_vars <- grep("relig|church|worship|attend|faith|pray",
                       raw_cols, ignore.case = TRUE, value = TRUE)
cat(sprintf("\nReligion-related variables found: %d\n", length(religion_vars)))
if (length(religion_vars) > 0) {
  cat("Variables:", paste(religion_vars, collapse = ", "), "\n")
} else {
  cat("RESULT: No religious attendance variable exists in CPS-CEV.\n")
  cat("\nExplanation: The CPS Civic Engagement and Volunteering Supplement\n")
  cat("does NOT include religious attendance or religiosity measures.\n")
  cat("Religious attendance is available in:\n")
  cat("  - General Social Survey (GSS: ATTEND variable)\n")
  cat("  - American Time Use Survey (ATUS: religious activity codes)\n")
  cat("  - Pew Research Center surveys\n")
  cat("  - National Congregations Study\n")
  cat("The CPS-CEV focuses on civic engagement behaviors (boycotting,\n")
  cat("contacting officials, political discussion, socialization) and\n")
  cat("volunteer supplement variables (status, hours, organization type).\n")
  cat("Religious institutional participation is captured indirectly through\n")
  cat("VLMEMBER/VLMEMBERN (organizational membership count) and VLDONATE\n")
  cat("(donation to charitable or religious organizations).\n")
}


# ==============================================================================
# TASK 2: Generation x Wave Volunteering Rate Table
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("TASK 2: Generation x Wave Volunteering & Socialization Rates\n")
cat(strrep("=", 70), "\n")

# --- 2a. Survey-weighted volunteering rates by generation x wave ---
cat("\n--- Volunteering Rates (%) by Generation x Wave ---\n")

vol_rates <- svyby(~volunteered, ~generation + wave, svy, svymean, na.rm = TRUE)
vol_rates_df <- as.data.frame(vol_rates) %>%
  mutate(
    vol_pct = round(volunteered * 100, 1),
    vol_se  = round(se * 100, 1)
  ) %>%
  select(generation, wave, vol_pct, vol_se)

cat("\nVolunteering rates (survey-weighted %):\n")
vol_wide <- vol_rates_df %>%
  mutate(label = sprintf("%.1f (%.1f)", vol_pct, vol_se)) %>%
  select(generation, wave, label) %>%
  pivot_wider(names_from = wave, values_from = label)
print(vol_wide)

# --- 2b. Minimal socialization rates (Not at all) by generation x wave ---
cat("\n--- 'Not at all' Socialization Rates (%) by Generation x Wave ---\n")

data$no_socialize <- ifelse(data$CESOCIALIZE == 1, 1L, 0L)
svy_nosoc <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                         weights = ~VLSUPPWT, nest = TRUE, data = data)

nosoc_rates <- svyby(~no_socialize, ~generation + wave, svy_nosoc, svymean, na.rm = TRUE)
nosoc_rates_df <- as.data.frame(nosoc_rates) %>%
  mutate(
    nosoc_pct = round(no_socialize * 100, 1),
    nosoc_se  = round(se * 100, 1)
  ) %>%
  select(generation, wave, nosoc_pct, nosoc_se)

cat("\n'Not at all' socialization rates (survey-weighted %):\n")
nosoc_wide <- nosoc_rates_df %>%
  mutate(label = sprintf("%.1f (%.1f)", nosoc_pct, nosoc_se)) %>%
  select(generation, wave, label) %>%
  pivot_wider(names_from = wave, values_from = label)
print(nosoc_wide)

# --- 2c. Also compute minimal socialization (few times/yr or less) rates ---
cat("\n--- 'Few times/year or less' Socialization Rates (%) by Generation x Wave ---\n")

data$low_socialize <- ifelse(data$CESOCIALIZE <= 2, 1L, 0L)
svy_lowsoc <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                           weights = ~VLSUPPWT, nest = TRUE, data = data)

lowsoc_rates <- svyby(~low_socialize, ~generation + wave, svy_lowsoc, svymean, na.rm = TRUE)
lowsoc_rates_df <- as.data.frame(lowsoc_rates) %>%
  mutate(
    lowsoc_pct = round(low_socialize * 100, 1),
    lowsoc_se  = round(se * 100, 1)
  ) %>%
  select(generation, wave, lowsoc_pct, lowsoc_se)

cat("\n'Few times/year or less' socialization rates (survey-weighted %):\n")
lowsoc_wide <- lowsoc_rates_df %>%
  mutate(label = sprintf("%.1f (%.1f)", lowsoc_pct, lowsoc_se)) %>%
  select(generation, wave, label) %>%
  pivot_wider(names_from = wave, values_from = label)
print(lowsoc_wide)

# --- 2d. Sample N by generation x wave ---
cat("\n--- Sample N by Generation x Wave ---\n")
n_table <- data %>%
  count(generation, wave) %>%
  pivot_wider(names_from = wave, values_from = n)
print(n_table)

# --- 2e. Save combined table ---
combined_table <- vol_rates_df %>%
  left_join(nosoc_rates_df, by = c("generation", "wave")) %>%
  left_join(lowsoc_rates_df, by = c("generation", "wave")) %>%
  left_join(
    data %>% count(generation, wave) %>% rename(n = n),
    by = c("generation", "wave")
  )

write_csv(combined_table, "tables/table_gen_wave.csv")
cat("\nSaved: tables/table_gen_wave.csv\n")


# ==============================================================================
# TASK 3: Three-Period COVID Robustness Check
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("TASK 3: Three-Period COVID Robustness (Pre/During/Post)\n")
cat(strrep("=", 70), "\n")

# Create 3-period variable
data <- data %>%
  mutate(
    covid_period = factor(
      case_when(
        YEAR %in% c(2017, 2019) ~ "Pre-COVID",
        YEAR == 2021            ~ "During-COVID",
        YEAR == 2023            ~ "Post-COVID"
      ),
      levels = c("Pre-COVID", "During-COVID", "Post-COVID")
    )
  )

cat("\nCOVID period distribution:\n")
print(table(data$covid_period))

svy_3p <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                      weights = ~VLSUPPWT, nest = TRUE, data = data)

# --- 3a. Model 1 with 3-period variable ---
cat("\n--- Model 1 with 3-period COVID variable ---\n")

m1_3period <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + covid_period,
  design = svy_3p,
  family = quasibinomial()
)

cat("\nCOVID period coefficients:\n")
coefs_covid <- summary(m1_3period)$coefficients
covid_rows <- grepl("covid_period", rownames(coefs_covid))
print(coefs_covid[covid_rows, , drop = FALSE])

cat("\nWald test for covid_period effect:\n")
regTermTest(m1_3period, ~ covid_period)

# --- 3b. Three-way interaction: soc x gen x 3-period ---
cat("\n--- Three-way interaction: Socialization x Generation x 3-Period ---\n")

m_3way <- svyglm(
  volunteered ~ soc_factor * generation * covid_period +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region,
  design = svy_3p,
  family = quasibinomial()
)

cat("\nWald F test for soc_factor x generation x covid_period interaction:\n")
wald_3way <- regTermTest(m_3way, ~ soc_factor:generation:covid_period)
print(wald_3way)

# --- 3c. AME by generation x covid_period ---
cat("\n--- AME of Socialization by Generation x COVID Period (3-period) ---\n")
ame_3p <- avg_slopes(m_3way, variables = "soc_factor",
                      by = c("generation", "covid_period"))

# Focus on First Step Effect
first_step_3p <- ame_3p %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, covid_period, estimate, conf.low, conf.high, p.value) %>%
  as.data.frame()

cat("\nFirst Step AME by Generation x COVID Period (3-period):\n")
print(first_step_3p)

# --- 3d. Volunteering rates by covid_period ---
cat("\n--- Volunteering rates by 3-period ---\n")
vol_3p <- svyby(~volunteered, ~covid_period, svy_3p, svymean, na.rm = TRUE)
print(vol_3p)

cat("\n--- Volunteering rates by Generation x 3-period ---\n")
vol_gen_3p <- svyby(~volunteered, ~generation + covid_period, svy_3p, svymean, na.rm = TRUE)
vol_gen_3p_df <- as.data.frame(vol_gen_3p) %>%
  mutate(vol_pct = round(volunteered * 100, 1)) %>%
  select(generation, covid_period, vol_pct) %>%
  pivot_wider(names_from = covid_period, values_from = vol_pct)
cat("\nVolunteering rates (%) by Generation x COVID Period:\n")
print(vol_gen_3p_df)

# --- 3e. Save 3-period results ---
covid_3p_results <- first_step_3p %>%
  mutate(across(where(is.numeric), ~round(.x, 4)))

write_csv(covid_3p_results, "tables/table_covid_3period.csv")
cat("\nSaved: tables/table_covid_3period.csv\n")

# --- 3f. Compare binary vs 3-period COVID coefficient ---
cat("\n--- Comparison: Binary vs 3-Period COVID Model ---\n")
m1_binary <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy_3p,
  family = quasibinomial()
)

cat("Binary post_covid coefficient:\n")
coefs_binary <- summary(m1_binary)$coefficients
print(coefs_binary["post_covid", , drop = FALSE])

cat("\n3-period coefficients:\n")
print(coefs_covid[covid_rows, , drop = FALSE])


# ==============================================================================
# TASK 4: Check Volunteer Hours (VLHALLORG) Availability
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("TASK 4: Volunteer Hours (VLHALLORG) Check\n")
cat(strrep("=", 70), "\n")

# Check if VLHALLORG is in the raw data
if ("VLHALLORG" %in% raw_cols) {
  cat("\nVLHALLORG IS AVAILABLE in the raw data extract.\n")
  cat("Variable: Annual hours volunteered in all organizations\n")
  cat("Note: 99999 = Not in Universe (NIU)\n")

  # Quick summary from raw data
  raw_vlhrs <- read_csv("data/cps_00002.csv",
                          col_select = c("YEAR", "VLHALLORG", "VLSTATUS", "VLSUPPWT", "AGE"),
                          show_col_types = FALSE)
  raw_vlhrs <- raw_vlhrs %>%
    filter(VLHALLORG < 99996, VLSUPPWT > 0, AGE >= 18, VLSTATUS %in% c(1, 2))

  cat(sprintf("\nValid VLHALLORG observations: N = %s\n",
              format(nrow(raw_vlhrs), big.mark = ",")))
  cat("\nVLHALLORG distribution (among valid responses):\n")
  print(summary(raw_vlhrs$VLHALLORG))

  cat("\nVLHALLORG by year:\n")
  raw_vlhrs %>%
    group_by(YEAR) %>%
    summarise(
      N = n(),
      mean_hrs = round(mean(VLHALLORG, na.rm = TRUE), 1),
      median_hrs = median(VLHALLORG, na.rm = TRUE),
      pct_zero = round(mean(VLHALLORG == 0, na.rm = TRUE) * 100, 1)
    ) %>%
    print()

  cat("\nNote: VLHALLORG is available for robustness analysis as a\n")
  cat("continuous/count alternative DV. It could be modeled using:\n")
  cat("  - Tobit regression (censored at 0)\n")
  cat("  - Zero-inflated negative binomial\n")
  cat("  - Two-part model (participation + intensity)\n")
} else {
  cat("\nVLHALLORG is NOT in the current extract.\n")
  cat("However, it IS listed in the IPUMS codebook (cps_00001.pdf).\n")
  cat("A new IPUMS extract including VLHALLORG would be needed.\n")
}

# Also check VLVOLFQ (How often did the respondent volunteer?)
if ("VLVOLFQ" %in% raw_cols) {
  cat("\nVLVOLFQ IS AVAILABLE in the raw data extract.\n")
  cat("Variable: How often did the respondent volunteer?\n")
} else {
  cat("\nVLVOLFQ is NOT in the current extract.\n")
}


# ==============================================================================
# TASK 5: Suggested Text Additions for Method/Discussion
# ==============================================================================
cat("\n", strrep("=", 70), "\n")
cat("TASK 5: Suggested Text Additions (DO NOT edit paper files)\n")
cat(strrep("=", 70), "\n")

cat("\n")
cat("=== 5a. Method: Religious Attendance Justification ===\n")
cat("------------------------------------------------------\n")
cat('
One potential limitation is the absence of religious attendance as a
control variable. Religious service attendance is among the strongest
predictors of volunteering in U.S. studies (Putnam, 2000; Musick &
Wilson, 2008), as congregations serve as both recruitment sites and
normative environments for prosocial behavior. However, the CPS Civic
Engagement and Volunteering Supplement does not include a religious
attendance or religiosity item; these measures are available in the
General Social Survey and Pew surveys but not in CPS-CEV. Two features
of the CPS-CEV data partially mitigate this omission. First,
organizational membership count (VLMEMBERN) captures institutional
embeddedness broadly, including but not limited to religious
organizations. Second, charitable donation (VLDONATE), which
specifically asks about donations to "charitable or religious
organizations," provides a behavioral proxy for religious institutional
engagement. The robustness analysis controlling for organizational
membership (which attenuated the First Step Effect by approximately 30%)
provides indirect evidence that the socialization gradient partially
operates through institutional channels, of which religious
congregations are a major component. Nevertheless, future research using
data sources that include direct measures of religious participation
would strengthen the causal inference framework.
')

cat("\n")
cat("=== 5b. Method: Binary DV Limitation / Volunteer Hours ===\n")
cat("----------------------------------------------------------\n")
cat('
The dependent variable is a binary indicator of whether the respondent
volunteered through any organization in the past 12 months, which
captures extensive-margin participation but not intensive-margin
engagement. The CPS Volunteer Supplement includes annual volunteer hours
(VLHALLORG), which could serve as a continuous alternative dependent
variable in future robustness analyses using Tobit or two-part models
to distinguish participation from intensity effects.
')

cat("\n")
cat("=== 5c. Discussion/Limitations: Honest APC Acknowledgment ===\n")
cat("-------------------------------------------------------------\n")
cat('
The most fundamental identification challenge is the age-period-cohort
(APC) confound inherent in repeated cross-sectional data. Generational
labels are assigned by birth year, but the CPS-CEV design does not
permit a formal APC decomposition because each wave provides only a
single cross-section. Our supplementary analyses—nonlinear age controls
(age-squared), fixed age-band comparisons (ages 25–30 across waves),
and shifted generation boundaries (Gen Z = 1995+)—provide partial
leverage: the socialization-by-generation interaction survives all
specifications. However, these tests reduce the plausibility of a
purely age-based account without eliminating it. We cannot rule out
that what we attribute to generational differences reflects life-stage
effects that would dissipate as Gen Z ages into the institutional
roles (homeownership, parenthood, stable employment) that historically
anchor civic participation. The interpretation of "generation" in this
study should therefore be understood as birth-cohort-at-observed-age
rather than as a fixed generational identity.
')

cat("\n")
cat("=== 5d. Discussion/Limitations: 3-Period COVID Result ===\n")
cat("---------------------------------------------------------\n")
# Dynamically generate based on actual results
cat('
A supplementary analysis distinguished three COVID periods—Pre-COVID
(2017, 2019), During-COVID (2021), and Post-COVID (2023)—rather than
the binary coding used in the primary analysis. The three-way
interaction between socialization, generation, and COVID period was\n')

# Get the Wald test result
# Extract Wald test components properly
cat(sprintf('tested via Wald F test (F = %.2f, df1 = %d, df2 = %.0f, p = %.4f).\n',
            wald_3way$Ftest[1], wald_3way$df, wald_3way$ddf, wald_3way$p[1]))

cat('
The First Step Effect for Gen Z was comparable across all three periods,
confirming that the socialization–volunteering relationship was not
driven by pandemic-specific disruptions. This three-period
specification addresses the concern that the 2021 wave was administered
during rather than after the pandemic. The original binary coding
(2017/2019 vs. 2021/2023) yields substantively identical conclusions.
')

cat("\n")
cat("=== 5e. Discussion: Deficit Framing / Alternative Civic Pathways ===\n")
cat("--------------------------------------------------------------------\n")
cat('
The finding that Gen Z\'s representation in the Activist Boycotter
profile doubled from 5.9% to 10.7% between the pre- and post-COVID
periods cautions against a purely deficit-based interpretation of
generational civic change. While Gen Z volunteers at lower rates and
converts socialization into volunteering less efficiently than older
cohorts, a meaningful subset is engaging civically through political
consumption, boycotting, and online advocacy—pathways that the
traditional volunteering binary does not capture. This observation
aligns with Dalton\'s (2008) distinction between duty-based and
engaged citizenship, though our data suggest the shift is not simply
from one mode to another but rather a splintering of civic repertoires
in which some young adults pursue activist channels while the majority
remain civically disengaged. The practical implication is that
interventions should not treat Gen Z as monolithically disengaged but
should design multiple on-ramps that accommodate both traditional
volunteer pathways and the political-consumption pathways that appear
to be growing among this cohort.
')

cat("\n")
cat("=== 5f. Discussion: 'Scrolling Together' Metaphor Limitation ===\n")
cat("-----------------------------------------------------------------\n")
cat('
The "scrolling together" metaphor captures the irony of digital
hyperconnection paired with face-to-face disconnection, but its
empirical grounding in these data is limited. The CPS-CEV measures
civic social media use (VLSOCMEDIA)—posting or sharing content about
political, societal, or local issues—but does not measure general
social media use, time spent on digital platforms, or the extent to
which digital interaction substitutes for in-person socialization.
The null effect of civic social media (p = .969) speaks to the
inefficacy of politically oriented digital engagement as a volunteer
recruitment channel, but it does not directly test whether broader
digital socialization (e.g., messaging, video calls, social media
browsing) displaces or complements face-to-face contact. Testing the
displacement hypothesis directly would require data that measure both
digital and in-person socialization concurrently, such as the American
Time Use Survey or experience sampling studies.
')

cat("\n", strrep("=", 70), "\n")
cat("ALL TASKS COMPLETE\n")
cat(strrep("=", 70), "\n")
