   /******************************************************************
    ***  LA MACRO NOBS PERMET D'AFFECTER LE NOMBRE D'OBSERVATIONS  ***
    ***  D'UNE TABLE SAS &DATA � LA MACRO-VARIABLE &NOMVAR         ***
    ***  (� CONDITION QUE LE PARAM�TRE &DATA NE CONTIENNE PAS      ***
    ***   LES CONDITIONS FIRSTOBS, OBS OU WHERE)                   ***
    ******************************************************************/

%MACRO NOBS(TAB,NOMVAR)/store;
  %LOCAL T;
     %LET T=%SYSFUNC(OPEN(&TAB));
     %LET &NOMVAR=%CMPRES(%SYSFUNC(ATTRN(&T,NOBS)));
     %LET T=%SYSFUNC(CLOSE(&T));
%MEND NOBS;
