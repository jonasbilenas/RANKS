options nocenter mprint symbolgen compress=binary /*fullstimer*/
        mstored sasmstore=macin source2 SPOOL OBS=max
        ;

%let home=/home/;
LIBNAME HOME "&home.";

%SYSMSTORECLEAR;

LIBNAME macin '/MACROS/' ;

PROC FORMAT;
  PICTURE PCT (ROUND) LOW-HIGH = '009.99%'
  ;
RUN;

ODS EXCEL file="&home./RANK3C_OUTPUT.xlsx"
          style=SASWEB
          OPTIONS (fittopage = 'yes'
                   frozen_headers='no'
                   autofilter='none'
                   embedded_titles = 'YES'
                   embedded_footnotes = 'YES'
                   zoom = '100'
                   orientation='Landscape'
                   Pages_FitHeight = '100'
                   center_horizontal = 'no'
                   center_vertical = 'no'
              );
ODS EXCEL options(sheet_interval="none"
          sheet_name="SAMPLE"
           );


PROC SORT DATA=HOME.test OUT=data_sort
          NOEQUALS TAGSORT FORCE;
  BY EVENT;
RUN;

PROC SURVEYSELECT DATA=data_sort
      METHOD=SRS
      RATE = (1 0.10)
      OUT  = sample
      SEED = 20220203;
  STRATA EVENT;
RUN;

PROC CONTENTS DATA=sample NODETAILS;
RUN;
%break;

ODS EXCEL options(sheet_interval="none"
          sheet_name="FREQ"
           );

PROC FREQ DATA=sample;
  TABLE EVENT / MISSING;
RUN;
%break;

ODS EXCEL options(sheet_interval="none"
          sheet_name="UNI OUTPUT"
           );

%MACRO UNI_SPLITS(ds,var,weight,bins);
%LET first = %SYSEVALF(100/&bins.);
%LET splits = %STR(OUTPUT OUT=P PCTLPRE=P_ PCTLPTS=&first TO 100  BY &first.);

PROC UNIVARIATE DATA=&ds. NOPRINT;
  VAR &var.;
  &splits.;
  WEIGHT &weight.;
run;

PROC PRINT DATA=P;
RUN;

PROC TRANSPOSE DATA=P OUT=pt;
RUN;

PROC SORT DATA=pt(KEEP=COL1) NODUPKEY
          OUT=PT2 NOEQUALS FORCE;
  BY COL1;
RUN;

*proc print data=pt; run;
%break;

ODS EXCEL options(sheet_interval="none"
          sheet_name="More CNTS"
           );
PROC CONTENTS DATA=PT2 NODETAILS;
RUN;
%break;

ODS EXCEL options(sheet_interval="none"
          sheet_name="FORMAT"
           );
DATA cntlin;
  SET PT2 END=eof;
  LENGTH HLO SEXCL EEXCL $1 LABEL $3;
  RETAIN FMTNAME "IV" TYPE 'N' END;
  nrec ++1;
  IF nrec=1 THEN DO;
    HLO='L'; SEXCL='N'; EEXCL='N';  START=.; END=COL1; LABEL=put(nrec-1,z3.); OUTPUT;
  END;
  ELSE IF NOT eof THEN DO;
    HLO=' '; SEXCL='Y'; EEXCL='N'; START=end; END=COL1; LABEL=PUT(nrec-1,z3.); OUTPUT;
  END;
  ELSE IF eof THEN DO;
    HLO='H'; SEXCL='Y'; EEXCL='N'; START=end; END=.; LABEL=PUT(nrec-1,z3.); OUTPUT;
  END;
RUN;

PROC FORMAT CNTLIN=CNTLIN FMTLIB;
     SELECT IV;
run;
%break;

ODS EXCEL options(sheet_interval="none"
          sheet_name="STATS"
           );
DATA &ds.;
  SET &ds;
  score_r = INPUT(PUT(&var.,IV.),BEST.);
  NOA=1;
run;

TITLE SAMPLED DATA IV=&var.;

PROC TABULATE DATA=&ds. NOSEPS MISSING;
  CLASS score_r;
  VAR SCORE EVENT NOA;
  WEIGHT &weight.;
  TABLE score_r='Ranked Score' ALL
        ,
        N*f=comma12.
        pctn='%'*f=pct.
        NOA='Weighted Accounts'*f=COMMA12.2
        SCORE*(MIN*f=3. MEAN*f=6.2 MAX*f=3. STD*f=8.2)
        EVENT='EVENT MEAN'*MEAN=' '*f=PERCENT8.2
        /RTS=20 ROW=FLOAT MISSTEXT=' ';
run;

PROC MEANS DATA = &ds. NWAY NOPRINT;
  CLASS score_r;
  VAR SCORE EVENT;
  WEIGHT &weight.;
  OUTPUT OUT=plot_data
         MEAN(score) = score
         MEAN(EVENT) = EVENT
         ;
RUN;

DATA log_odds;
  SET plot_data;
  LOG_ODDS = LOG(EVENT/(1-EVENT));
RUN;
TITLE;
PROC PRINT DATA=log_odds;
  VAR SCORE LOG_ODDS;
RUN;

TITLE RANK AND PLOT;
TITLE2 SAMPLED DATA IV=&var.;
PROC SGPLOT DATA=log_odds;
  SERIES X=SCORE Y=LOG_ODDS /
  LINEATTRS=(COLOR=BLUE) MARKERS
  MARKERATTRS=(symbol=CIRCLEFILLED  COLOR=RED SIZE=6);
  XAXIS GRID LABEL="BINED &var.";
  YAXIS GRID LABEL='LOG OF ODDS (EVENT/(1-EVENT))';
RUN;
%break;
%MEND;

%UNI_SPLITS(ds=sample,var=score,weight=SamplingWeight,bins=20) ;
ODS EXCEL CLOSE;

