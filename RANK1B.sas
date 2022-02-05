options nocenter mprint symbolgen compress=binary /*fullstimer*/
        mstored sasmstore=macin source2 OBS=max
        ;

%let home=/a_directory;
LIBNAME HOME "&home.";

%SYSMSTORECLEAR;

libname macin '/home/jonasbilenas0/MACROS/' ;

ods EXCEL file="&home./RANK1B_OUTPUT.xlsx"
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
            sheet_name="RESULTS"
           );

PROC FORMAT;
  VALUE BADS
    610  = '0.130434783'
    630  = '0.230769231'
    650  = '0.375000000'
    670  = '0.545454545'
    690  = '0.705882353'
    710  = '0.827586207'
    730  = '0.905660000'
    750  = '0.950495050'
    770  = '0.974619289'
    790  = '0.987146530'
    810  = '0.993531695'
    830  = '0.996755354'
    850  = '0.998375041'
    OTHER= '.'
  ;
RUN;


DATA freqy;
  CALL STREAMINIT(20220130);
  DO I = 1 TO 1E6;
    SCORE=(ROUND(RAND("Normal")*30+740,1)<>610)><870;
    OUTPUT;
  END;
RUN;

PROC MEANS DATA=freqy n NWAY;
  CLASS SCORE;
  OUTPUT OUT=freqy2 N=N;
RUN;



DATA fmt (RENAME=(SCORE=START));
  RETAIN FMTNAME 'COUNT' TYPE 'N';
  SET freqy2 END=EOF;
  LABEL = N;
  OUTPUT;
  IF EOF THEN DO;
    HLO='O'; START=.; LABEL=0;    OUTPUT;
  END;
RUN;

PROC FORMAT CNTLIN=fmt;
run;

PROC FORMAT FMTLIB;
RUN;




DATA TEST;
  CALL STREAMINIT(20220128);
  DO SCORE = 610 TO 850 BY 20;
    DO OB = 1 TO 10000;
      RANDOM=RAND("UNIFORM");
      CUTOFF = INPUT(PUT(SCORE,BADS.),BEST10.);
      IF RANDOM > CUTOFF THEN EVENT=0;
      ELSE EVENT=1;
      OUTPUT;
    END;
  END;
  DROP OB CUTOFF RANDOM;
RUN;

PROC CONTENTS DATA = TEST NODETAILS; RUN;
PROC TABULATE DATA=TEST NOSEPS;
  CLASS SCORE;
  VAR EVENT;
  TABLE SCORE ALL
        ,
        EVENT*MEAN
        /RTS=20 ROW=float;
RUN;

PROC LOGISTIC DATA=test descending;
  MODEL EVENT = SCORE;
  STORE WORK.test_model;
RUN;

DATA LARGE;
  *CALL STREAMINIT(20220130);
  DO SCORE = 610 TO 870 BY 1;
    IF INPUT(PUT(SCORE,COUNT.),BEST.) >0 THEN DO;
      DO OB = 1 TO INPUT(PUT(SCORE,COUNT.),BEST.);
        OUTPUT;
      END;
    END;
  END;
  DROP OB;
RUN;

PROC PLM RESTORE=work.test_model;
  score data=large out=BIG  predicted  / ilink;
run;
QUIT;



PROC MEANS DATA=BIG NWAY MEAN NOPRINT;
  CLASS SCORE;
  VAR Predicted;
  OUTPUT OUT=BIG_EST MEAN=;
RUN;


DATA fmt (RENAME=(SCORE=START Predicted=LABEL));
  RETAIN FMTNAME 'BADSS' TYPE 'N';
  SET BIG_EST END=EOF;
  OUTPUT;
  IF EOF THEN DO;
    LABEL='.';    HLO='O'; OUTPUT;
  END;
RUN;

proc format cntlin=fmt;
run;

PROC FORMAT FMTLIB;
RUN;


DATA home.TEST;
  CALL STREAMINIT(20220129);
  SET large;
  RANDOM=RAND("UNIFORM");
  CUTOFF = INPUT(PUT(SCORE,BADSS.),BEST10.);
  IF RANDOM > CUTOFF THEN EVENT=0;
  ELSE EVENT=1;
  OUTPUT;
  DROP CUTOFF RANDOM;
 RUN;

PROC CONTENTS DATA=home.test NODETAILS; RUN;

PROC LOGISTIC DATA=home.TEST descending;
  MODEL EVENT = SCORE;
RUN;
%break;
ods excel close;

