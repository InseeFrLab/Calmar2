************                                                                ************;
*****            REMONTÉE AU NIVEAU MÉNAGES DES VARIABLES KISH                    ******;
*****               FUSION AVEC LA TABLE MÉNAGES INITIALE                         ******;
************                                                                ************;

%MACRO REMONTKI / store;

%LOCAL MEN BASE MKMAX KISHELI I ;

%IF (&TYP=4 AND &CAT1>0)      %THEN %LET MEN=&TABMEN ;
%ELSE %IF &TYP=4 AND &CAT1=0  %THEN %LET MEN=&DATAMEN;
%ELSE %IF &TYP=5                              %THEN %LET MEN=__MENAGE;

%IF %INDEX(&MEN,.) NE 0 %THEN %LET BASE=%SCAN(&MEN,1,.);
%ELSE                         %LET BASE=WORK;
PROC DATASETS DDNAME=&BASE NOLIST;
     MODIFY &MEN;
     INDEX CREATE &IDENT;
QUIT;


                              /* LA TABLE KISH CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */

%IF &CAT3>0  %THEN                          /* CONSTRUCTION DES VARIABLES INDICATRICES */
%DO;
 DATA __KISH (DROP=%DO I=1 %TO &CAT3; _V&I %END;)
      __KISELI (KEEP=&IDENT &IDENT2 &POIDKISH %DO I=1 %TO &CAT3; _V&I %END;
                            %IF &NUM3>0 %THEN %DO I=%EVAL(&CAT3+1) %TO &NVARK; &&K&I %END;
                            %IF &CATZ3>0 %THEN %DO I=1 %TO &CATZ3; _Z&I %END;
                            %IF &NUMZ3>0 %THEN %DO I=%EVAL(&CATZ3+1) %TO &NZK; &&ZK&I %END;);
      SET &TABKISH (KEEP=&IDENT &IDENT2 &POIDKISH %DO I=1 %TO &NVARK; &&K&I  %END;
	                     %DO I=1 %TO &CAT3; _V&I %END;
                         %IF &NZK>0 %THEN %DO ;
                             %DO I=1 %TO &NZK;   &&ZK&I %END;
                             %DO I=1 %TO &CATZ3; _Z&I %END;
                         %END;) ;

                                             /* VARIABLES DE CALAGE */
  %DO I=1 %TO &NVARK ;
     %IF &&MK&I=0 %THEN %DO;                           /* VARIABLES QUANTITATIVES KISH */
         K&I._1=&&K&I * &POIDKISH;
     %END;
     %ELSE %DO;
      ARRAY V&I(&&MK&I) K&I._1-K&I._&&MK&I;            /* VARIABLES QUALITATIVES KISH  */
         DO J=1 TO &&MK&I;
            IF &&K&I=J OR &&K&I=COMPRESS('0'!!J)
               OR &&K&I=COMPRESS('00'!!J)
            THEN V&I(J)=&POIDKISH;
            ELSE IF &&K&I=' ' THEN V&I(J)=. ;
            ELSE V&I(J)=0;
         END;
     %END;
  %END;

  %IF &NZK>0 %THEN                            /* VARIABLES DE NON-RÉPONSE */
  %DO I=1 %TO &NZK ;
     %IF &&MZK&I=0 %THEN %DO;                           /* VARIABLES QUANTITATIVES KISH */
         ZK&I._1=&&ZK&I * &POIDKISH;
     %END;

     %ELSE %DO;
      ARRAY VZ&I(&&MZK&I) ZK&I._1-ZK&I._&&MZK&I;         /* VARIABLES QUALITATIVES KISH  */
         DO J=1 TO &&MZK&I;
            IF &&ZK&I=J OR &&ZK&I=COMPRESS('0'!!J)
               OR &&ZK&I=COMPRESS('00'!!J)
            THEN VZ&I(J)=&POIDKISH;
            ELSE IF &&ZK&I=' ' THEN VZ&I(J)=. ;
            ELSE VZ&I(J)=0;
         END;
     %END;
  %END;
                                              /* REPÉRAGE DES VALEURS MANQUANTES */

    IF &IDENT=' ' OR &POIDKISH<=0 OR &POIDKISH=.
 %DO I=1 %TO &CAT3;
   OR &&K&I=' '
 %END;
 %IF &NUM3>0 %THEN 
 %DO I=%EVAL(&CAT3+1) %TO &NVARK;
   OR &&K&I=.
 %END;
 %IF &CATZ3>0 %THEN
 %DO I=1 %TO &CATZ3;
   OR &&ZK&I=' '
 %END;
 %IF &NUMZ3>0 %THEN 
 %DO I=%EVAL(&CATZ3+1) %TO &NZK;
   OR &&ZK&I=.
 %END;
 THEN
 DO;
     ELIMK=1;
     OUTPUT __KISELI;
  END;
  ELSE ELIMK=0;
  OUTPUT __KISH;
  RUN;

  %NOBSS(__KISELI,KISHELI)
  RUN;

  %IF &NKISH=1 %THEN %GOTO E1;

  %ELSE %IF &NKISH>1 %THEN
  %DO;
   PROC SUMMARY DATA=__KISH NWAY;                               /* SOMMATION PAR MÉNAGE */
        CLASS &IDENT  ;
        VAR &POIDKISH ELIMK
        %DO I=1 %TO &NVARK ;
            %IF &&MK&I=0 %THEN %LET MKMAX=1;
            %ELSE              %LET MKMAX=&&MK&I;
            K&I._1-K&I._&MKMAX
        %END;
        %IF &NZK>0 %THEN
        %DO I=1 %TO &NZK ;
            %IF &&MZK&I=0 %THEN %LET MKMAX=1;
            %ELSE               %LET MKMAX=&&MZK&I;
            ZK&I._1-ZK&I._&MKMAX
        %END;
           ;
       OUTPUT OUT=__SOMME(DROP=_TYPE_ RENAME=(_FREQ_=__KISECH))
             SUM= ;
   RUN;
   %GOTO E2;
  %END;
