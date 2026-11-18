# QC Log

Method: independent double programming. QC programs (`qc/`) were written in
base R from the derivation text in `specs/adam_spec.csv`, without admiral or
dplyr, and compared with production datasets using `diffdf`.
QC ADAE uses QC ADSL treatment dates (independent chain).

## Scope

| Dataset | Variables compared | Records | Key |
|---|---|---|---|
| ADSL | TRT01P, TRT01A, TRTSDT, TRTEDT, TRTDURD, AGEGR1, ITTFL, SAFFL | 306 | USUBJID |
| ADAE | TRTA, ASTDT, ASTDTF, ASTDY, TRTEMFL | 1,191 | USUBJID, AESEQ |

## Findings

| ID | Run | Dataset | Finding | Resolution |
|---|---|---|---|---|
| QC-001 | 1 | ADSL, ADAE | Attribute difference only: SDTM variable labels retained on USUBJID/AESEQ in production, dropped by base R `merge()` in QC. No value differences. | Labels removed from both sides before comparison. Labels are verified separately against the spec by xportr (Step 5, 0 label mismatches). |

## Final result (run 2)

| Dataset | diffdf result |
|---|---|
| ADSL | No issues found |
| ADAE | No issues found |

Zero unresolved discrepancies.
