# ------------------------------------------------------------------
# Program:  t_demog.R
# Purpose:  Table 14.1.1 Demographic characteristics, safety population
# Input:    outputs/datasets/adsl.rds
# Output:   outputs/tlf/t_demog.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(dplyr)
library(rtables)
library(tern)

arm_levels <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")

adsl_saf <- readRDS("outputs/datasets/adsl.rds") %>%
  filter(SAFFL == "Y") %>%
  mutate(
    TRTA   = factor(TRT01A, levels = arm_levels),
    AGEGR1 = factor(AGEGR1, levels = c("<65", "65-80", ">80"))
  ) %>%
  df_explicit_na()

lyt <- basic_table(
  title          = "Table 14.1.1 Demographic Characteristics",
  subtitles      = "Safety Population",
  main_footer    = "Source: ADSL. Program: programs/t_demog.R",
  show_colcounts = TRUE
) %>%
  split_cols_by("TRTA") %>%
  add_overall_col("All Patients") %>%
  analyze_vars(
    vars       = c("AGE", "AGEGR1", "SEX", "RACE"),
    var_labels = c("Age (years)", "Age group", "Sex", "Race")
  )

tbl <- build_table(lyt, adsl_saf)
print(tbl)
export_as_txt(tbl, file = "outputs/tlf/t_demog.txt")
