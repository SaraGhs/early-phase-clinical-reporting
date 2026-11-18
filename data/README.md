# Data source

This project uses **public example data** from the R package `pharmaversesdtm`
(version 1.5.0), which contains SDTM datasets from the CDISC pilot study
(STUDYID: "CDISCPILOT01"), a clinical trial of xanomeline transdermal patch
vs placebo.

- No real patient data and no confidential data are used.
- Data is loaded directly from the package; no raw files are stored in this repo.

## Domains used
| Domain | Description        | Rows   | Subjects |
|--------|--------------------|-------:|---------:|
| DM     | Demographics       | 306    | 306      |
| EX     | Exposure           | 591    | 254      |
| AE     | Adverse events     | 1,191  | 225      |
| LB     | Laboratory results | 59,580 | <<LB>>   |
| VS     | Vital signs        | 29,643 | <<VS>>   |

## Key observations from exploration (`programs/00_explore.R`)

- **306 subjects** in DM (one row per subject); **52 screen failures**, leaving
  **254 dosed subjects**: Placebo (86), Xanomeline Low Dose (84),
  Xanomeline High Dose (84 planned).
- **12 subjects** randomized to High Dose received Low Dose (ARM ≠ ACTARM),
  so planned and actual treatment variables are derived separately in ADSL.
- All AE and LB subjects exist in DM (referential integrity check passed).
- LB contains **47 lab tests** across chemistry, hematology, urinalysis and other
  categories. Only 12 lab records fall at the visit labelled BASELINE; most
  pre-treatment labs are at SCREENING, so baseline is derived as the last
  non-missing value on or before first dose, not by visit name.
- AE: 225 subjects with at least one adverse event; most frequent body systems
  are General disorders/administration site conditions and Skin disorders,
  consistent with a transdermal product.
