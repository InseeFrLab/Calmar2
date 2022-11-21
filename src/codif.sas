************                                                                  ************;
*****   RECODIFICATION DES VARIABLES QUALITATIVES DANS LE(S) FICHIER(S) D'ENQUÊTE ********;
************                                                                  ************;

%MACRO CODIF(TABIN= ,
             TABOUT= ,
             XV= ,
             XM= )/store;

%LOCAL FIN NC NCZ ZV ZM MAR MAXMOD I J lnmod;

%LET ERMOD=0;

%IF &TABIN=&DATAMEN %THEN %DO;
    %LET FIN=MEN;
    %LET NC=%EVAL(&CAT1);
    %LET NCZ=%EVAL(&CATZ1);
    %LET ZV =ZM;
    %LET ZM =MZM;
    %LET MAR=&MARMEN;
    %LET MAXMOD=%EVAL(&NMAX1);
%END;
%ELSE %IF &TABIN=&DATAIND %THEN %DO;
      %LET FIN=IND;
      %LET NC=%EVAL(&CAT2);
      %LET NCZ=%EVAL(&CATZ2);
      %LET ZV =ZI;
      %LET ZM =MZI;
      %LET MAR=&MARIND;
      %LET MAXMOD=%EVAL(&NMAX2);
%END;
%ELSE %IF &TABIN=&DATAKISH %THEN %DO;
    %LET FIN=KIS;
    %LET NC=%EVAL(&CAT3);
    %LET NCZ=%EVAL(&CATZ3);
    %LET ZV =ZK;
    %LET ZM =MZK;
    %LET MAR=&MARKISH;
    %LET MAXMOD=%EVAL(&NMAX3);
%END;

PROC FREQ DATA=&TABIN ;
     %DO I=1 %TO &NC;
         TABLES &&&XV.&I/NOPRINT OUT=LIST&I(KEEP=&&&XV&I COUNT
                                               %IF &PCT=OUI %THEN %DO; PERCENT %END; );;
     %END;
     %IF &NCZ>0 %THEN
     %DO I=1 %TO &NCZ;
         TABLES &&&ZV.&I/NOPRINT OUT=LZ&I(KEEP=&&&ZV&I COUNT
                                               %IF &PCT=OUI %THEN %DO; PERCENT %END; );
     %END;
RUN;

%DO I=1 %TO &NC;
 %LOCAL MOD&I;
 DATA LIST&I;
      SET LIST&I;
      IF COMPRESS(PUT(&&&XV.&I,32.)) NOT IN (' ','.');   /* <-- correction du 31/07/2009 */
 RUN;
 %NOBSS(LIST&I,MOD&I)
 RUN;
 %IF &&MOD&I NE &&&XM.&I %THEN
 %DO;
   %LET ERMOD=1;
   %IF &&MOD&I NE 0 %THEN
   %DO;
      PROC PRINT DATA=LIST&I LABEL SPLIT='!';
        TITLE4 "** ERREUR : LA VARIABLE %CMPRES(&&&XV.&I) A %CMPRES(&&MOD&I) MODALITÉS"
               " DANS LA TABLE %CMPRES(&TABIN) **";
        TITLE5 "** MAIS EST DÉCLARÉE AVEC %CMPRES(&&&XM.&I) MODALITÉS DANS LA TABLE"
               " DES MARGES **";
        TITLE7 "LISTE DES MODALITÉS DE LA VARIABLE %CMPRES(&&&XV.&I) DANS LA TABLE"
               " DE DONNÉES";
        LABEL COUNT='EFFECTIF!ECHANTILLON!NON PONDÉRÉ'
             %IF &PCT=OUI %THEN %DO;
              PERCENT='%!ECHANTILLON!NON PONDÉRÉ' 
             %END; ;
      RUN;
   %END;
   %ELSE %IF &&MOD&I=0 %THEN
   %DO;
      DATA _NULL_;
	     FILE PRINT;
		 PUT   @2 "** ERREUR : LA VARIABLE %CMPRES(&&&XV.&I) A %CMPRES(&&MOD&I) MODALITÉS"
                  " DANS LA TABLE %CMPRES(&TABIN) **";
         PUT / @2 "** MAIS EST DÉCLARÉE AVEC %CMPRES(&&&XM.&I) MODALITÉS DANS LA TABLE"
                  " DES MARGES **";
      RUN;
   %END;
 %END;
%END;

