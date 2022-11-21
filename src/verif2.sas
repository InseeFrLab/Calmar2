%MACRO VERIF2(MAR)/store;

%LOCAL NNUM;

  DATA _NULL_;
    SET &&&MAR (KEEP=N);
    ARRAY V _NUMERIC_;
    CALL SYMPUT('NNUM',LEFT(PUT(DIM(V),1.)));
  RUN;

  %IF &SYSERR=0 AND &NNUM=0 %THEN
  %DO;
    %LET ER=1;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
      PUT @2 "***   ERREUR : LA VARIABLE N FIGURANT DANS LA"      @73 "***";
      PUT @2 "***            TABLE %UPCASE(&&&MAR)"                @73 "***";
      PUT @2 "***            SPECIFIEE DANS LE PARAMETRE &MAR"    @73 "***";
      PUT @2 "***            N'EST PAS NUMÉRIQUE"                 @73 "***";
      PUT @2 74*"*";
  %END;
%MEND VERIF2;