%END;
                           /* LA TABLE KISH NE CONTIENT PAS DE VARIABLES CATÉGORIELLES */


%ELSE %IF &CAT3=0 %THEN
%DO;
 DATA __KISH __KISELI (DROP=ELIMK);
      SET &DATAKISH (KEEP=&IDENT &IDENT2 &POIDKISH %DO I=1 %TO &NVARK; &&K&I %END;
                          %IF &NZK>0 %THEN %DO I=1 %TO &NZK;   &&ZK&I %END;);
      IF NMISS(%DO I=1 %TO &NVARK;&&K&I, %END;
               %IF &NZK>0 %THEN %DO J=1 %TO &NZK;&&ZK&J, %END;
               &POIDKISH) NE 0 OR &POIDKISH<=0 OR &IDENT=' ' THEN
      DO;
         ELIMK=1;
         OUTPUT __KISELI;
      END;
      ELSE ELIMK=0;
      %DO I=1 %TO &NVARK;
          &&K&I=&&K&I*&POIDKISH;
      %END;
      %IF &NZK>0 %THEN
      %DO I=1 %TO &NZK;
          &&ZK&I=&&ZK&I*&POIDKISH;
      %END;
      OUTPUT __KISH;
 RUN;

 %NOBSS(__KISELI,KISHELI)
 RUN;

 %IF &NKISH=1 %THEN %GOTO E1;

 %ELSE %IF &NKISH>1 %THEN
 %DO;
  PROC SUMMARY DATA=__KISH NWAY;
       CLASS &IDENT ;
       VAR %DO I=1 %TO &NVARK ; &&K&I %END;
           %IF &NZK>0 %THEN %DO I=1 %TO &NZK; &&ZK&I %END; &POIDKISH ELIMK;
       OUTPUT OUT=__SOMME(DROP=_TYPE_ RENAME=(_FREQ_=__KISECH))
              SUM(%DO I=1 %TO &NVARK ; &&K&I %END; &POIDKISH ELIMK)=
            %IF &NZK>0 %THEN
            %DO;
              SUM(%DO I=1 %TO &NZK; &&ZK&I %END;)=%DO I=1 %TO &NZK; ZK&I._1 %END;
            %END;
             ;
  RUN;
  %GOTO E2;
 %END;
%END;


%E1 :
PROC DATASETS DDNAME=WORK NOLIST;                     /* UN SEUL INDIVIDU-KISH PAR MÉNAGE */
     MODIFY __KISH;
     INDEX CREATE &IDENT;
QUIT;
DATA __MENAGE;                                         /* FUSION KISH-MÉNAGES */
            MERGE &MEN __KISH;
            BY &IDENT;
               __KISH=&POIDKISH;
RUN;
%GOTO E3;

%E2 :                                              /* PLUSIEURS INDIVIDUS-KISH PAR MÉNAGE */
PROC DATASETS DDNAME=WORK NOLIST;
     MODIFY __SOMME;
     INDEX CREATE &IDENT;
QUIT;

 DATA __MENAGE;
      MERGE &MEN __SOMME (RENAME=(&POIDKISH=__KISH));
      BY &IDENT;
 RUN;

%E3 :
PROC DATASETS DDNAME=WORK NOLIST;
     DELETE __SOMME %IF %UPCASE(&OBSELI) NE OUI OR &KISHELI=0 %THEN %DO; __KISELI %END; ;
     %IF %UPCASE(&OBSELI)=OUI AND &KISHELI>0 AND &CAT3>0 %THEN
	 %DO;
	    MODIFY __KISELI;
		RENAME %DO I=1 %TO &CAT3; _V&I=&&K&I %END;
		       %IF &CATZ3>0 %THEN %DO I=1 %TO &CATZ3; _Z&I=&&ZK&I; %END; ;
	 %END;
QUIT;
%MEND REMONTKI;
