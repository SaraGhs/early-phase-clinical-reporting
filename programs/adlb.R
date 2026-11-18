# ------------------------------------------------------------------
# Program:  adlb.R
# Purpose:  Derive ADLB (laboratory analysis dataset)
# Input:    pharmaversesdtm::lb, outputs/datasets/adsl.rds
#           specs/adam_spec.csv
# Output:   outputs/datasets/adlb.rds
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(admiral)
library(dplyr)
library(pharmaversesdtm)

# ---- Spec: variable list and order --------------------------------
spec <- read.csv("specs/adam_spec.csv", stringsAsFactors = FALSE)
adlb_vars <- spec %>%
  filter(dataset == "ADLB") %>%
  arrange(order) %>%
  pull(variable)

# ---- Inputs ---------------------------------------------------------
adsl <- readRDS("outputs/datasets/adsl.rds")
lb   <- convert_blanks_to_na(pharmaversesdtm::lb)

# ---- Parameters, values, dates --------------------------------------
adlb <- lb %>%
  derive_vars_merged(
    dataset_add = adsl,
    by_vars     = exprs(STUDYID, USUBJID),
    new_vars    = exprs(TRTA = TRT01A, TRTSDT)
  ) %>%
  mutate(
    PARAMCD = LBTESTCD,
    PARAM   = if_else(is.na(LBSTRESU), LBTEST,
                      paste0(LBTEST, " (", LBSTRESU, ")")),
    PARCAT1 = LBCAT,
    AVAL    = LBSTRESN,
    ANRLO   = LBSTNRLO,
    ANRHI   = LBSTNRHI
  ) %>%
  derive_vars_dt(dtc = LBDTC, new_vars_prefix = "A") %>%      # ADT, no imputation
  derive_vars_dy(reference_date = TRTSDT, source_vars = exprs(ADT)) %>%

  # ---- Reference range indicator -----------------------------------
mutate(
  ANRIND = case_when(
    is.na(AVAL)                     ~ NA_character_,
    !is.na(ANRLO) & AVAL < ANRLO    ~ "LOW",
    !is.na(ANRHI) & AVAL > ANRHI    ~ "HIGH",
    !is.na(ANRLO) | !is.na(ANRHI)   ~ "NORMAL",
    TRUE                            ~ NA_character_
  )
) %>%

  # ---- Baseline: last non-missing value on/before first dose ---------
restrict_derivation(
  derivation = derive_var_extreme_flag,
  args = params(
    by_vars = exprs(STUDYID, USUBJID, PARAMCD),
    order   = exprs(ADT, LBSEQ),
    new_var = ABLFL,
    mode    = "last"
  ),
  filter = !is.na(AVAL) & !is.na(TRTSDT) & ADT <= TRTSDT
) %>%
  derive_var_base(by_vars = exprs(STUDYID, USUBJID, PARAMCD),
                  source_var = AVAL,   new_var = BASE) %>%
  derive_var_base(by_vars = exprs(STUDYID, USUBJID, PARAMCD),
                  source_var = ANRIND, new_var = BNRIND) %>%

  # ---- Post-baseline: change, percent change, shift, visits ---------
mutate(
  postbl  = !is.na(ADT) & !is.na(TRTSDT) & ADT > TRTSDT,
  CHG     = if_else(postbl, AVAL - BASE, NA_real_),
  PCHG    = if_else(postbl & !is.na(BASE) & BASE != 0,
                    (AVAL - BASE) / BASE * 100, NA_real_),
  SHIFT1  = if_else(postbl & !is.na(BNRIND) & !is.na(ANRIND),
                    paste(BNRIND, "to", ANRIND), NA_character_),
  weekvis = postbl & grepl("^WEEK [0-9]+$", VISIT),
  AVISIT  = case_when(
    ABLFL == "Y" ~ "Baseline",
    weekvis      ~ sub("WEEK", "Week", VISIT),
    TRUE         ~ NA_character_
  ),
  AVISITN = case_when(
    ABLFL == "Y" ~ 0,
    weekvis      ~ as.numeric(sub("WEEK ", "", VISIT)),
    TRUE         ~ NA_real_
  )
) %>%
  select(all_of(adlb_vars))

# ---- Save ----------------------------------------------------------
saveRDS(adlb, "outputs/datasets/adlb.rds")
