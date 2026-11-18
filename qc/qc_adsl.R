# ------------------------------------------------------------------
# Program:  qc_adsl.R
# Purpose:  Independent QC (double programming) of ADSL derived
#           variables, written from specs/adam_spec.csv derivation
#           text using base R only (no admiral, no dplyr)
# Input:    pharmaversesdtm::dm, pharmaversesdtm::ex
#           outputs/datasets/adsl.rds (production, for comparison)
# Output:   qc/qc_adsl.rds, qc/qc_adsl_diffdf.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(diffdf)

blank_to_na <- function(df) {
  df[] <- lapply(df, function(x) if (is.character(x)) replace(x, x == "", NA) else x)
  df
}

dm <- blank_to_na(as.data.frame(pharmaversesdtm::dm))
ex <- blank_to_na(as.data.frame(pharmaversesdtm::ex))

# ---- Valid doses: EXDOSE > 0, or EXDOSE = 0 and EXTRT contains PLACEBO ----
valid <- !is.na(ex$EXDOSE) &
  (ex$EXDOSE > 0 | (ex$EXDOSE == 0 & grepl("PLACEBO", ex$EXTRT)))
exv <- ex[valid, ]

# Complete dates only (partial dates -> NA, matching "no date imputation")
exv$stdt <- as.Date(substr(exv$EXSTDTC, 1, 10), format = "%Y-%m-%d")
exv$endt <- as.Date(substr(exv$EXENDTC, 1, 10), format = "%Y-%m-%d")

first_date <- function(x) if (all(is.na(x))) NA_real_ else min(x, na.rm = TRUE)
last_date  <- function(x) if (all(is.na(x))) NA_real_ else max(x, na.rm = TRUE)

ids <- sort(unique(exv$USUBJID))
trt <- data.frame(
  USUBJID = ids,
  TRTSDT  = as.Date(sapply(split(exv$stdt, exv$USUBJID)[ids], first_date)),
  TRTEDT  = as.Date(sapply(split(exv$endt, exv$USUBJID)[ids], last_date))
)

# ---- Subject level ---------------------------------------------------
qc <- merge(dm[, c("USUBJID", "ARM", "ACTARM", "AGE")], trt,
            by = "USUBJID", all.x = TRUE)

qc$TRT01P  <- ifelse(qc$ARM    == "Screen Failure", NA, qc$ARM)
qc$TRT01A  <- ifelse(qc$ACTARM == "Screen Failure", NA, qc$ACTARM)
qc$TRTDURD <- as.numeric(qc$TRTEDT - qc$TRTSDT) + 1
qc$AGEGR1  <- ifelse(qc$AGE < 65, "<65", ifelse(qc$AGE <= 80, "65-80", ">80"))
qc$ITTFL   <- ifelse(qc$ARM != "Screen Failure", "Y", "N")
qc$SAFFL   <- ifelse(!is.na(qc$TRTSDT), "Y", "N")

qc_vars <- c("USUBJID", "TRT01P", "TRT01A", "TRTSDT", "TRTEDT",
             "TRTDURD", "AGEGR1", "ITTFL", "SAFFL")
qc_adsl <- qc[, qc_vars]
saveRDS(qc_adsl, "qc/qc_adsl.rds")

# ---- Compare with production ----------------------------------------
prod <- as.data.frame(readRDS("outputs/datasets/adsl.rds"))[, qc_vars]

# Compare values only: variable labels are metadata, applied and
# verified separately by xportr (Step 5). See qc/qc_log.md, QC-001.
prod    <- haven::zap_label(prod)
qc_adsl <- haven::zap_label(qc_adsl)

res <- diffdf(base = prod, compare = qc_adsl, keys = "USUBJID",
              file = "qc/qc_adsl_diffdf.txt")
print(res)
cat("\nADSL QC - issues found:", diffdf_has_issues(res), "\n")
