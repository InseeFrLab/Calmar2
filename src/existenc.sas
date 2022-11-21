   /******************************************************************
    ***  LA MACRO EXISTENC PERMET DE VERIFIER L'EXISTENCE          ***
    ***     D'UNE TABLE SAS &TABLE                                 ***
    ******************************************************************/

%MACRO EXISTENC(TAB)/store;
 %LOCAL PRESENCE;
 %LET PRESENCE= ;
 %IF &TAB NE %STR() %THEN
 %DO;
    %LET PRESENCE=%SYSFUNC(EXIST(&TAB));
    %IF &PRESENCE=0 %THEN
    %DO;
        %LET ER=1;
        DATA _NULL_ ;
             FILE PRINT;
             PUT @8 56*"*";
             PUT @8 "*** ERREUR : LA TABLE &TAB N'EXISTE PAS" @61 "***";
             PUT @8 56*"*";
    %END;
 %END;
%MEND EXISTENC;
