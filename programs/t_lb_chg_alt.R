# ------------------------------------------------------------------
# Program:  t_lb_chg_alt.R
# Purpose:  Table 14.3.4 ALT: value and change from baseline by visit,
#           safety population
# Input:    outputs/datasets/adsl.rds, outputs/datasets/adlb.rds
# Output:   outputs/tlf/t_lb_chg_alt.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(dplyr)
library(rtables)
library(tern)

arm_levels <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")

adsl_saf <- readRDS("outputs/datasets/adsl.rds") %>%
  filter(SAFFL == "Y") %>%
  mutate(TRTA = factor(TRT01A, levels = arm_levels)) %>%
  df_explicit_na()

adlb_alt <- readRDS("outputs/datasets/adlb.rds") %>%
  filter(PARAMCD == "ALT", !is.na(AVISITN),
         USUBJID %in% adsl_saf$USUBJID) %>%
  arrange(AVISITN) %>%
  mutate(
    TRTA   = factor(TRTA, levels = arm_levels),
    AVISIT = factor(AVISIT, levels = unique(AVISIT))   # Baseline, Week 2, ...
  )

lyt <- basic_table(
  title          = paste("Table 14.3.4", unique(adlb_alt$PARAM),
                         "- Value and Change from Baseline by Visit"),
  subtitles      = "Safety Population",
  main_footer    = c("Baseline = last non-missing value on or before first dose.",
                     "Source: ADLB, ADSL. Program: programs/t_lb_chg_alt.R"),
  show_colcounts = TRUE
) %>%
  split_cols_by("TRTA") %>%
  split_rows_by("AVISIT", split_fun = drop_split_levels,
                label_pos = "visible", split_label = "Analysis Visit") %>%
  split_cols_by_multivar(vars = c("AVAL", "CHG"),
                         varlabels = c("Value at Visit", "Change from Baseline")) %>%
  summarize_colvars(.stats = c("n", "mean_sd", "median", "range"))

tbl <- build_table(lyt, adlb_alt, alt_counts_df = adsl_saf)
print(tbl)
export_as_txt(tbl, file = "outputs/tlf/t_lb_chg_alt.txt")
