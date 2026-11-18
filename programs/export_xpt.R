# ------------------------------------------------------------------
# Program:  export_xpt.R
# Purpose:  Apply spec metadata (type, length, label, order, format)
#           with xportr, log mismatches, export SAS transport v5 files
# Input:    outputs/datasets/adsl.rds, adae.rds, adlb.rds
#           specs/adam_spec.csv
# Output:   outputs/datasets/adsl.xpt, adae.xpt, adlb.xpt
#           outputs/datasets/xportr_log.txt
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(xportr)
library(dplyr)

# Variable-level metadata (blank format cells become NA)
spec <- read.csv("specs/adam_spec.csv", stringsAsFactors = FALSE,
                 na.strings = "")

# Dataset-level metadata (dataset labels)
ds_meta <- data.frame(
  dataset = c("ADSL", "ADAE", "ADLB"),
  label   = c("Subject-Level Analysis Dataset",
              "Adverse Events Analysis Dataset",
              "Laboratory Analysis Dataset")
)

log_file <- "outputs/datasets/xportr_log.txt"
cat("xportr log -", format(Sys.time()), "\n", file = log_file)

export_one <- function(name) {
  df   <- readRDS(file.path("outputs/datasets", paste0(tolower(name), ".rds")))
  msgs <- character()

  withCallingHandlers(
    df %>%
      xportr_metadata(spec, domain = name) %>%
      xportr_type(verbose = "warn") %>%
      xportr_length(verbose = "warn") %>%
      xportr_label(verbose = "warn") %>%
      xportr_order(verbose = "warn") %>%
      xportr_format() %>%
      xportr_df_label(ds_meta, domain = name) %>%
      xportr_write(file.path("outputs/datasets",
                             paste0(tolower(name), ".xpt"))),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w)); invokeRestart("muffleWarning")
    },
    message = function(m) {
      msgs <<- c(msgs, conditionMessage(m)); invokeRestart("muffleMessage")
    }
  )

  cat("\n==", name, "==\n",
      if (length(msgs)) paste(msgs, collapse = "\n") else "No messages",
      "\n", file = log_file, append = TRUE)
  cat(name, ":", length(msgs), "message(s)\n")
}

for (d in c("ADSL", "ADAE", "ADLB")) export_one(d)
