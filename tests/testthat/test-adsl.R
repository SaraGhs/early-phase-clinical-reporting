test_that("ADSL has one row per subject in DM", {
  expect_equal(nrow(adsl), nrow(pharmaversesdtm::dm))
  expect_false(anyDuplicated(adsl$USUBJID) > 0)
})

test_that("ADSL columns match the spec, in order", {
  expect_identical(names(adsl), spec_vars("ADSL"))
})

test_that("population flags are Y/N and match their definitions", {
  expect_true(all(adsl$ITTFL %in% c("Y", "N")))
  expect_true(all(adsl$SAFFL %in% c("Y", "N")))
  expect_identical(adsl$SAFFL == "Y", !is.na(adsl$TRTSDT))
  expect_identical(adsl$ITTFL == "Y", adsl$ARM != "Screen Failure")
})

test_that("screen failures have no treatment", {
  sf <- adsl$ARM == "Screen Failure"
  expect_true(all(is.na(adsl$TRT01P[sf])))
  expect_true(all(is.na(adsl$TRT01A[sf])))
  expect_true(all(is.na(adsl$TRTSDT[sf])))
})

test_that("treatment dates and duration are consistent", {
  ok <- !is.na(adsl$TRTSDT) & !is.na(adsl$TRTEDT)
  expect_true(all(adsl$TRTSDT[ok] <= adsl$TRTEDT[ok]))
  expect_equal(adsl$TRTDURD[ok],
               as.numeric(adsl$TRTEDT[ok] - adsl$TRTSDT[ok]) + 1)
})

test_that("AGEGR1 boundaries follow the spec", {
  expect_true(all(adsl$AGEGR1[adsl$AGE < 65] == "<65"))
  expect_true(all(adsl$AGEGR1[adsl$AGE >= 65 & adsl$AGE <= 80] == "65-80"))
  expect_true(all(adsl$AGEGR1[adsl$AGE > 80] == ">80"))
})

test_that("DI-001: known subjects keep missing TRTEDT and stay in safety population", {
  di <- adsl[adsl$USUBJID %in% c("01-705-1018", "01-705-1382"), ]
  expect_equal(nrow(di), 2)
  expect_true(all(di$SAFFL == "Y"))
  expect_true(all(is.na(di$TRTEDT)))
})
