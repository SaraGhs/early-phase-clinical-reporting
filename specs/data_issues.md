# Data Issues Log

| ID | Domain | Subjects | Issue | Handling | Impact |
|---|---|---|---|---|---|
| DI-001 | EX | 01-705-1018, 01-705-1382 | Single EX record with missing EXENDTC; last dose date unknown | TRTEDT/TRTEDTM and TRTDURD left missing (no imputation). In a live study a data query would be raised to the site. | TRTEMFL applies no upper window when TRTEDT is missing, so AEs on or after TRTSDT are flagged treatment-emergent. |
