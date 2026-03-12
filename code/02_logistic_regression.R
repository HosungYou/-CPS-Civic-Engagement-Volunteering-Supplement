# ==============================================================================
# 02_logistic_regression.R
# PRIMARY ANALYSIS: Survey-Weighted Logistic Regression
#
# Study: Bowling Alone, Scrolling Together
# Authors: Hosung You & Suzanna Windon
# Target: NVSQ
#
# Design: 4-wave pooled (2017/2019/2021/2023), N ≈ 201,000
#         post_covid binary (0 = 2017/2019, 1 = 2021/2023)
#
# RQ1: Socialization × Generation interaction (nonlinear threshold)
# RQ2: Three-way interactions (× Education, × Employment, × SM, × COVID)
# ==============================================================================

library(tidyverse)
library(survey)
library(marginaleffects)
library(broom)
library(gt)

set.seed(20260309)

# --- 1. Load Cleaned Data (4-wave pooled) -------------------------------------
data <- readRDS("data/cev_clean.rds")
cat(sprintf("Analytic sample: N = %s (4-wave pooled)\n",
            format(nrow(data), big.mark = ",")))
cat(sprintf("Pre-COVID: %s | Post-COVID: %s\n",
            format(sum(data$post_covid == 0), big.mark = ","),
            format(sum(data$post_covid == 1), big.mark = ",")))

# --- 2. Survey Design --------------------------------------------------------
# CPS uses stratified multistage cluster design.
# SERIAL provides household-level clustering; STATEFIP provides state stratification.
# IPUMS does not release actual PSU identifiers; this is the best available specification.
options(survey.lonely.psu = "adjust")
svy <- svydesign(ids = ~SERIAL, strata = ~STATEFIP,
                  weights = ~VLSUPPWT, nest = TRUE, data = data)

# --- 3. Model 1: RQ1 — Socialization × Generation ----------------------------
cat("\n=== Model 1: Socialization × Generation Interaction ===\n")

m1 <- svyglm(
  volunteered ~ soc_factor * generation +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
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
pred_m1_df <- as.data.frame(pred_m1[, c("soc_factor", "generation", "estimate", "conf.low", "conf.high")])
print(pred_m1_df)

# --- 4. Model 2: RQ2a — Three-Way Interaction (Education) --------------------
cat("\n=== Model 2: Socialization × Generation × Education ===\n")

m2_edu <- svyglm(
  volunteered ~ soc_factor * generation * ba_plus +
    AGE + female + race_eth + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m2_edu, ~ soc_factor:generation:ba_plus)

# --- 5. Model 3: RQ2b — Three-Way Interaction (Employment) -------------------
cat("\n=== Model 3: Socialization × Generation × Employment ===\n")

m3_emp <- svyglm(
  volunteered ~ soc_factor * generation * employed +
    AGE + female + race_eth + ba_plus +
    married + faminc_log + metro + region + post_covid,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m3_emp, ~ soc_factor:generation:employed)

# --- 6. Model 4: RQ2c — Three-Way Interaction (Civic Social Media) -----------
cat("\n=== Model 4: Socialization × Generation × Civic SM ===\n")

m4_sm <- svyglm(
  volunteered ~ soc_factor * generation * civic_sm +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region + post_covid,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m4_sm, ~ soc_factor:generation:civic_sm)

# --- 7. Model 5: RQ2d — Three-Way Interaction (Post-COVID) -------------------
cat("\n=== Model 5: Socialization × Generation × Post-COVID ===\n")

m5_covid <- svyglm(
  volunteered ~ soc_factor * generation * post_covid +
    AGE + female + race_eth + ba_plus + employed +
    married + faminc_log + metro + region,
  design = svy,
  family = quasibinomial()
)

cat("\nThree-way interaction test:\n")
regTermTest(m5_covid, ~ soc_factor:generation:post_covid)

# AME of socialization by generation × COVID period
cat("\nAME of Socialization by Generation × COVID Period:\n")
ame_m5 <- avg_slopes(m5_covid, variables = "soc_factor",
                      by = c("generation", "post_covid"))
print(ame_m5)

# --- 8. Predicted Probability Plots ------------------------------------------
# Key Figure: Socialization × Generation predicted probabilities

pred_df <- as_tibble(pred_m1) %>%
  select(soc_factor, generation, estimate, conf.low, conf.high)

gen_colors <- c(
  "Gen Z"       = "#E63946",
  "Millennial"  = "#457B9D",
  "Gen X"       = "#2A9D8F",
  "Boomer"      = "#E9C46A",
  "Silent"      = "#264653"
)

ggplot(pred_df, aes(x = soc_factor, y = estimate,
                    color = generation, group = generation)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high, fill = generation),
              alpha = 0.1, color = NA) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  scale_fill_manual(values = gen_colors, guide = "none") +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, NA)) +
  theme_minimal(base_size = 14) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1)) +
  labs(
    title = "Predicted Probability of Volunteering by Socialization and Generation",
    subtitle = "CPS-CEV 2017–2023, Survey-Weighted Logistic Regression",
    x = "In-Person Socialization Frequency",
    y = "Predicted Probability of Volunteering"
  )

