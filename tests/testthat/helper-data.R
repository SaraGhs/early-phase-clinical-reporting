# Loaded automatically by testthat before the test files run.
# Finds the project root from any working directory (local or CI).
root <- rprojroot::find_root(rprojroot::has_file("renv.lock"))

read_ds <- function(name) {
  readRDS(file.path(root, "outputs", "datasets", paste0(name, ".rds")))
}

spec <- read.csv(file.path(root, "specs", "adam_spec.csv"), stringsAsFactors = FALSE)
spec_vars <- function(ds) {
  s <- spec[spec$dataset == ds, ]
  s$variable[order(s$order)]
}

adsl <- read_ds("adsl")
adae <- read_ds("adae")
adlb <- read_ds("adlb")
