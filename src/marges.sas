************                                                                  ************;
*****        RECOMPOSITION DU TABLEAU DES MARGES DE NIVEAU INDIVIDUS OU KISH        ******;
*****                 FUSION AVEC LA TABLE DES MARGES MÉNAGES                       ******;
************                                                                  ************;

%MACRO MARGES (ENTREE= )/store;
%LOCAL MAR1 LIST V CAT NM NMOD POP I;
%IF &ENTREE=__MARIND %THEN %DO;
  %LET MAR1=__MARMEN;
  %LET LIST=__CODIND;
  %LET V=I;
  %LET CAT=&CAT2;
  %LET NM=P;
  %LET NMOD=&NMAX2;
  %LET POP=POPIND;
%END;
%ELSE %IF &ENTREE=__MARKIS %THEN %DO;
        %IF &TYP=4 %THEN %LET MAR1=__MARMEN;
  %ELSE %IF &TYP=5 %THEN %LET MAR1=__MARGES;
  %LET LIST=__CODKIS;
  %LET V=K;
  %LET CAT=&CAT3;
  %LET NM=MK;
  %LET NMOD=&NMAX3;
  %LET POP=POPKISH;
%END;

%IF &NMOD=0 %THEN %LET NMOD=1;


%IF &CAT>0 %THEN             /* LA TABLE INDIVIDU CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */
%DO;


DATA __MAR;
 SET &ENTREE (RENAME=(VAR=VAR0));
  VAR1=COMPRESS("&V"!!_N_);
  N=INT(N)*(1-(N<0));
  TYPE1="C";                               /*  VARIABLE CATÉGORIELLE  */
  IF N=0 THEN TYPE1="N";                   /*  VARIABLE NUMÉRIQUE     */
  TOT=SUM(OF MAR1-MAR&NMOD);

   /*  SI LES MARGES DES VARIABLES CATÉGORIELLES SONT DONNÉES EN EFFECTIFS  */

  %IF %UPCASE(&PCT) NE OUI %THEN
  %DO;
    IF TYPE1="C" THEN
    DO;
      ARRAY MARG MARG1-MARG&NMOD;
      ARRAY MARGE  MAR1-MAR&NMOD;
      ARRAY PCT  PCT1-PCT&NMOD;
      DO OVER MARG;
        PCT=MARGE/TOT*100;
        MARG=MARGE;
      END;
    END;
    IF TYPE1="N" THEN MARG1=MAR1;
  %END;

   /*  SI LES MARGES DES VARIABLES CATÉGORIELLES SONT DONNÉES EN POURCENTAGES */

  %IF %UPCASE(&PCT)=OUI %THEN
  %DO;
    IF TYPE1="C" THEN
    DO;
      ARRAY MARG MARG1-MARG&NMOD;
      ARRAY MARGE  MAR1-MAR&NMOD;
      ARRAY PCT  PCT1-PCT&NMOD;
      DO OVER MARG;
        MARG=MARGE/100*&&&POP;
        PCT=MARGE;
      END;
    END;
    IF TYPE1="N" THEN MARG1=MAR1;
  %END;
RUN;

%IF %UPCASE(&PCT) NE OUI %THEN
 %DO;
  DATA _NULL_;
       SET __MAR(OBS=1);
       CALL SYMPUT("&POP",TOT);
  RUN;
%END;


PROC TRANSPOSE DATA=__MAR OUT=__MARI2;           /* REDÉFINITION DES MARGES INDIVIDUS */
     BY VAR1 VAR0 TYPE1 notsorted;                         /*           EN VARIABLES NUMÉRIQUES */
     VAR MARG1-MARG&NMOD;
PROC TRANSPOSE DATA=__MAR OUT=__MARI3;
     BY VAR1 VAR0 notsorted;
     VAR PCT1-PCT&NMOD;
DATA __MARI2;
     MERGE __MARI2 (RENAME=(COL1=MAR1)) __MARI3 (RENAME=(COL1=PCT1));
DATA __MARI2(DROP=_NAME_);
     LENGTH  VAR $32 MODALITE $ 8 ;
     SET __MARI2 ;
         N=0;
         IF MAR1 NE . ;
            MODALITE=SUBSTR(_NAME_,4);
            VAR=UPCASE(COMPRESS(VAR1!!'_'!!MODALITE));
            VAR0=UPCASE(VAR0);
            IF TYPE1="N" THEN MODALITE=" ";
            %DO I=1 %TO &CAT;
              IF VAR1="&V.&I" AND 10<=%CMPRES(&&&NM&I)<100 THEN
              DO;
                    IF INPUT(MODALITE,3.)<'10' THEN MODALITE=COMPRESS('0'!!MODALITE);
              END;
              ELSE IF VAR1="&V.&I" AND %CMPRES(&&&NM&I)>='100' THEN
              DO;
                    IF INPUT(MODALITE,3.)<10 THEN MODALITE=COMPRESS('00'!!MODALITE);
                    ELSE IF '10'<=INPUT(MODALITE,3.)<'100'
                         THEN MODALITE=COMPRESS('0'!!MODALITE);
              END;
            %END;

DATA __MARGES ;                           /* CONCATÉNATION DES MARGES MÉNAGES-INDIVIDUS */
    LENGTH NIVEAU  $1  ;
     SET &MAR1   (IN=M1)
         __MARI2 (IN=M2 KEEP=VAR N MAR1 PCT1 TYPE1);
         IF M1=1 AND "&MAR1"="__MARMEN" THEN
         DO;
           NIVEAU='1';
           IF N>0 THEN TYPE1='C';
           ELSE IF N=0 THEN TYPE1='N';
         END;
         IF M2=1 AND "&ENTREE"="__MARIND" THEN NIVEAU='2';
         IF M2=1 AND "&ENTREE"="__MARKIS" THEN NIVEAU='3';

PROC SORT DATA=__MARI2;                    /*       CONSTITUTION D'UNE TABLE DE PASSAGE */
     BY VAR0 MODALITE;                     /* ENTRE MODALITÉS INITIALES ET INDICATRICES */
PROC SORT DATA=&LIST;
     BY VAR MODALITE;
DATA &LIST (KEEP=VAR VAR0 MODALITE MODAL0);
     MERGE &LIST (RENAME=(VAR=VAR0))
           __MARI2 ;
     BY VAR0 MODALITE;
        IF VAR0 NE ' ' THEN OUTPUT;
PROC SORT DATA=&LIST;
     BY VAR MODALITE;
RUN;

%END;


                               /* LA TABLE INDIVIDU NE CONTIENT PAS DE VAR. CATÉGORIELLE */
%ELSE %IF &CAT=0 %THEN %DO;
 DATA __MARGES;
      SET &MAR1(IN=M1) &ENTREE(IN=M2);
         IF M2=1 AND "&ENTREE"="__MARIND" THEN NIVEAU='2';
         IF M2=1 AND "&ENTREE"="__MARKIS" THEN NIVEAU='3';
         IF M1=1 AND "&MAR1"="MARMEN"     THEN NIVEAU='1';
         IF N>0 THEN TYPE1='C';
         ELSE IF N=0 THEN TYPE1='N';
 RUN;
%END;

 PROC DATASETS DDNAME=WORK NOLIST;
      DELETE __MAR __MARI2 __MARI3;
 QUIT;

%MEND MARGES;