%IF &NCZ>0 %THEN
%DO I=1%TO &NCZ;
 %LOCAL MODZ&I;
 DATA LZ&I;
      SET LZ&I;
      IF COMPRESS(PUT(&&&ZV.&I,32.)) NOT IN (' ','.');
 RUN;
 %NOBSS(LZ&I,MODZ&I)
 RUN;
 %IF &&MODZ&I NE &&&ZM.&I %THEN
 %DO;
   %LET ERMOD=1;
   %IF &&MODZ&I NE 0 %THEN
   %DO;
      PROC PRINT DATA=LZ&I LABEL SPLIT='!';
        TITLE4 "** ERREUR : LA VARIABLE %CMPRES(&&&ZV.&I) A %CMPRES(&&MODZ&I) MODALITÉS"
               " DANS LA TABLE %CMPRES(&TABIN) **";
        TITLE5 "** MAIS EST DÉCLARÉE AVEC %CMPRES(&&&ZM.&I) MODALITÉS DANS LA TABLE"
               " DES MARGES **";
        TITLE7 "LISTE DES MODALITÉS DE LA VARIABLE %CMPRES(&&&ZV.&I) DANS LA TABLE"
               " DE DONNÉES";
        LABEL COUNT='EFFECTIF!ECHANTILLON!NON PONDÉRÉ'
             %IF &PCT=OUI %THEN %DO; 
              PERCENT='%!ECHANTILLON!NON PONDÉRÉ' 
             %END; ;
      RUN;
    %END;
   %ELSE %IF &&MODZ&I=0 %THEN
   %DO;
      DATA _NULL_;
	     FILE PRINT;
		 PUT   @2 "** ERREUR : LA VARIABLE %CMPRES(&&&ZV.&I) A %CMPRES(&&MODZ&I) MODALITÉS"
                  " DANS LA TABLE %CMPRES(&TABIN) **";
         PUT / @2 "** MAIS EST DÉCLARÉE AVEC %CMPRES(&&&ZM.&I) MODALITÉS DANS LA TABLE"
                  " DES MARGES **";
      RUN;
   %END;
 %END;
%END;

%IF &ERMOD=1 %THEN
%DO;
   PROC PRINT DATA=&MAR (WHERE=(N NE 0));
       TITLE4 "TABLE DES MARGES : &MAR";
   RUN;
  %GOTO AARRET;
%END;

%DO I=1 %TO &NC;
 %let lnmod=%length(&&&XM.&I);               /* <-- !! correction du 18/05/2010 */
 DATA LIST&I;
      LENGTH  VAR $32 MODALITE MODAL0 $8 __X 3;
      SET LIST&I (KEEP=&&&XV&I);
          VAR=UPCASE("&&&XV&I");
          MODAL0=&&&XV&I;
          __X+1;
          MODALITE=PUT(__X,z&lnmod..);       /* <-- !! correction du 18/05/2010 */
          MACV=COMPRESS("O&I"!!"_"!!__X);
          MACM=COMPRESS("S&I"!!"_"!!__X);
          CALL SYMPUT (MACV,MODAL0);
          CALL SYMPUT (MACM,MODALITE);
  RUN;
%END;

%IF &NCZ>0 %THEN
%DO I=1 %TO &NCZ;
 %let lnmod=%length(&&&ZM.&I);                /* <-- !! correction du 18/05/2010 */
 DATA LZ&I;
      LENGTH  VAR $32 MODALITE MODAL0 $8 __X 3;
      SET LZ&I (KEEP=&&&ZV&I);
          VAR=UPCASE("&&&ZV&I");
          MODAL0=&&&ZV&I;
          __X+1;
          MODALITE=PUT(__X,z&lnmod..);         /* <-- !! correction du 18/05/2010 */
          MACV=COMPRESS("OZ&I"!!"_"!!__X);
          MACM=COMPRESS("SZ&I"!!"_"!!__X);
          CALL SYMPUT (MACV,MODAL0);
          CALL SYMPUT (MACM,MODALITE);
  RUN;
%END;
DATA &TABOUT ;
     SET &TABIN (RENAME=(%DO I=1 %TO &NC; &&&XV&I = _V&I %END;
                         %IF &NCZ>0 %THEN %DO I=1 %TO &NCZ;
                            &&&ZV&I=_Z&I %END;));
     %DO I=1 %TO &NC;
      %DO J=1 %TO &&&XM&I;
          IF PUT(_V&I,8.)="&&&O&I._&J" THEN
             &&&XV&I="&&&S&I._&J";
      %END;
     %END;
    %IF &NCZ>0 %THEN
     %DO I=1 %TO &NCZ;
      %DO J=1 %TO &&&ZM&I;
          IF PUT(_Z&I,8.)="&&&OZ&I._&J" THEN
             &&&ZV&I="&&&SZ&I._&J";
      %END;
     %END;
DATA __COD&FIN (KEEP=VAR MODAL0 MODALITE);
      SET %DO I=1 %TO &NC;
           LIST&I
          %END;;
PROC SORT DATA=__COD&FIN;
     BY VAR MODALITE;

%AARRET :

PROC DATASETS DDNAME=WORK NOLIST;
     DELETE %DO I=1 %TO &NC;
                LIST&I
            %END;
            %DO I=1 %TO &NCZ;
                LZ&I
            %END;  ;
QUIT;

%MEND CODIF;
