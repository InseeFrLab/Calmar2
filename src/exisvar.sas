   /******************************************************************
    ***  LA MACRO EXISVAR PERMET DE VERIFIER L'EXISTENCE           ***
    ***  DE LA VARIABLE &V DANS LA TABLE SAS &TAB                  ***
    ******************************************************************/

%MACRO EXISVAR(TAB,V)/ store;
 %LOCAL NUMV T;
 %LET NUMV= ;
 %LET T=%SYSFUNC(OPEN(&&&TAB));
 %LET NUMV=%SYSFUNC(VARNUM(&T,&V));
 %IF &NUMV=0 %THEN
 %DO;
     %LET ER=1;
     DATA _NULL_;
      FILE PRINT;
        PUT //@2 74*"*";
        PUT @2 "***   ERREUR : LA VARIABLE &V NE FIGURE PAS"       @73 "***";
        PUT @2 "***            DANS LA TABLE %UPCASE(&&&TAB)"      @73 "***";
        PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE &TAB"   @73 "***";
        PUT @2 74*"*";
 %END;
 %LET T=%SYSFUNC(CLOSE(&T));
%MEND EXISVAR;
