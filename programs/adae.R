# ------------------------------------------------------------------
# Program:  adae.R
# Purpose:  Derive ADAE (adverse events analysis dataset)
# Input:    pharmaversesdtm::ae, outputs/datasets/adsl.rds
#           specs/adam_spec.csv
# Output:   outputs/datasets/adae.rds
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(admiral)
library(dplyr)
library(pharmaversesdtm)

# ---- Spec: variable list and order --------------------------------
spec <- read.csv("specs/adam_spec.csv", stringsAsFactors = FALSE)
adae_vars <- spec %>%
  filter(dataset == "ADAE") %>%
  arrange(order) %>%
  pull(variable)

# ---- Inputs ---------------------------------------------------------
adsl <- readRDS("outputs/datasets/adsl.rds")
ae   <- convert_blanks_to_na(pharmaversesdtm::ae)

# ---- Derivations ----------------------------------------------------
adae <- ae %>%
  # Bring in treatment and population info from ADSL
  derive_vars_merged(
    dataset_add = adsl,
    by_vars     = exprs(STUDYID, USUBJID),
    new_vars    = exprs(TRTA = TRT01A, SAFFL, TRTSDT, TRTEDT)
  ) %>%
  # Start date: impute missing day/month to earliest, not before TRTSDT
  derive_vars_dt(
    dtc                = AESTDTC,
    new_vars_prefix    = "AST",
    highest_imputation = "M",
    date_imputation    = "first",
    min_dates          = exprs(TRTSDT)
  ) %>%
  # End date: impute missing day/month to latest
  derive_vars_dt(
    dtc                = AEENDTC,
    new_vars_prefix    = "AEN",
    highest_imputation = "M",
    date_imputation    = "last"
  ) %>%
  # Study days (no day 0)
  derive_vars_dy(
    reference_date = TRTSDT,
    source_vars    = exprs(ASTDT, AENDT)
  ) %>%
  mutate(
    ASEV = AESEV,
    # Spec: Y if ASTDT >= TRTSDT and (ASTDT <= TRTEDT + 30, or TRTEDT missing)
    TRTEMFL = if_else(
      !is.na(ASTDT) & !is.na(TRTSDT) & ASTDT >= TRTSDT &
        (is.na(TRTEDT) | ASTDT <= TRTEDT + 30),
      "Y", NA_character_
    )
  ) %>%
  select(all_of(adae_vars))

# ---- Save ----------------------------------------------------------
saveRDS(adae, "outputs/datasets/adae.rds")
