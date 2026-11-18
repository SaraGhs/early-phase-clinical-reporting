test_that("ADAE has one row per SDTM AE record, all subjects in ADSL", {
  expect_equal(nrow(adae), nrow(pharmaversesdtm::ae))
  expect_false(any(duplicated(adae[c("USUBJID", "AESEQ")])))
  expect_true(all(adae$USUBJID %in% adsl$USUBJID))
})

test_that("ADAE columns match the spec, in order", {
  expect_identical(names(adae), spec_vars("ADAE"))
})

test_that("TRTEMFL follows the treatment-emergent window", {
  expect_true(all(adae$TRTEMFL %in% c("Y", NA)))
  before <- !is.na(adae$ASTDT) & !is.na(adae$TRTSDT) & adae$ASTDT < adae$TRTSDT
  after  <- !is.na(adae$ASTDT) & !is.na(adae$TRTEDT) & adae$ASTDT > adae$TRTEDT + 30
  expect_true(all(is.na(adae$TRTEMFL[before])))
  expect_true(all(is.na(adae$TRTEMFL[after])))
  # Reconciliation: every non-flagged AE is explained by one of the rules
  expect_equal(sum(is.na(adae$TRTEMFL)), sum(before | after))
})

test_that("study day has no day 0", {
  expect_false(any(adae$ASTDY == 0, na.rm = TRUE))
})

test_that("start dates are complete and imputation flags are valid", {
  expect_false(any(is.na(adae$ASTDT)))
  expect_true(all(adae$ASTDTF %in% c("D", "M", NA)))
})
