options nocenter mprint symbolgen compress=binary /*fullstimer*/
        mstored sasmstore=macin source2 OBS=max
        ;

%let home=/a_directory;
LIBNAME HOME "&home.";
%let var=score;
%SYSMSTORECLEAR;

LIBNAME macin '/MACROS_directory/' ;

PROC FORMAT;
  PICTURE PCT (ROUND) LOW-HIGH = '009.99%'
  ;
RUN;

ODS EXCEL file="&home./RANK2B_OUTPUT.xlsx"
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
ods EXCEL options(sheet_interval="none"
          sheet_name="CONTENTS"
           );

PROC CONTENTS DATA=HOME.TEST NODETAILS; RUN;

PROC RANK DATA = HOME.test
          OUT=binned
          GROUPS=20
          TIES=low;
  VAR score;
  RANKS score_r;
RUN;

PROC CONTENTS DATA = binned NODETAILS; RUN;

%break;
ods EXCEL options(sheet_interval="none"
          sheet_name="RESULTS"
           );
TITLE IV=&var.;
PROC TABULATE DATA=BINNED NOSEPS MISSING;
  CLASS score_r;
  VAR SCORE EVENT;
  TABLE score_r='Ranked Score' ALL
        ,
        N*f=comma12.
        pctn='%'*f=pct.
        SCORE*(MIN*f=3. MEAN*f=6.2 MAX*f=3. STD*F=8.2)
        EVENT='EVENT MEAN'*MEAN=' '*f=percent8.2
        /rts=20 row=float misstext=' ';
run;
TITLE;
PROC MEANS DATA = BINNED NWAY NOPRINT;
  CLASS score_r;
  VAR SCORE EVENT;
  OUTPUT OUT=plot_data
         MEAN(score) = score
         MEAN(EVENT) = EVENT
         ;
RUN;

DATA log_odds;
  SET plot_data;
  LOG_ODDS = LOG(EVENT/(1-EVENT));
RUN;

PROC PRINT DATA=log_odds;
  VAR SCORE LOG_ODDS;
RUN;

TITLE RANK and PLOT of IV=&var.;
PROC SGPLOT DATA=log_odds;
  SERIES X=SCORE Y=LOG_ODDS /
  LINEATTRS=(COLOR=BLUE) MARKERS
  MARKERATTRS=(symbol=CIRCLEFILLED  COLOR=RED SIZE=6);
  XAXIS GRID LABEL="BINED &var.";
  YAXIS GRID LABEL='LOG OF ODDS (EVENT/(1-EVENT))';
RUN;
TITLE;
%break;
ods EXCEL options(sheet_interval="none"
          sheet_name="LOGISTIC NO BANDWITH"
           );
PROC LOGISTIC DATA=home.TEST descending;
  MODEL EVENT = SCORE;
TITLE NO BINWIDTH;
RUN;
%break;

ods EXCEL options(sheet_interval="none"
          sheet_name="BANDWITH=0.002"
           );
PROC LOGISTIC DATA=home.TEST descending;
  MODEL EVENT = SCORE/BINWIDTH=0.002;
  TITLE BINWIDTH=0.002;
RUN;
%break;

ods EXCEL options(sheet_interval="none"
          sheet_name="BANDWITH=0.05"
           );
PROC LOGISTIC DATA=home.TEST descending;
  MODEL EVENT = SCORE/BINWIDTH=0.05;
  TITLE BINWIDTH=0.05;
RUN;

%break;
ODS EXCEL CLOSE;
TITLE;


