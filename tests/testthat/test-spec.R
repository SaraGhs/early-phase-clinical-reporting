test_that("spec meets SAS transport v5 limits", {
  expect_true(all(nchar(spec$variable) <= 8))
  expect_true(all(nchar(spec$label) <= 40))
  expect_false(any(duplicated(spec[c("dataset", "variable")])))
  expect_true(all(spec$type %in% c("character", "numeric")))
})
