# ------------------------------------------------------------------
# Program:  qc_adae.R
# Purpose:  Independent QC of ADAE key derived variables
#           (TRTA, ASTDT, ASTDTF, ASTDY, TRTEMFL), base R only,
#           using QC ADSL dates (not production)
# Input:    pharmaversesdtm::ae, qc/qc_adsl.rds
#           outputs/datasets/adae.rds (production, for comparison)
# Output:   qc/qc_adae_diffdf.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(diffdf)

blank_to_na <- function(df) {
  df[] <- lapply(df, function(x) if (is.character(x)) replace(x, x == "", NA) else x)
  df
}

ae      <- blank_to_na(as.data.frame(pharmaversesdtm::ae))
qc_adsl <- readRDS("qc/qc_adsl.rds")

qc <- merge(ae[, c("USUBJID", "AESEQ", "AESTDTC")],
            qc_adsl[, c("USUBJID", "TRT01A", "TRTSDT", "TRTEDT")],
            by = "USUBJID", all.x = TRUE)
names(qc)[names(qc) == "TRT01A"] <- "TRTA"

# ---- ASTDT: impute partial start dates -------------------------------
# Spec: earliest possible date, but not earlier than TRTSDT
d <- substr(qc$AESTDTC, 1, 10)
n <- nchar(d)

is_full  <- !is.na(n) & n == 10
is_ym    <- !is.na(n) & n == 7     # "YYYY-MM": day missing
is_y     <- !is.na(n) & n == 4     # "YYYY": month and day missing

qc$ASTDT <- as.Date(NA)
qc$ASTDT[is_full] <- as.Date(d[is_full], format = "%Y-%m-%d")
qc$ASTDT[is_ym]   <- as.Date(paste0(d[is_ym], "-01"), format = "%Y-%m-%d")
qc$ASTDT[is_y]    <- as.Date(paste0(d[is_y], "-01-01"), format = "%Y-%m-%d")

# If first dose falls inside the partial period, use first dose date
same_month <- is_ym & !is.na(qc$TRTSDT) & format(qc$TRTSDT, "%Y-%m") == d
same_year  <- is_y  & !is.na(qc$TRTSDT) & format(qc$TRTSDT, "%Y")    == d
qc$ASTDT[same_month | same_year] <- qc$TRTSDT[same_month | same_year]

qc$ASTDTF <- ifelse(is_ym, "D", ifelse(is_y, "M", NA))

# ---- ASTDY: no day 0 --------------------------------------------------
diff_days <- as.numeric(qc$ASTDT - qc$TRTSDT)
qc$ASTDY  <- ifelse(diff_days >= 0, diff_days + 1, diff_days)

# ---- TRTEMFL ---------------------------------------------------------
qc$TRTEMFL <- ifelse(
  !is.na(qc$ASTDT) & !is.na(qc$TRTSDT) & qc$ASTDT >= qc$TRTSDT &
    (is.na(qc$TRTEDT) | qc$ASTDT <= qc$TRTEDT + 30),
  "Y", NA)

qc_vars <- c("USUBJID", "AESEQ", "TRTA", "ASTDT", "ASTDTF", "ASTDY", "TRTEMFL")
qc_adae <- qc[, qc_vars]

# ---- Compare with production ----------------------------------------
prod <- as.data.frame(readRDS("outputs/datasets/adae.rds"))[, qc_vars]

# Compare values only: variable labels are metadata, applied and
# verified separately by xportr (Step 5). See qc/qc_log.md, QC-001.
prod    <- haven::zap_label(prod)
qc_adae <- haven::zap_label(qc_adae)

res <- diffdf(base = prod, compare = qc_adae, keys = c("USUBJID", "AESEQ"),
              file = "qc/qc_adae_diffdf.txt")
print(res)
cat("\nADAE QC - issues found:", diffdf_has_issues(res), "\n")
