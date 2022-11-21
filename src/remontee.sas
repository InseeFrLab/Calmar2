************                                                                  ************;
*****             REMONTÉE AU NIVEAU MÉNAGES DES VARIABLES INDIVIDUS                ******;
*****                 FUSION AVEC LA TABLE MÉNAGES INITIALE                         ******;
************                                                                  ************;

%MACRO REMONTEE / store;

%LOCAL MEN BASE PMAX INDELI I ;

%IF (&CAT1>0 OR &CATZ1>0)         %THEN %LET MEN=&TABMEN;
%ELSE %IF (&CAT1=0 AND &CATZ1=0)  %THEN %LET MEN=&DATAMEN;
RUN;
%IF %INDEX(&MEN,.) NE 0 %THEN %LET BASE=%SCAN(&MEN,1,.);
%ELSE                         %LET BASE=WORK;
RUN;
PROC DATASETS DDNAME=&BASE NOLIST;
     MODIFY &MEN;
     INDEX CREATE &IDENT;
QUIT;

                           /* LA TABLE INDIVIDU CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */

                                             /* CONSTRUCTION DES VARIABLES INDICATRICES */
%IF &CAT2>0  %THEN
 %DO;
 DATA __INDIV __INDELI (KEEP=&IDENT &IDENT2 %IF &TYP=2B %THEN &POIDS;
                             %DO I=1 %TO &CAT2; _V&I %END;
							 %IF &NUM2 >0  %THEN %DO I=%EVAL(&CAT2+1) %TO &NVARI; &&W&I %END;
                             %IF &CATZ2 >0 %THEN %DO J=1 %TO &CATZ2; _Z&J %END;
                             %IF &NUMZ2 >0 %THEN %DO J=%EVAL(&CATZ2+1) %TO &NZI; &&ZI&J %END;);
     DROP J;
     SET &TABIND;
  %DO I=1 %TO &NVARI ;                              /* VARIABLES DE CALAGE */
     %IF &&P&I=0 %THEN
      %DO;                                          /* VARIABLES QUANTITATIVES INDIVIDUS */
         I&I._1=&&W&I;
      %END;
     %ELSE %DO;
      ARRAY V&I(&&P&I) I&I._1-I&I._&&P&I;           /* VARIABLES QUALITATIVES INDIVIDUS  */
         DO J=1 TO &&P&I;
            IF &&W&I=J OR &&W&I=COMPRESS('0'!!J)
               OR &&W&I=COMPRESS('00'!!J)
            THEN V&I(J)=1;
            ELSE IF &&W&I=' ' THEN V&I(J)=. ;
            ELSE V&I(J)=0;
         END;
     %END;
  %END;
                                                    /* VARIABLES DE NON-RÉPONSE */
  %IF &NZI>0 %THEN
  %DO I=1 %TO &NZI;
     %IF &&MZI&I=0 %THEN                            /* VARIABLES QUANTITATIVES INDIVIDUS */
      %DO;
         ZI&I._1=&&ZI&I;
      %END;
     %ELSE %DO;
      ARRAY VZ&I(&&MZI&I) ZI&I._1-ZI&I._&&MZI&I;     /* VARIABLES QUALITATIVES INDIVIDUS  */
         DO J=1 TO &&MZI&I;
            IF &&ZI&I=J OR &&ZI&I=COMPRESS('0'!!J)
               OR &&ZI&I=COMPRESS('00'!!J)
            THEN VZ&I(J)=1;
            ELSE IF &&ZI&I=' ' THEN VZ&I(J)=. ;
            ELSE VZ&I(J)=0;
         END;
     %END;
  %END;
                                                    /* REPÉRAGE DES VALEURS MANQUANTES */
  IF &IDENT=' ' 
     %DO I=1 %TO &CAT2; OR &&W&I=' ' %END;
     %IF &NUM2>0 %THEN %DO I=%EVAL(&CAT2+1) %TO &NVARI; OR &&W&I=. %END;
     %IF &CATZ2>0  %THEN %DO J=1 %TO &CATZ2; OR &&ZI&J=' ' %END;
     %IF &NUMZ2>0  %THEN %DO J=%EVAL(&CATZ2+1) %TO &NZI; OR &&ZI&J=. %END;
     %IF &TYP=2B %THEN OR &POIDS=. OR &POIDS<=0 ;
  THEN
  DO;
    ELIMI=1;
    OUTPUT __INDELI;
  END;
  ELSE ELIMI=0;
  OUTPUT __INDIV;
  RUN;

 PROC SUMMARY DATA=__INDIV NWAY;                                /* SOMMATION PAR MÉNAGE */
      CLASS &IDENT ;
      VAR ELIMI
        %DO I=1 %TO &NVARI ;
            %IF &&P&I=0 %THEN %LET PMAX=1;
            %ELSE             %LET PMAX=&&P&I;
            I&I._1-I&I._&PMAX
        %END;
        %IF &NZI>0 %THEN
        %DO I=1 %TO &NZI ;
            %IF &&MZI&I=0 %THEN %LET PMAX=1;
            %ELSE               %LET PMAX=&&MZI&I;
            ZI&I._1-ZI&I._&PMAX
        %END;
           ;
      OUTPUT OUT=__SOMME(DROP=_TYPE_ RENAME=(_FREQ_=__IND))
             SUM= ;
