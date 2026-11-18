/*-------------------------------------------------------------------
 Program:  qc_adsl.sas
 Purpose:  Independent SAS QC of ADSL derived variables;
           PROC COMPARE against production ADSL built in R
 Input:    dm.xpt, ex.xpt (SDTM), adsl.xpt (R production ADSL)
 Author:   Sara Gharouni Saffar
-------------------------------------------------------------------*/
%let path = /home/u64652320/ecr;   /* <-- replace with your folder Location */
/* Save evidence files into the ecr folder */
proc printto log="&path/qc_adsl_sas.log" new; run;
ods html5 (id=evidence) path="&path" file="qc_adsl_sas_results.html";

libname xdm   xport "&path/dm.xpt";
libname xex   xport "&path/ex.xpt";
libname xadsl xport "&path/adsl.xpt";

proc copy in=xdm   out=work; run;
proc copy in=xex   out=work; run;
proc copy in=xadsl out=work; run;   /* production ADSL -> WORK.ADSL */

/* Valid doses: EXDOSE > 0, or EXDOSE = 0 and EXTRT contains PLACEBO */
data ex_v;
  set ex;
  if EXDOSE > 0 or (EXDOSE = 0 and index(upcase(EXTRT), 'PLACEBO') > 0);
  if length(strip(EXSTDTC)) >= 10 then stdt = input(substr(EXSTDTC, 1, 10), yymmdd10.);
  if length(strip(EXENDTC)) >= 10 then endt = input(substr(EXENDTC, 1, 10), yymmdd10.);
  format stdt endt date9.;
run;

/* First and last valid dose date per subject */
proc sql;
  create table trt as
  select USUBJID,
         min(stdt) as TRTSDT format=date9.,
         max(endt) as TRTEDT format=date9.
  from ex_v
  group by USUBJID
  order by USUBJID;
quit;

proc sort data=dm; by USUBJID; run;

/* Subject-level derivations, from the spec text */
data qc_adsl;
  merge dm(in=a keep=USUBJID ARM ACTARM AGE) trt;
  by USUBJID;
  if a;
  length TRT01P TRT01A $40 AGEGR1 $10 ITTFL SAFFL $1;
  if ARM    ne 'Screen Failure' then TRT01P = ARM;
  if ACTARM ne 'Screen Failure' then TRT01A = ACTARM;
  if n(TRTSDT, TRTEDT) = 2 then TRTDURD = TRTEDT - TRTSDT + 1;
  if      AGE < 65  then AGEGR1 = '<65';
  else if AGE <= 80 then AGEGR1 = '65-80';
  else                   AGEGR1 = '>80';
  ITTFL = ifc(ARM ne 'Screen Failure', 'Y', 'N');
  SAFFL = ifc(not missing(TRTSDT), 'Y', 'N');
  keep USUBJID TRT01P TRT01A TRTSDT TRTEDT TRTDURD AGEGR1 ITTFL SAFFL;
run;

/* Counts */
title "SAS QC: populations";
proc freq data=qc_adsl; tables ITTFL*SAFFL / list missing; run;

title "SAS QC: actual treatment, safety population";
proc freq data=qc_adsl; where SAFFL = 'Y'; tables TRT01A / missing; run;

title "SAS QC: age groups";
proc freq data=qc_adsl; tables AGEGR1 / missing; run;

title "SAS QC: treatment duration (days)";
proc means data=qc_adsl n nmiss min mean median max; var TRTDURD; run;

/* Value-level comparison with the R production ADSL */
proc sort data=adsl
  out=prod(keep=USUBJID TRT01P TRT01A TRTSDT TRTEDT TRTDURD AGEGR1 ITTFL SAFFL);
  by USUBJID;
run;
proc sort data=qc_adsl; by USUBJID; run;

title "PROC COMPARE: R production ADSL (BASE) vs SAS QC ADSL (COMPARE)";
proc compare base=prod compare=qc_adsl listall criterion=1e-8;
  id USUBJID;
run;
title;
ods html5 (id=evidence) close;
proc printto; run;