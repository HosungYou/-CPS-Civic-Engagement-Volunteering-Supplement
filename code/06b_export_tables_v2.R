# ==============================================================================
# 06b_export_tables_v2.R — Streamlined tables for revised manuscript
# ==============================================================================

library(tidyverse)
library(survey)

data <- readRDS("data/cev_clean.rds")

# --- Table 1: Trimmed Sample Characteristics ----------------------------------
cat("Exporting Table 1 (trimmed)...\n")
table1 <- data %>%
  group_by(generation) %>%
  summarise(
    N = format(n(), big.mark = ","),
    `Age (M)` = sprintf("%.1f", mean(AGE)),
    `Female (%)` = sprintf("%.1f", mean(female) * 100),
    `BA+ (%)` = sprintf("%.1f", mean(ba_plus) * 100),
    `Vol. Rate (%)` = sprintf("%.1f", mean(volunteered) * 100),
    `Soc. (M)` = sprintf("%.2f", mean(CESOCIALIZE, na.rm = TRUE)),
    `Min. Soc. (%)` = sprintf("%.1f", mean(CESOCIALIZE == 1, na.rm = TRUE) * 100),
    .groups = "drop"
  ) %>%
  rename(Generation = generation)

write_csv(table1, "tables/table1_sample_characteristics.csv")

# --- Table 3: LPA Profiles (reordered by engagement intensity) ----------------
cat("Exporting Table 3 (LPA profiles, reordered)...\n")
data_lpa <- readRDS("data/cev_with_profiles.rds")

# Build raw profile stats
prof_raw <- data_lpa %>%
  group_by(profile) %>%
  summarise(
    N = n(),
    pct_sample = n() / nrow(data_lpa) * 100,
    boycott = mean(boycott, na.rm = TRUE) * 100,
    puboff = mean(puboff, na.rm = TRUE) * 100,
    polconv = mean(polconv, na.rm = TRUE),
    socialize = mean(socialize, na.rm = TRUE),
    membership = mean(membership, na.rm = TRUE),
    donated = mean(donated, na.rm = TRUE) * 100,
    vol_rate = mean(volunteered, na.rm = TRUE) * 100,
    .groups = "drop"
  )

# Assign labels based on characteristics (match paper ordering)
# Map mclust profile numbers to paper labels using indicator patterns:
# Isolated Disengaged: lowest everything, vol ~9%
# Politically Aware Isolated: low soc, high polconv, no boycott/donate
# Socially Active Non-Donors: highest soc, no donate, low vol
# Mainstream Donors: largest class, ~100% donate, moderate everything
# Activist Boycotters: 100% boycott
# Fully Engaged: 100% puboff, highest of most

label_map <- prof_raw %>%
  mutate(label = case_when(
    boycott > 95 & puboff < 5 ~ "Activist Boycotters",
    puboff > 95 ~ "Fully Engaged",
    donated > 95 ~ "Mainstream Donors",
    socialize > 4 & donated < 5 ~ "Socially Active Non-Donors",
    polconv > 4 & socialize < 2 ~ "Politically Aware Isolated",
    TRUE ~ "Isolated Disengaged"
  ))

# Paper ordering
order_vec <- c("Isolated Disengaged", "Politically Aware Isolated",
               "Socially Active Non-Donors", "Mainstream Donors",
               "Activist Boycotters", "Fully Engaged")

table3 <- label_map %>%
  mutate(label = factor(label, levels = order_vec)) %>%
  arrange(label) %>%
  transmute(
    Profile = label,
    `% Sample` = sprintf("%.1f", pct_sample),
    `Boycott (%)` = sprintf("%.1f", boycott),
    `Contact Off. (%)` = sprintf("%.1f", puboff),
    `Pol. Conv. (M)` = sprintf("%.2f", polconv),
    `Socialize (M)` = sprintf("%.2f", socialize),
    `Org. Memb. (M)` = sprintf("%.2f", membership),
    `Donated (%)` = sprintf("%.1f", donated),
    `Vol. Rate (%)` = sprintf("%.1f", vol_rate)
  )

write_csv(table3, "tables/table5_lpa_profiles.csv")

# --- Table 4: Generation × Profile Distribution (with labels) ----------------
cat("Exporting Table 4 (gen × profile, labeled)...\n")

# Create label column in data
profile_labels <- label_map %>% select(profile, label)
data_lpa2 <- data_lpa %>% left_join(profile_labels, by = "profile")

table4 <- data_lpa2 %>%
  count(generation, label) %>%
  group_by(generation) %>%
  mutate(pct = sprintf("%.1f", n / sum(n) * 100)) %>%
  select(-n) %>%
  mutate(label = factor(label, levels = order_vec)) %>%
  arrange(label) %>%
  pivot_wider(names_from = label, values_from = pct) %>%
  rename(Generation = generation)

write_csv(table4, "tables/table6_gen_profile_dist.csv")

cat("Tables exported.\n")
