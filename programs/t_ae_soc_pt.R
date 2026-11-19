# ------------------------------------------------------------------
# Program:  t_ae_soc_pt.R
# Purpose:  Table 14.3.1 Treatment-emergent adverse events by
#           system organ class and preferred term, safety population
# Input:    outputs/datasets/adsl.rds, outputs/datasets/adae.rds
# Output:   outputs/tlf/t_ae_soc_pt.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(dplyr)
library(rtables)
library(tern)

arm_levels <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")

# Denominators: treated subjects (column N)
adsl_saf <- readRDS("outputs/datasets/adsl.rds") %>%
  filter(SAFFL == "Y") %>%
  mutate(TRTA = factor(TRT01A, levels = arm_levels)) %>%
  df_explicit_na()

# Numerators: treatment-emergent AEs only
adae_te <- readRDS("outputs/datasets/adae.rds") %>%
  filter(SAFFL == "Y", TRTEMFL == "Y") %>%
  mutate(TRTA = factor(TRTA, levels = arm_levels)) %>%
  df_explicit_na()

lyt <- basic_table(
  title          = "Table 14.3.1 Treatment-Emergent Adverse Events by System Organ Class and Preferred Term",
  subtitles      = "Safety Population",
  main_footer    = c("A patient is counted once per SOC and once per preferred term.",
                     "Source: ADAE, ADSL. Program: programs/t_ae_soc_pt.R"),
  show_colcounts = TRUE
) %>%
  split_cols_by("TRTA") %>%
  add_overall_col("All Patients") %>%
  analyze_num_patients(
    vars    = "USUBJID",
    .stats  = c("unique", "nonunique"),
    .labels = c(unique    = "Total number of patients with at least one TEAE",
                nonunique = "Overall total number of TEAEs")
  ) %>%
  split_rows_by("AEBODSYS", child_labels = "visible", nested = FALSE,
                split_fun = drop_split_levels, label_pos = "hidden",
                split_label = "System Organ Class") %>%
  summarize_num_patients(
    var     = "USUBJID",
    .stats  = c("unique", "nonunique"),
    .labels = c(unique    = "Total number of patients with at least one TEAE",
                nonunique = "Total number of TEAEs")
  ) %>%
  count_occurrences(vars = "AEDECOD", .indent_mods = -1L)

tbl <- build_table(lyt, adae_te, alt_counts_df = adsl_saf) %>%
  # Most frequent SOCs first, then most frequent terms within each SOC
  sort_at_path(path = "AEBODSYS", scorefun = cont_n_allcols) %>%
  sort_at_path(path = c("AEBODSYS", "*", "AEDECOD"), scorefun = score_occurrences)

print(tbl)
export_as_txt(tbl, file = "outputs/tlf/t_ae_soc_pt.txt")