%END;

                         /* LA TABLE INDIVIDU NE CONTIENT PAS DE VARIABLES CATÉGORIELLES */


%ELSE %IF &CAT2=0  %THEN
%DO;                                                  /* REPÉRAGE DES VALEURS MANQUANTES */
 DATA __INDIV __INDELI (KEEP=&IDENT &IDENT2 %IF &TYP=2B %THEN &POIDS;
                             %IF &NVARI>0 %THEN %DO I=1 %TO &NVARI; &&W&I %END;
                             %IF &NZI  >0 %THEN %DO J=1 %TO &NZI; &&ZI&J %END;);
      SET &DATAIND;
          IF NMISS(&W1 %IF &NVARI>1 %THEN %DO I=2 %TO &NVARI;,&&W&I %END;
                   %IF &TYP=2B %THEN %DO;,&POIDS %END;) NE 0
			 OR &IDENT=' '
             %IF &TYP=2B %THEN OR &POIDS<=0 ;  THEN
          DO;
            ELIMI=1;
            OUTPUT __INDELI;
          END;
          ELSE ELIMI=0;
          OUTPUT __INDIV;
 RUN;

 PROC SUMMARY DATA=__INDIV NWAY;
      CLASS &IDENT  ;
      VAR ELIMI
          %DO I=1 %TO &NVARI; &&W&I %END;
          %IF &NZI>0 %THEN %DO I=1 %TO &NZI; &&ZI&I %END; ;
      OUTPUT OUT=__SOMME(DROP=_TYPE_ RENAME=(_FREQ_=__IND))
             SUM(ELIMI %DO I=1 %TO &NVARI; &&W&I %END;)=
           %IF &NZI>0 %THEN
           %DO;
             SUM(%DO I=1 %TO &NZI; &&ZI&I %END;)=%DO I=1 %TO &NZI; ZI&I._1 %END;
           %END;
             ;
%END;

 %NOBSS(__INDELI,INDELI)
  RUN;

PROC DATASETS DDNAME=WORK NOLIST;
     MODIFY __SOMME;
     INDEX CREATE &IDENT;
QUIT;

                                                      /* FUSION INDIVIDUS-MÉNAGES */

 DATA __MENAGE;
      MERGE &MEN __SOMME(in=s)  ;
      BY &IDENT;
	   IF s=0 THEN
	   DO;
	     elimi=0;
        %IF &cat2>0 %THEN 
		%DO;

          %DO I=1 %TO &NVARI ;                              
            %IF &&P&I=0 %THEN if I&I._1=. then I&I._1=0 %str(;) ;
            %ELSE %DO;
              ARRAY V&I I&I._1-I&I._&&P&I;           /* VARIABLES QUALITATIVES INDIVIDUS  */
              DO over V&I;
                IF v&i=. then v&i=0;
              END;
            %END;
		  %END;

          %IF &NZI>0 %THEN
          %DO I=1 %TO &NZI;
            %IF &&MZI&I=. %THEN if ZI&I._1=. then ZI&I._1=0 %str(;) ;
            %ELSE %DO;
             ARRAY VZ&I ZI&I._1-ZI&I._&&MZI&I;     /* VARIABLES QUALITATIVES INDIVIDUS  */
             DO over VZ&I;
              IF VZ&I=. then VZ&I=0 ;
             END;
            %END;
          %END;

		%END;

        %ELSE %DO;
          %DO I=1 %TO &NVARI; 
              if &&W&I=. then &&W&I=0;
          %END;
          %IF &NZI>0 %THEN %DO I=1 %TO &NZI; 
              if &&ZI&I=. then &&ZI&I=0;
          %END; ;
		%END;

	   END;
 RUN;

 PROC DATASETS DDNAME=WORK NOLIST;
      DELETE __SOMME %IF %UPCASE(&OBSELI) NE OUI OR &INDELI=0 %THEN  __INDELI ; ;
	%IF %UPCASE(&OBSELI)=OUI AND &INDELI>0 AND &CAT2>0 %THEN 
    %DO;
      MODIFY __INDELI;
	    RENAME %DO I=1 %TO &CAT2; _V&I=&&W&I %END;
		       %IF &CATZ2>0 %THEN %DO J=1 %TO &CATZ2; _Z&J=&&ZI&J %END; ;
    %END;
 QUIT;

%MEND REMONTEE;
