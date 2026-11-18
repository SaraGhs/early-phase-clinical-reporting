# ------------------------------------------------------------------
# Program:  00_explore.R
# Purpose:  Explore CDISC pilot SDTM domains (DM, EX, AE, LB, VS)
#           before ADaM derivation
# Input:    pharmaversesdtm package (public example data)
# Author:   Sara Gharouni Saffar
# ------------------------------------------------------------------

library(dplyr)
library(pharmaversesdtm)

dm <- pharmaversesdtm::dm
ex <- pharmaversesdtm::ex
ae <- pharmaversesdtm::ae
lb <- pharmaversesdtm::lb
vs <- pharmaversesdtm::vs

# 1. Dataset sizes (rows, columns)
sapply(list(DM = dm, EX = ex, AE = ae, LB = lb, VS = vs), dim)

# 2. Subjects: DM should have exactly one row per subject
nrow(dm)
n_distinct(dm$USUBJID)
dm %>% count(ARM, ACTARM)           # planned vs actual arm
n_distinct(ex$USUBJID)              # subjects who actually received a dose

# 3. Referential integrity: every subject in other domains exists in DM
setdiff(unique(ae$USUBJID), dm$USUBJID)
setdiff(unique(lb$USUBJID), dm$USUBJID)

# 4. Lab tests
lb %>% count(LBCAT)
n_distinct(lb$LBTESTCD)
lb %>% count(LBTESTCD, LBTEST, sort = TRUE) %>% head(10)
lb %>% count(VISITNUM, VISIT) %>% arrange(VISITNUM)

# 5. Adverse events
n_distinct(ae$USUBJID)              # subjects with at least one AE
ae %>% count(AEBODSYS, sort = TRUE) %>% head(10)
ae %>% count(AESEV)

# 6. Vital signs
vs %>% count(VSTESTCD, VSTEST)
