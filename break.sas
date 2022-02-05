options nocenter mprint symbolgen compress=binary fullstimer
        mstored sasmstore=macin source2;

%SYSMSTORECLEAR;
libname macin '/compiled_MACROS_directoru/' ;

%macro BREAK / store source des="New Tab in xlsx file";
ods EXCEL options(sheet_interval="output");
ods exclude all;
data _null;
  declare odsout obj();
run;
ods select all;
%mend;

proc catalog catalog=macin.sasmacr;
  contents;
run;