ggsave("figures/pred_prob_soc_gen.png", width = 12, height = 8, dpi = 300)

# --- 9. AME Bar Plot: First Step Effect by Generation -------------------------
ame_first_step <- ame_m1 %>%
  filter(contrast == "Few times/yr - Not at all") %>%
  select(generation, estimate, conf.low, conf.high)

ggplot(ame_first_step, aes(x = generation, y = estimate, fill = generation)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  scale_fill_manual(values = gen_colors, guide = "none") +
  scale_y_continuous(labels = scales::percent_format()) +
  theme_minimal(base_size = 14) +
  labs(
    title = "First Step Effect: Marginal Gain from Minimal Socialization",
    subtitle = "AME of 'Not at all' → 'Few times/year', CPS-CEV 2017–2023",
    x = "", y = "Change in Volunteering Probability (pp)"
  )

ggsave("figures/ame_first_step.png", width = 10, height = 6, dpi = 300)

# --- 10. COVID Comparison Plot ------------------------------------------------
# Predicted probabilities: Pre vs Post COVID by generation
pred_covid <- predictions(m5_covid,
  newdata = datagrid(soc_factor = unique, generation = unique,
                     post_covid = c(0, 1)),
  type = "response"
)

pred_covid_df <- as_tibble(pred_covid) %>%
  mutate(period = ifelse(post_covid == 0, "Pre-COVID (2017/2019)",
                         "Post-COVID (2021/2023)")) %>%
  select(soc_factor, generation, period, estimate, conf.low, conf.high)

ggplot(pred_covid_df, aes(x = soc_factor, y = estimate,
                          color = generation, group = generation)) +
  geom_line(linewidth = 1) +
  geom_point(size = 2) +
  facet_wrap(~period) +
  scale_color_manual(values = gen_colors, name = "Generation") +
  scale_y_continuous(labels = scales::percent_format(), limits = c(0, NA)) +
  theme_minimal(base_size = 13) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(
    title = "Socialization–Volunteering Relationship: Pre vs Post COVID",
    x = "In-Person Socialization Frequency",
    y = "Predicted Probability of Volunteering"
  )

ggsave("figures/pred_prob_covid_comparison.png", width = 14, height = 7, dpi = 300)

# --- 11. Export Results -------------------------------------------------------
saveRDS(list(m1 = m1, m2_edu = m2_edu, m3_emp = m3_emp,
             m4_sm = m4_sm, m5_covid = m5_covid),
        "data/logistic_models.rds")

cat("\nAll 5 models saved to data/logistic_models.rds\n")
cat("Primary analysis complete.\n")
