# ------------------------------------------------------------------
# Program:  adsl.R
# Purpose:  Derive ADSL (subject-level analysis dataset)
# Input:    pharmaversesdtm::dm, pharmaversesdtm::ex
#           specs/adam_spec.csv
# Output:   outputs/datasets/adsl.rds
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(admiral)
library(dplyr)
library(pharmaversesdtm)

# ---- Spec: variable list and order --------------------------------
spec <- read.csv("specs/adam_spec.csv", stringsAsFactors = FALSE)
adsl_vars <- spec %>%
  filter(dataset == "ADSL") %>%
  arrange(order) %>%
  pull(variable)

# ---- Read SDTM; SAS-style blank strings become NA ------------------
dm <- convert_blanks_to_na(pharmaversesdtm::dm)
ex <- convert_blanks_to_na(pharmaversesdtm::ex)

# ---- EX: convert dose dates to datetimes ---------------------------
# Start: missing time imputed to 00:00:00 (default "first")
# End:   missing time imputed to 23:59:59 ("last")
ex_ext <- ex %>%
  derive_vars_dtm(dtc = EXSTDTC, new_vars_prefix = "EXST") %>%
  derive_vars_dtm(dtc = EXENDTC, new_vars_prefix = "EXEN",
                  time_imputation = "last")

# ---- ADSL derivations ----------------------------------------------
adsl <- dm %>%
  # Treatment variables (spec: missing for screen failures)
  mutate(
    TRT01P = if_else(ARM    == "Screen Failure", NA_character_, ARM),
    TRT01A = if_else(ACTARM == "Screen Failure", NA_character_, ACTARM)
  ) %>%
  # First valid dose datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = (EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", EXTRT))) &
      !is.na(EXSTDTM),
    new_vars    = exprs(TRTSDTM = EXSTDTM),
    order       = exprs(EXSTDTM, EXSEQ),
    mode        = "first"
  ) %>%
  # Last valid dose datetime
  derive_vars_merged(
    dataset_add = ex_ext,
    by_vars     = exprs(STUDYID, USUBJID),
    filter_add  = (EXDOSE > 0 | (EXDOSE == 0 & grepl("PLACEBO", EXTRT))) &
      !is.na(EXENDTM),
    new_vars    = exprs(TRTEDTM = EXENDTM),
    order       = exprs(EXENDTM, EXSEQ),
    mode        = "last"
  ) %>%
  # Dates from datetimes, then treatment duration
  derive_vars_dtm_to_dt(source_vars = exprs(TRTSDTM, TRTEDTM)) %>%
  derive_var_trtdurd() %>%
  # Age group and population flags
  mutate(
    AGEGR1 = case_when(
      AGE < 65  ~ "<65",
      AGE <= 80 ~ "65-80",
      AGE > 80  ~ ">80"
    ),
    ITTFL = if_else(ARM != "Screen Failure", "Y", "N"),
    SAFFL = if_else(!is.na(TRTSDT), "Y", "N")
  ) %>%
  # Keep only spec variables, in spec order
  select(all_of(adsl_vars))

# ---- Save ----------------------------------------------------------
saveRDS(adsl, "outputs/datasets/adsl.rds")
