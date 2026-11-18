# Data Issues Log

| ID | Domain | Subjects | Issue | Handling | Impact |
|---|---|---|---|---|---|
| DI-001 | EX | 01-705-1018, 01-705-1382 | Single EX record with missing EXENDTC; last dose date unknown | TRTEDT/TRTEDTM and TRTDURD left missing (no imputation). In a live study a data query would be raised to the site. | No AE records exist for either subject, so TRTEMFL is unaffected in this study; the missing-TRTEDT rule is retained as a safeguard. |
| DI-002 | LB | 8 records (HBA1C) | LBCAT missing for Hemoglobin A1C | PARCAT1 left missing per spec (PARCAT1 = LB.LBCAT); not re-categorized without a source | HbA1c excluded from category-based summaries; other parameters unaffected |
