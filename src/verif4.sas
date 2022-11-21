%MACRO VERIF4(MAR)/store;

%LOCAL MARNUM MARCAR MAX;

       %IF &MAR=MARMEN  %THEN %LET MAX=%EVAL(&NMAX1);
 %ELSE %IF &MAR=MARIND  %THEN %LET MAX=%EVAL(&NMAX2);
 %ELSE %IF &MAR=MARKISH %THEN %LET MAX=%EVAL(&NMAX3);

  DATA __MAR ;
    SET &&&MAR %IF %UPCASE(&NONREP)=OUI %THEN %DO;(WHERE=(R NE 1)) %END; ;
  DATA _NULL_ ;
    SET __MAR (KEEP=MAR1-MAR&MAX);
    ARRAY V _NUMERIC_;
    CALL SYMPUT('MARNUM',LEFT(PUT(DIM(V),4.)));
  RUN;

  %IF &SYSERR NE 0 %THEN
  %DO;
    %LET ER=1;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
      PUT @2 "***   ERREUR : UNE (AU MOINS) DES VARIABLES MAR1 À MAR&MAX"
             " NE FIGURE PAS"                                         @73 "***";
      PUT @2 "***            DANS LA TABLE %UPCASE(&&&MAR)"            @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE &MAR"        @73 "***";
      PUT @2 "***            (&MAX EST LE NOMBRE MAXIMUM DE MODALITÉS SPÉCIFIÉ"
          @73 "***";
      PUT @2 "***             DANS CETTE TABLE)"  @73 "***";
      PUT @2 74*"*";

      PROC CONTENTS DATA=&&&MAR SHORT;
      TITLE4 "CONTENU DE LA TABLE %UPCASE(&&&MAR)";
  %END;

  %ELSE %IF &MARNUM NE &MAX %THEN
  %DO;
    %LET ER=1;
    %LET MARCAR=%EVAL(&MAX-&MARNUM);
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
      PUT @2 "***   ERREUR : PARMI LES VARIABLES MAR1 À MAR&MAX FIGURANT DANS"
          @73 "***";
      PUT @2 "***            LA TABLE %UPCASE(&&&MAR)"              @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE &MAR"      @73 "***";
      PUT @2 "***            &MARCAR NE SONT PAS NUMÉRIQUES"        @73 "***";
      PUT @2 74*"*";

      PROC CONTENTS DATA=&&&MAR;
      TITLE4 "CONTENU DE LA TABLE %UPCASE(&&&MAR)";
  %END;
%MEND VERIF4;
