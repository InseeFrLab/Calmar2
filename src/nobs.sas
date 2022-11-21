   /******************************************************************
    ***  LA MACRO NOBS PERMET D'AFFECTER LE NOMBRE D'OBSERVATIONS  ***
    ***  D'UNE TABLE SAS &DATA À LA MACRO-VARIABLE &NOMVAR         ***
    ***  (À CONDITION QUE LE PARAMÈTRE &DATA NE CONTIENNE PAS      ***
    ***   LES CONDITIONS FIRSTOBS, OBS OU WHERE)                   ***
    ******************************************************************/

%MACRO NOBS(TAB,NOMVAR)/store;
  %LOCAL T;
     %LET T=%SYSFUNC(OPEN(&TAB));
     %LET &NOMVAR=%CMPRES(%SYSFUNC(ATTRN(&T,NOBS)));
     %LET T=%SYSFUNC(CLOSE(&T));
%MEND NOBS;
