# ------------------------------------------------------------------
# Program:  app/app.R
# Purpose:  Interactive exploration of ADSL, ADAE, ADLB with teal
# Input:    outputs/datasets/adsl.rds, adae.rds, adlb.rds
# Run:      shiny::runApp("app")   (from the project root)
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(teal)
library(teal.modules.clinical)

# Project root, found from any working directory (runApp switches to app/)
root <- rprojroot::find_root(rprojroot::has_file("renv.lock"))

# ---- Data: prepared inside within() so teal records the code ---------
data <- within(teal_data(), {
  library(dplyr)
  library(tern)

  arm_levels <- c("Placebo", "Xanomeline Low Dose", "Xanomeline High Dose")

  # Safety population only (exploratory safety app)
  ADSL <- readRDS(file.path(root, "outputs/datasets/adsl.rds")) %>%
    filter(SAFFL == "Y") %>%
    mutate(
      TRT01A = factor(TRT01A, levels = arm_levels),
      TRT01P = factor(TRT01P, levels = arm_levels),
      AGEGR1 = factor(AGEGR1, levels = c("<65", "65-80", ">80"))
    ) %>%
    df_explicit_na()

  ADAE <- readRDS(file.path(root, "outputs/datasets/adae.rds")) %>%
    filter(USUBJID %in% ADSL$USUBJID) %>%
    df_explicit_na()

  # Analysis visits only; AVALU (unit) derived from PARAM for plot labels
  ADLB <- readRDS(file.path(root, "outputs/datasets/adlb.rds")) %>%
    filter(USUBJID %in% ADSL$USUBJID, !is.na(AVISITN)) %>%
    arrange(AVISITN) %>%
    mutate(
      AVISIT = factor(AVISIT, levels = unique(AVISIT)),
      AVALU  = ifelse(grepl("\\)$", PARAM), sub(".*\\((.*)\\)$", "\\1", PARAM), NA)
    ) %>%
    df_explicit_na()

  rm(arm_levels)   # helper only; keep just the datasets in teal_data

  # Apply variable labels from the ADaM spec (teal modules use them as row labels)
  spec <- read.csv(file.path(root, "specs/adam_spec.csv"), stringsAsFactors = FALSE)
  for (ds in c("ADSL", "ADAE", "ADLB")) {
    df <- get(ds)
    s  <- spec[spec$dataset == ds, ]
    for (v in intersect(names(df), s$variable)) {
      attr(df[[v]], "label") <- s$label[s$variable == v]
    }
    assign(ds, df)
  }
  attr(ADLB$AVALU, "label") <- "Analysis Value Unit"   # app-only helper variable

  # Keep only the three datasets in teal_data
  rm(spec, ds, df, s, v, arm_levels)
}, root = root)


join_keys(data) <- join_keys(
  join_key("ADSL", "ADSL", c("STUDYID", "USUBJID")),
  join_key("ADAE", "ADAE", c("STUDYID", "USUBJID", "AESEQ")),
  join_key("ADLB", "ADLB", c("STUDYID", "USUBJID", "LBSEQ")),
  join_key("ADSL", "ADAE", c("STUDYID", "USUBJID")),
  join_key("ADSL", "ADLB", c("STUDYID", "USUBJID"))
)

# ---- Variable choices (teal.picks syntax, teal.modules.clinical >= 0.13) ----
arm_choices <- variables(choices = c("TRT01A", "TRT01P"), selected = "TRT01A")

# Lab parameter codes for the biomarker picker
param_codes <- sort(unique(readRDS(file.path(root, "outputs/datasets/adlb.rds"))$PARAMCD))

# ---- App -------------------------------------------------------------
app <- init(
  data   = data,
  filter = teal_slices(
    teal_slice(dataname = "ADAE", varname = "TRTEMFL", selected = "Y")
  ),
  modules = modules(
    tm_t_summary(
      label          = "Demographics",
      dataname       = "ADSL",
      arm_var        = arm_choices,
      summarize_vars = variables(
        choices  = c("AGE", "AGEGR1", "SEX", "RACE"),
        selected = c("AGE", "AGEGR1", "SEX", "RACE"),
        multiple = TRUE,
        ordered  = TRUE
      )
    ),
    tm_t_events(
      label      = "Adverse events by SOC / PT",
      dataname   = "ADAE",
      arm_var    = arm_choices,
      hlt        = variables(choices = "AEBODSYS", selected = "AEBODSYS"),
      llt        = variables(choices = "AEDECOD",  selected = "AEDECOD"),
      add_total  = TRUE,
      event_type = "treatment-emergent adverse event"
    ),
    tm_g_lineplot(
      label      = "Biomarker trajectories",
      dataname   = "ADLB",
      parentname = "ADSL",
      group_var  = variables(
        choices  = c("TRT01A", "TRT01P"),
        selected = "TRT01A",
        multiple = FALSE
      ),
      x = variables(choices = "AVISIT", selected = "AVISIT", fixed = TRUE),
      y = variables(
        choices  = c("AVAL", "CHG", "PCHG"),
        selected = "CHG",
        multiple = FALSE
      ),
      paramcd = picks(
        variables("PARAMCD", fixed = TRUE),
        values(choices = param_codes, selected = "ALT", multiple = FALSE),
        check_dataset = FALSE
      )
    )
  )
) |>
  modify_title("Early-Phase Clinical Reporting - CDISCPILOT01 (public example data)")

shinyApp(app$ui, app$server)
