test_that("ADLB has one row per SDTM LB record", {
  expect_equal(nrow(adlb), nrow(pharmaversesdtm::lb))
  expect_false(any(duplicated(adlb[c("USUBJID", "LBSEQ")])))
})

test_that("ADLB columns match the spec, in order", {
  expect_identical(names(adlb), spec_vars("ADLB"))
})

test_that("one baseline per subject and parameter, on or before first dose", {
  bl <- adlb[adlb$ABLFL %in% "Y", ]
  expect_false(any(duplicated(bl[c("USUBJID", "PARAMCD")])))
  expect_true(all(bl$ADY <= 1))          # day 1 = first dose day
  expect_equal(length(unique(bl$USUBJID)), sum(adsl$SAFFL == "Y"))
})

test_that("change from baseline is correct and post-baseline only", {
  post <- !is.na(adlb$CHG)
  expect_equal(adlb$CHG[post], adlb$AVAL[post] - adlb$BASE[post])
  expect_true(all(adlb$ADY[post] > 1))
  expect_true(all(is.na(adlb$CHG[adlb$ABLFL %in% "Y"])))
  p <- !is.na(adlb$PCHG)
  expect_equal(adlb$PCHG[p], (adlb$AVAL[p] - adlb$BASE[p]) / adlb$BASE[p] * 100)
  expect_false(any(adlb$BASE[p] == 0))
})

test_that("range indicators and analysis visits are valid", {
  expect_true(all(adlb$ANRIND %in% c("LOW", "NORMAL", "HIGH", NA)))
  expect_true(all(adlb$AVISIT[adlb$AVISITN %in% 0] == "Baseline"))
  expect_identical(adlb$ABLFL %in% "Y", adlb$AVISITN %in% 0)
})
