%MACRO CALMAR1 (
DATA      =       , /* TABLE SAS EN ENTRÉE                                    */
M         = 1     , /* MÉTHODE UTILISÉE                                       */
POIDS     =       , /* PONDÉRATION INITIALE (POIDS DE SONDAGE DK)             */
POIDSFIN  =       , /* PONDÉRATION FINALE   (POIDS DE CALAGE WK)              */
PONDQK    = __UN  , /* PONDÉRATION QK                                         */
LABELPOI  =       , /* LABEL DE LA PONDÉRATION FINALE                         */
DATAPOI   =       , /* TABLE CONTENANT LA PONDÉRATION FINALE (NIVEAU 1)       */
MISAJOUR  =  OUI  , /* MISE À JOUR DE LA TABLE &DATAPOI SI ELLE EXISTE DÉJÀ   */
CONTPOI   =  OUI  , /* CONTENU DE LA TABLE PRÉCEDENTE                         */
LO        =       , /* BORNE INFÉRIEURE (MÉTHODE LOGIT OU LINÉAIRE TRONQUÉE)  */
UP        =       , /* BORNE SUPÉRIEURE (MÉTHODE LOGIT OU LINÉAIRE TRONQUÉE)  */
EDITPOI   =  NON  , /* EDITION DES POIDS PAR COMBINAISON DE VALEURS           */
STAT      =  OUI  , /* STATISTIQUES SUR LES POIDS                             */
OBSELI    =  NON  , /* STOCKAGE DES OBSERVATIONS ÉLIMINÉES DANS UNE TABLE     */
IDENT     =       , /* IDENTIFIANT DES OBSERVATIONS (NIVEAU 1)                */
DATAMAR   =       , /* TABLE SAS CONTENANT LES MARGES DES VARIABLES DE CALAGE */
PCT       =  NON  , /* PCT = OUI SI LES MARGES SONT EN POURCENTAGES           */
EFFPOP    =       , /* EFFECTIF DE MÉNAGES DANS LA POPULATION  (SI PCT = OUI) */
CONT      =  OUI  , /* SI CONT = OUI DES CONTROLES SONT EFFECTUÉS             */
MAXITER   =   15  , /* NOMBRE MAXIMUM D'ITÉRATIONS                            */
NOTES     =  NON  , /* PAR DÉFAUT : OPTIONS NONOTES                           */
SEUIL     = 0.0001  /* SEUIL POUR LE TEST D'ARRET                             */
) /STORE ;

%LOCAL EFFINIT EFFECH LLB NBVER NMAX EFIND1 EFIND EFIND2 EFKISH1 EFKISH EFKISH2
       INDECH KISHECH INDELI KISHELI GAMMA SPOIDS I J K L P Q ;

FOOTNOTE1;FOOTNOTE2;FOOTNOTE3;FOOTNOTE4;FOOTNOTE5;


  /*   LA PROC CONTENTS SERA UTILISÉE AU MOMENT DE LA LECTURE DE LA TABLE DATAMAR   */

  PROC CONTENTS NOPRINT DATA=%SCAN(&DATA,1,'(')
                OUT=__NOMVAR; 
  DATA __NOMVAR (KEEP=VAR TYPE);
       SET __NOMVAR;
	   LENGTH VAR $ 32;
	       VAR=UPCASE(LEFT(NAME));
  PROC SORT DATA=__NOMVAR;
    BY VAR;


%LET NITER=0;
%LET FINI=0;
%LET MAXDIF=1;
%LET NPOINEG=;
%LET VC1=;
%LET VN1=;
%LET POINEG=0;
%LET PBIML=0;
%LET ARRET=0;
%LET MAXIT=0;

%IF &ECHELLE=%STR()     %THEN %LET GAMMA=1;
%ELSE %IF &ECHELLE NE 0 %THEN %LET GAMMA=&ECHELLE;


   /*  DÉTERMINATION DU NOMBRE MAXIMUM DE MODALITÉS  */

%NMOD(DATAMAR,NMAX)


   /*****************************************
    ***  LECTURE DE LA TABLE SAS DATAMAR  ***
    *****************************************/

DATA __MAR1;
  SET &DATAMAR;
  VAR=LEFT(UPCASE(VAR));
  N=INT(N)*(1-(N<0));
  TYPE="C";                               /*  VARIABLE CATÉGORIELLE  */
  IF N=0 THEN TYPE="N";                   /*  VARIABLE NUMÉRIQUE     */
  TOT=SUM(OF MAR1-MAR&NMAX);

   /*  SI LES MARGES DES VARIABLES CATÉGORIELLES SONT DONNÉES EN EFFECTIFS  */

  %IF %UPCASE(&PCT) NE OUI %THEN
  %DO;
    IF TYPE="C" THEN
    DO;
      ARRAY MARG MARG1-MARG&NMAX;
      ARRAY MARGE  MAR1-MAR&NMAX;
      ARRAY PCT  PCT1-PCT&NMAX;
      DO OVER MARG;
        PCT=MARGE/TOT*100;
        MARG=MARGE;
      END;
    END;
    IF TYPE="N" THEN MARG1=MAR1;
  %END;

   /*  SI LES MARGES DES VARIABLES CATÉGORIELLES SONT DONNÉES EN POURCENTAGES */

  %IF %UPCASE(&PCT)=OUI %THEN
  %DO;
    IF TYPE="C" THEN
    DO;
      ARRAY MARG MARG1-MARG&NMAX;
      ARRAY MARGE  MAR1-MAR&NMAX;
      ARRAY PCT  PCT1-PCT&NMAX;
      DO OVER MARG;
        MARG=MARGE/100*&EFFPOP;
        PCT=MARGE;
      END;
    END;
    IF TYPE="N" THEN MARG1=MAR1;
  %END;
  %IF &TYP=1 OR &TYP=2 %THEN
  %DO;
      TYPE1=TYPE;
  %END;


   /**********************************************************************
    ***  CONSTRUCTION DE LA TABLE __MAR3 ET DES MACROS-VARIABLES       ***
    ***  CONTENANT LES NOMS DES VARIABLES ET LES NOMBRES DE MODALITÉS  ***
    **********************************************************************/

PROC SORT DATA=__MAR1;                   /*  TRI PAR TYPE DE VARIABLE  */
  BY NIVEAU TYPE1 VAR;

PROC FREQ DATA=__MAR1;
  TABLES TYPE/ OUT=__LEC1 NOPRINT;

DATA _NULL_;
  SET __LEC1;
  %LET JJ=0;          /*  JJ EST LE NOMBRE DE VARIABLES CATÉGORIELLES  */
  %LET LL=0;          /*  LL EST LE NOMBRE DE VARIABLES NUMÉRIQUES     */
  IF TYPE="C" THEN CALL SYMPUT('JJ',LEFT(PUT(COUNT,9.)));
  IF TYPE="N" THEN CALL SYMPUT('LL',LEFT(PUT(COUNT,9.)));
RUN;

DATA _NULL_;
  MERGE __MAR1(WHERE=(TYPE="C") IN=IN1) __NOMVAR(RENAME=(TYPE=TYPESAS));
  BY VAR;
  IF IN1;
  RETAIN K 0;
  K=K+1;
  J=PUT(K,4.);       /* <- !!! correction du 18/05/2010 : 9999 variables catégorielles possibles */
  IF K=1 THEN NN=N;
  ELSE NN=N-1;
  MAC="VC"!!LEFT(J); /* LES VCJ CONTIENDRONT LES NOMS DES VAR. CATÉGORIELLES  */
  MAD="M"!!LEFT(J);  /* LES MJ (RESP.NJ) CONTIENDRONT LES NOMBRES DE MODALITÉS*/
  MAE="N"!!LEFT(J);  /*(RESP. -1, SAUF LA 1ÈRE) DES VARIABLES CATÉGORIELLES   */
  MAF="T"!!LEFT(J);  /* LES TJ VALENT 1 POUR UNE VAR.NUM., 2 POUR UNE VAR.CAR.*/
  CALL SYMPUT(MAC,TRIM(VAR));
  CALL SYMPUT(MAD,(LEFT(PUT(N,3.))));
  CALL SYMPUT(MAE,(LEFT(PUT(NN,3.))));
  CALL SYMPUT(MAF,(LEFT(PUT(TYPESAS,1.))));
RUN;

DATA _NULL_;
  SET __MAR1(WHERE=(TYPE="N"));
  J=PUT(_N_,4.);       /* <- !!! MODIFICATION DU 26/02/2009 : 9999 variables numériques possibles */
  MAC="VN"!!LEFT(J);   /* LES VNJ CONTIENDRONT LES NOMS DES VAR. NUMÉRIQUES  */
  CALL SYMPUT(MAC,TRIM(VAR));
RUN;

PROC TRANSPOSE DATA=__MAR1 OUT=__MAR30;
  BY NIVEAU VAR TYPE TYPE1 NOTSORTED;
  VAR MARG1-MARG&NMAX;
  TITLE4;

PROC TRANSPOSE DATA=__MAR1 OUT=__MAR31;
  BY NIVEAU VAR TYPE TYPE1 NOTSORTED;
  VAR PCT1-PCT&NMAX;

DATA __MAR3;
  MERGE __MAR30(RENAME=(COL1=MARGE)) __MAR31(RENAME=(COL1=PCTMARGE));


   /*******************************************************************
    ** UN NOUVEAU CONTROLE ... SUR LE PARAMÈTRE POIDS CETTE FOIS-CI  **
    *******************************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;
  %IF &POIDS = AND &VC1 = %THEN
  %DO;
  DATA _NULL_;
    FILE PRINT;
   PUT //@2 "*****************************************************************";
    PUT @2 "***   ERREUR : LE PARAMÈTRE POIDS N'EST PAS RENSEIGNÉ ALORS   ***";
    PUT @2 "***            QU'IL N'Y A PAS DE VARIABLE CATÉGORIELLE       ***";
    PUT @2 "*****************************************************************";
    %GOTO FFIN;
  %END;


  /***************************************
   *** ... ET SUR LE PARAMÈTRE ECHELLE ***
   ***************************************/

  %IF &ECHELLE=0 AND &EFFPOP=%STR( ) AND &VC1=%STR( ) %THEN
  %DO;
  DATA _NULL_;
    FILE PRINT;
   PUT //@2 "**************************************************************************";
   %IF &TYP NE 2 %THEN
   %DO;
    PUT @2 "***   ERREUR : LE PARAMÈTRE POPMEN N'EST PAS RENSEIGNÉ ALORS           ***";
    PUT @2 "***            QU'IL N'Y A PAS DE VARIABLE CATÉGORIELLE                ***";
    PUT @2 "***            DANS LA TABLE &MARMEN INDIQUÉE DANS LE PARAMÈTRE MARMEN ***";
   %END;
   %ELSE
   %DO;
    PUT @2 "***   ERREUR : LE PARAMÈTRE POPIND N'EST PAS RENSEIGNÉ ALORS           ***";
    PUT @2 "***            QU'IL N'Y A PAS DE VARIABLE CATÉGORIELLE                ***";
    PUT @2 "***            DANS LA TABLE &MARIND INDIQUÉE DANS LE PARAMÈTRE MARIND ***";
   %END;
    PUT @2 "***            ET QUE LE FACTEUR D'ÉCHELLE DOIT ÊTRE CALCULÉ           ***";
    PUT @2 "***            (LE PARAMÈTRE ECHELLE VAUT 0)                           ***";
    PUT @2 "**************************************************************************";
    %GOTO FFIN;
  %END;

%END;


  /***********************************************
   **  CALCUL DE LA TAILLE DE LA POPULATION     **
   **  EN PRÉSENCE DE VARIABLES CATÉGORIELLES   **
   ***********************************************/


%IF &VC1 NE AND %UPCASE(&PCT) NE OUI %THEN
%DO;

  DATA _NULL_;
    SET __MAR1(KEEP=TOT OBS=1);
    CALL SYMPUT("EFFPOP",LEFT(PUT(TOT,10.)));
  RUN;

%END;

  /************************************************************
   ** CALCUL DE LA TAILLE DE L'ÉCHANTILLON SI LA VARIABLE DE **
   ** PONDÉRATION INITIALE &POIDS EST MANQUANTE              **
   **                                                        **
   ** CALCUL DE LA SOMME DES POIDS SI LE FACTEUR D'ÉCHELLE   **
   ** EST À CALCULER                                         **
   ************************************************************/

%LET PONDGEN=0;

%IF &POIDS =  OR &ECHELLE=0 %THEN
%DO;

  DATA __MARY;
    SET &DATA;
    KEEP %DO J=1 %TO &JJ; &&VC&J %END;
         %DO L=1 %TO &LL; &&VN&L %END;
         %IF &NZ>0 %THEN %DO; &ZZ0  %END;
         %IF &PONDQK NE AND &PONDQK NE __UN %THEN
           %DO;
             &PONDQK
           %END;
         %IF &POIDS NE %THEN
           %DO;
             &POIDS
           %END;
    %STR(;);
    IF NMISS
       (%DO J=1 %TO &JJ; &&VC&J ,%END; %DO L=1 %TO &LL; &&VN&L , %END;
         %IF &NZM>0   %THEN %DO I=1 %TO &NZM;           &&ZM&I , %END;
         %IF &CATZ2>0 %THEN %DO I=1 %TO &CATZ2; %DO J=1 %TO &&MZI&I; ZI&I._&J , %END;%END;
         %IF &NUMZ2>0 %THEN %DO I=%EVAL(&CATZ2+1) %TO &NZI;          ZI&I_1,    %END;
         %IF &CATZ3>0 %THEN %DO I=1 %TO &CATZ3; %DO J=1 %TO &&MZK&I; ZK&I._&J , %END;%END;
         %IF &NUMZ3>0 %THEN %DO I=%EVAL(&CATZ3+1) %TO &NZK;          ZK&I_1, %END;
         0) = 0
        %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; AND ELIMI=0 %END;
        %IF &TYP=4  OR &TYP=5           %THEN %DO; AND ELIMK=0 %END;
        %IF &PONDQK NE AND &PONDQK NE __UN %THEN %DO; AND &PONDQK GT 0 %END;
        %IF &POIDS  NE %THEN %DO; AND &POIDS GT 0 %END;
     %STR(;);
  RUN;

  %NOBSS(__MARY,EFFECH)

  %IF &EFFECH=0 %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
               %IF &TYP NE 2 AND &TYP NE 2B %THEN
               %DO;
      PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAMEN)" @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAMEN A 0 OBSERVATION"
          @73 "***";
               %END;
               %ELSE
               %DO;
      PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAIND)" @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAIND A 0 OBSERVATION"
          @73 "***";
               %END;
      PUT @2 "***            NON ÉLIMINÉE" @73 "***";
      PUT @2 74*"*";
    %GOTO FFIN;
  %END;

 %IF &POIDS=  %THEN
 %DO;
    %LET PONDGEN=1;
    %LET GAMMA=1;
 %END;

 %ELSE %IF &ECHELLE=0 %THEN
 %DO;
     PROC SUMMARY DATA=__MARY NWAY;
          VAR &POIDS;
          OUTPUT OUT=SOMPOIDS SUM= ;
     DATA _NULL_;
          SET SOMPOIDS;
          GAMMA=&EFFPOP/&POIDS;
          CALL SYMPUT('SPOIDS',LEFT(PUT(&POIDS,10.)));
          CALL SYMPUT('GAMMA',TRIM(LEFT(GAMMA)));
     RUN;
 %END;

%END;


   /**************************************************
    ***  CRÉATION DE LA TABLE DE TRAVAIL __CALAGE  ***
    ***  ET DE LA TABLE __PHI                      ***
    **************************************************/

DATA __CALAGE (KEEP=%IF &JJ>0 %THEN %DO I=1 %TO &JJ; _V&I %END;
                    %DO J=1 %TO &JJ; &&VC&J %DO I=1 %TO &&M&J; Y&J._&I  %END;%END;
                    %DO L=1 %TO &LL; &&VN&L %END;
                    %IF &NZ>0 %THEN %DO; &ZZM  &ZZ1 %END;
                    %IF &POIDS =  AND  &VC1 NE %THEN %DO;__POND__ %END;
                    %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN __IND ELIMI ;
                    %IF &TYP=4 OR &TYP=5 %THEN %DO;
                        __KISH  ELIMK  %IF &NKISH>1 %THEN __KISECH; 
                    %END;
                    &POIDS __UN __WFIN __POIDS  &PONDQK &IDENT ELIM)
  %IF %UPCASE(&OBSELI)=OUI AND &TYP NE 2B %THEN
  %DO;
     __OBSELI(KEEP =&IDENT &POIDS &PONDQK
                %IF &JJ=0 %THEN %DO;
                    %IF &TYP NE 2 %THEN %DO I=1 %TO &NVARM; &&V&I %END;
					%ELSE               %DO I=1 %TO &NVARI; &&W&I %END;
                    %IF &TYP NE 2 AND &NZM>0 %THEN  &ZZM  ;
                    %IF &TYP=2 AND &NZI>0 %THEN %DO I=1 %TO &NZI; &&ZI&I %END;
		        %END;
				%ELSE %DO;
                    %DO I=1 %TO &JJ; _V&I %END;
                    %IF &TYP NE 2 AND &NUM1>0 %THEN %DO I=%EVAL(&JJ+1) %TO &NVARM; &&V&I %END;
                    %IF &TYP=2 AND &NUM2>0 %THEN %DO I=%EVAL(&JJ+1) %TO &NVARI; &&W&I %END;
                    %IF &TYP NE 2 AND &CATZ1>0 %THEN %DO I=1 %TO &CATZ1; _Z&I %END;
                    %IF &TYP=2 AND &CATZ2>0 %THEN %DO I=1 %TO &CATZ2; _Z&I %END;
                    %IF &TYP NE 2 AND &NUMZ1>0 %THEN %DO I=%EVAL(&CATZ1+1) %TO &NZM; &&ZM&I %END;
                    %IF &TYP=2 AND &NUMZ2>0 %THEN %DO I=%EVAL(&CATZ2+1) %TO &NZI; &&ZI&I %END;
                %END;
                %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN ELIMI;
                %IF &TYP>=4 %THEN ELIMK;) ;

     LABEL %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN ELIMI="nombre d'individus éliminés" ;
		   %IF &TYP=4  OR &TYP=5           %THEN ELIMK="nombre d'unités Kish éliminées" ; ;
  %END;
  %STR(;);
  SET &DATA;
  
  __UN=1;
  %IF &PONDGEN=1 %THEN
  %DO;
    __POND__=&EFFPOP/&EFFECH;
    __POIDS=__POND__*&PONDQK;
    __WFIN=__POND__;
    CALL SYMPUT('POIDS','__POND__');
  %END;
  %IF &POIDS NE  %THEN
  %DO;
    __POIDS=&POIDS*&PONDQK*&GAMMA;
    __WFIN=&POIDS*&GAMMA;
  %END;
  IF NMISS
  (%DO J=1 %TO &JJ; &&VC&J ,%END; %DO L=1 %TO &LL;  &&VN&L , %END;
         %IF &NZ >0 %THEN %DO; &ZZMV   %END;
         %IF &TYP>=2 %THEN
         %DO;
          %IF &CATZ2>0 %THEN %DO I=1 %TO &CATZ2; %DO J=1 %TO &&MZI&I; ZI&I._&J , %END;%END;
          %IF &NUMZ2>0 %THEN %DO I=%EVAL(&CATZ2+1) %TO &NZI;          ZI&I._1,    %END;
          %IF &CATZ3>0 %THEN %DO I=1 %TO &CATZ3; %DO J=1 %TO &&MZK&I; ZK&I._&J , %END;%END;
          %IF &NUMZ3>0 %THEN %DO I=%EVAL(&CATZ3+1) %TO &NZK;          ZK&I._1, %END;
         %END;
   __POIDS)=0
  AND __POIDS GT 0
  %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; AND ELIMI=0 %END;
  %IF &TYP=4  OR &TYP=5           %THEN %DO; AND ELIMK=0 %END;
  THEN ELIM=0;
  ELSE
  DO;
    ELIM=1;
    %IF %UPCASE(&OBSELI)=OUI AND &TYP NE 2B %THEN
    %DO;
      OUTPUT __OBSELI;
    %END;
  END;

 /*  CRÉATION DE VARIABLES DISJONCTIVES À PARTIR DES VARIABLES CATÉGORIELLES  */

  %DO J=1 %TO &JJ;           /* VARIABLES DE CALAGE X */
    %IF &&T&J=1 %THEN                                /* CAS DE VARIABLES NUMÉRIQUES-SAS  */
      %DO I=1 %TO &&M&J;
        Y&J._&I=(&&VC&J=&I);
      %END;
    %IF &&T&J=2 %THEN                                /* CAS DE VARIABLES CARACTÈRES-SAS  */
      %DO;
        %IF &&M&J<10 %THEN                           /*  MOINS DE 10 MODALITÉS  */
        %DO I=1 %TO &&M&J;
          Y&J._&I=(&&VC&J="&I");
        %END;
        %ELSE %IF &&M&J<100 %THEN                    /*  DE 10 À 99 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            Y&J._&I=(&&VC&J="0&I");
          %END;
          %DO I=10 %TO &&M&J;
            Y&J._&I=(&&VC&J="&I");
          %END;
        %END;
        %ELSE                                      /*  DE 100 À 999 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            Y&J._&I=(&&VC&J="00&I");
          %END;
          %DO I=10 %TO 99;
            Y&J._&I=(&&VC&J="0&I");
          %END;
          %DO I=100 %TO &&M&J;
            Y&J._&I=(&&VC&J="&I");
          %END;
        %END;
      %END;
  %END;

%IF &NZM>0 %THEN                  /* VARIABLES DE NON-RÉPONSE Z */
%DO;
  %IF &CATZ1>0 %THEN
  %DO J=1 %TO &CATZ1;

        %IF &&MZM&J<10 %THEN                                /*  MOINS DE 10 MODALITÉS  */
        %DO I=1 %TO &&MZM&J;
          ZM&J._&I=(&&ZM&J="&I" OR &&ZM&J=&I);
        %END;
        %ELSE %IF &&MZM&J<100 %THEN                         /*  DE 10 À 99 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            ZM&J._&I=(&&ZM&J="0&I" OR &&ZM&J=&I);
          %END;
          %DO I=10 %TO &&MZM&J;
            ZM&J._&I=(&&ZM&J="&I" OR &&ZM&J=&I);
          %END;
        %END;
        %ELSE                                               /*  DE 100 À 999 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            ZM&J._&I=(&&ZM&J="00&I" OR &&ZM&J=&I);
          %END;
          %DO I=10 %TO 99;
            ZM&J._&I=(&&ZM&J="0&I" OR &&ZM&J=&I);
          %END;
          %DO I=100 %TO &&MZM&J;
            ZM&J._&I=(&&ZM&J="&I" OR &&ZM&J=&I);
          %END;
        %END;
  %END;
  %IF &NUMZ1>0 %THEN                                         /* VARIABLES NUMÉRIQUES */
  %DO L=%EVAL(&CATZ1+1) %TO &NZM;
      ZM&L._1=&&ZM&L;
  %END;
%END;

%ELSE %IF &TYP=2  %THEN                          /* CALAGE SÉPARÉ INDIVIDUS */
%DO;
  %IF &CATZ2>0 %THEN
  %DO J=1 %TO &CATZ2;

        %IF &&MZI&J<10 %THEN                                /*  MOINS DE 10 MODALITÉS  */
        %DO I=1 %TO &&MZI&J;
          ZI&J._&I=(&&ZI&J="&I" OR &&ZI&J=&I);
        %END;
        %ELSE %IF &&MZI&J<100 %THEN                         /*  DE 10 À 99 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            ZI&J._&I=(&&ZI&J="0&I" OR &&ZI&J=&I);
          %END;
          %DO I=10 %TO &&MZI&J;
            ZI&J._&I=(&&ZI&J="&I" OR &&ZI&J=&I);
          %END;
        %END;
        %ELSE                                               /*  DE 100 À 999 MODALITÉS  */
        %DO;
          %DO I=1 %TO 9;
            ZI&J._&I=(&&ZI&J="00&I" OR &&ZI&J=&I);
          %END;
          %DO I=10 %TO 99;
            ZI&J._&I=(&&ZI&J="0&I" OR &&ZI&J=&I);
          %END;
          %DO I=100 %TO &&MZI&J;
            ZI&J._&I=(&&ZI&J="&I" OR &&ZI&J=&I);
          %END;
        %END;
  %END;
  %IF &NUMZ2>0 %THEN                                         /* VARIABLES NUMÉRIQUES */
  %DO L=%EVAL(&CATZ2+1) %TO &NZI;
      ZI&L._1=&&ZI&L;
  %END;
%END;

OUTPUT __CALAGE;
RUN;

   /*   CALCUL DE L'EFFECTIF (NON PONDÉRÉ) DE L'ÉCHANTILLON)   */

%NOBSS(__CALAGE,EFFINIT)


   /*   CALCUL DES NOMBRES D'OBSERVATIONS ÉLIMINÉES ET CONSERVÉES   */

%IF &PONDGEN=1 %THEN       /*  NOMBRE D'OBSERVATIONS CONSERVÉES DÉJÀ CALCULÉ  */
%DO;
  %LET EFFELIM=%EVAL(&EFFINIT-&EFFECH);
%END;

                            /*  NOMBRE D'OBSERVATIONS CONSERVÉES NON CALCULÉ  */
%IF &PONDGEN=0 OR &TYP>2 %THEN
%DO;

  %LET EFFELIM=0;
  %LET INDELI=0;
  %LET KISHELI=0;

  PROC MEANS DATA=__CALAGE NOPRINT;
    WHERE ELIM=1;
    VAR ELIM
        %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND %END;
        %IF (&TYP=4 OR &TYP=5) %THEN %DO; %IF &NKISH>1 %THEN __KISECH ; %END; ;
    OUTPUT OUT=__EFFELI SUM=;

  DATA _NULL_;
    SET __EFFELI;
    CALL SYMPUT("EFFELIM",LEFT(PUT(ELIM,10.)));
    %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN
    %DO;
        CALL SYMPUT("INDELI",LEFT(PUT(__IND,10.)));
    %END;
    %IF (&TYP=4 OR &TYP=5) %THEN
    %DO;
	    %IF &NKISH>1 %THEN CALL SYMPUT("KISHELI",LEFT(PUT(__KISECH,10.))); ;
    %END;
  RUN;

  %IF (&TYP=4 OR &TYP=5) %THEN 
  %DO; 
       %IF &NKISH>1 %THEN %LET KISHELI=&EFFELIM; ;
  %END;

  %LET EFFECH=%EVAL(&EFFINIT-&EFFELIM);

  %IF &EFFECH=0 %THEN
  %DO;
   %IF %UPCASE(&OBSELI)=OUI  AND &TYP NE 2B AND &JJ>0 %THEN
   %DO;
    PROC DATASETS NOLIST;
        MODIFY __OBSELI;
		RENAME %DO I=1 %TO &JJ; _V&I=%IF &TYP NE 2 %THEN &&V&I ; %ELSE &&W&I ;%END; 
		       %IF &CATZ1>0 %THEN %DO I=1 %TO &CATZ1; _Z&I=&&ZM&I %END; 
		       %IF &TYP=2 AND &CATZ2>0 %THEN %DO I=1 %TO &CATZ2; _Z&I=&&ZI&I %END; ;
    QUIT;
   %END;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
               %IF &TYP NE 2 AND &TYP NE 2B %THEN
               %DO;
      PUT @2 "***   ERREUR : LA TABLE  %UPCASE(&DATAMEN)" @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAMEN A &EFFINIT"
             " OBSERVATIONS..." @73 "***";
               %END;
               %ELSE
               %DO;
      PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAIND)" @73 "***";
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAIND A &EFFINIT"
             " OBSERVATIONS..." @73 "***";
               %END;
      PUT @2 "***            MAIS ELLES SONT TOUTES ÉLIMINÉES !" @73 "***";
      PUT @2 "***" @73 "***";
      PUT @2 "***   UNE OBSERVATION DE LA TABLE EN ENTRÉE EST ÉLIMINÉE DÈS QUE :"
              @73 "***";
      PUT @2 "***   - ELLE A UNE VALEUR MANQUANTE SUR L'UNE DES VARIABLES DU"
          " CALAGE" @73 "***";
      PUT @2 "***   - ELLE A UNE VALEUR MANQUANTE, NÉGATIVE OU NULLE SUR L'UNE"
          @73 "***";
      PUT @2 "***     DES VARIABLES DE PONDÉRATION." @73 "***";
      PUT @2 74*"*";
    %GOTO FFIN;
  %END;
%END;

   %IF %UPCASE(&OBSELI)=OUI %THEN
   %DO;
    PROC DATASETS NOLIST;
	  %IF &EFFELIM=0 %THEN %DO; DELETE __OBSELI ; %END;
      %ELSE %IF &EFFELIM>0 AND &TYP NE 2B AND &JJ>0 %THEN
      %DO;
        MODIFY __OBSELI;
		RENAME %DO I=1 %TO &JJ; _V&I=%IF &TYP NE 2 %THEN &&V&I ; %ELSE &&W&I ;%END; 
		       %IF &CATZ1>0 %THEN %DO I=1 %TO &CATZ1; _Z&I=&&ZM&I %END; 
		       %IF &TYP=2 AND &CATZ2>0 %THEN %DO I=1 %TO &CATZ2; _Z&I=&&ZI&I %END; ;
	  %END;
    QUIT;
   %END;

PROC MEANS DATA=__CALAGE(WHERE=(ELIM=0)) NOPRINT;
  VAR
   %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND  %END;
   %IF &TYP=4 OR &TYP=5 %THEN %DO;            __KISH %END;
   __UN
  %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
  %DO L=1 %TO &LL; &&VN&L   %END;
  %STR(;);
  WEIGHT __WFIN;
  OUTPUT OUT=__PHI SUM=;



   /******************************************************************
    ***  RÉCUPÉRATION DANS LES MACRO-VARIABLES &EFIND ET &EFKISH   ***
    ***  DES EFFECTIFS PONDÉRÉS DES ÉCHANTILLONS INDIVIDUS ET KISH ***
    ******************************************************************/


PROC TRANSPOSE DATA=__PHI OUT=__PHI2;

DATA __PHI2 ;
     %IF &GAMMA NE 1 %THEN 
     %DO;
        DROP __IND1 __KISH1
        %IF &ECHELLE NE 0 %THEN __SPOIDS ;
		%str(;)
	 %END;
  SET __PHI2(FIRSTOBS=3 RENAME=(COL1=ECHANT));
  RETAIN EFFPOND EFFPONDI EFFPONDK;
  IF _NAME_='__UN' THEN
  DO;
    EFFPOND=ECHANT;
    CALL SYMPUT("EFFPOND",LEFT(PUT(ECHANT,10.)));
    %IF &GAMMA NE 1 AND &ECHELLE NE 0 %THEN
    %DO;
       __SPOIDS=ECHANT/&GAMMA;
       CALL SYMPUT("SPOIDS",LEFT(PUT(__SPOIDS,10.)));
    %END;
  END;
  ELSE IF _NAME_='__IND' THEN
  DO;
    EFFPONDI=ECHANT;
    CALL SYMPUT("EFIND",LEFT(PUT(ECHANT,10.)));
    %IF &GAMMA NE 1 %THEN
    %DO;
       __IND1=ECHANT/&GAMMA;
       CALL SYMPUT('EFIND1',LEFT(PUT(__IND1,10.)));
    %END;
  END;
  ELSE IF _NAME_='__KISH' THEN
  DO;
    EFFPONDK=ECHANT;
    CALL SYMPUT("EFKISH",LEFT(PUT(ECHANT,10.)));
    %IF &GAMMA NE 1 %THEN
    %DO;
       __KISH1=ECHANT/&GAMMA;
       CALL SYMPUT('EFKISH1',LEFT(PUT(__KISH1,10.)));
    %END;
  END;

RUN;

%LET PB1=0;

DATA __MAR4 (DROP=EFFPONDI EFFPONDK) ;
     MERGE __PHI2(FIRSTOBS=
                           %IF &TYP=1 OR &TYP=2 %THEN %DO;                  2 %END;
                           %ELSE %IF &TYP=2B OR &TYP=3 OR &TYP=4 %THEN %DO; 3 %END;
                           %ELSE %IF &TYP=5 %THEN %DO;                      4 %END; )
           __MAR3(WHERE=(MARGE NE .));
  LENGTH VAR1 $32. MODALITE $8. MODAL2 $8.;
  MODAL1=SUBSTR(_NAME_,4,5);
  RETAIN J 0;
  IF _NAME_="PCT1" THEN J+1;
  %DO I=1 %TO &JJ;
    IF J=&I THEN
    DO;
      %IF &&T&I=1 %THEN
      %DO;
        MODAL2=MODAL1;
      %END;
      %IF &&T&I=2 %THEN
      %DO;
        %LET LONG&I=%LENGTH(&&M&I);
        MODAL2=(PUT(INPUT(MODAL1,8.),Z&&LONG&I...));
      %END;
    END;
  %END;
  VAR1=VAR;
  MODALITE=RIGHT(MODAL2);
  %IF &EFIND NE %STR( ) %THEN
  %DO;
    IF NIVEAU='2' THEN EFFPOND=EFFPONDI;
  %END;
  %IF &EFKISH NE %STR( ) %THEN
  %DO;
    IF NIVEAU='3' THEN EFFPOND=EFFPONDK;
  %END;
  PCTECH=ECHANT/EFFPOND*100;
  IF TYPE1="N" THEN DO; PCTECH=.;MODAL2=' ';END;
  IF TYPE1="C" AND ECHANT=0 AND MARGE NE 0 THEN
  DO;
    ERR="*";
    CALL SYMPUT('PB1','1');
  END;
RUN;



 /************************************************************************************
  **** CRÉATION D'UNE TABLE DES MARGES ÉLIMINANT LES MARGES INDIVIDUS REDONDANTES ****
  **** CRÉATION DE MACRO-VARIABLES CONTENANT LES VARIABLES NUMÉRIQUES RETENUES    ****
  ****   POUR LE CALAGE                                                           ****
  ************************************************************************************/

DATA __MAR40;
     SET __MAR4;
     %IF (&TYP=3 OR &TYP=5 OR &TYP=2B) AND &CAT2>1 %THEN
       %DO I=2 %TO &CAT2;
           IF UPCASE(VAR)="I&I._&&P&I" AND &&P&I>0 THEN DELETE;
       %END;
     %IF (&TYP=4 OR &TYP=5) AND &CAT3>1 %THEN
       %DO J=2 %TO &CAT3;
           IF UPCASE(VAR)="K&J._&&MK&J" AND &&MK&J>0 THEN DELETE;
       %END;
DATA __MAR40N;
     SET __MAR40 (WHERE=(TYPE="N"));
RUN;

%NOBSS(__MAR40N,LLB);

DATA _NULL_;
     SET __MAR40N;
     J=PUT(_N_,4.);   /* <- !!! MODIFICATION DU 26/02/2009 : 9999 variables numériques possibles */
     MAC=COMPRESS("VNN"!!J);
     CALL SYMPUT (MAC,VAR);
RUN;

 /***************************************************************************
  **** RÉINTÉGRATION DES MODALITÉS ORIGINELLES POUR L'ÉDITION DES MARGES ****
  ***************************************************************************/

%LET CM=%SYSFUNC(EXIST(__CODMEN));
%LET CI=%SYSFUNC(EXIST(__CODIND));
%LET CK=%SYSFUNC(EXIST(__CODKIS));

%IF &CI=1 %THEN %DO;
 %LET TI=%SYSFUNC(OPEN(__CODIND));
 %LET MI=%SYSFUNC(VARNUM(&TI,MODAL0));
 %LET TI=%SYSFUNC(CLOSE(&TI));
%END;

%IF &CK=1 %THEN %DO;
 %LET TK=%SYSFUNC(OPEN(__CODKIS));
 %LET MK=%SYSFUNC(VARNUM(&TK,MODAL0));
 %LET TK=%SYSFUNC(CLOSE(&TK));
%END;

PROC SORT DATA=__MAR4;
     BY VAR MODAL2;

%IF (&TYP=1 OR &TYP>=3) AND &CAT1>0 AND &CM=1 %THEN
%DO;
DATA __MAR4;
     MERGE __MAR4  (IN=U)
           __CODMEN (IN=R RENAME=(MODALITE=MODAL2));
     BY VAR MODAL2 ;
        IF U=1 AND R=1 THEN MODALITE=RIGHT(MODAL0);
        IF U=1 THEN OUTPUT;
%END;

%IF &TYP=2 AND &CAT2>0 AND &CI=1 %THEN
%DO;
DATA __MAR4 ;
     MERGE __MAR4  (IN=U)
           __CODIND (IN=R RENAME=(MODALITE=MODAL2));
     BY VAR MODAL2;
        IF U=1 AND R=1 THEN MODALITE=RIGHT(MODAL0);
        IF U=1 THEN OUTPUT;
%END;

%IF (&TYP=3 OR &TYP=5 OR &TYP=2B) AND &CAT2>0 %THEN
%DO;
 %IF &CI=1 %THEN
 %DO;
  PROC SORT DATA=__MAR4;
     BY VAR MODAL2;
  DATA __MAR4 (DROP=VAR0 MODAL0);
     MERGE __MAR4  (IN=U)
           __CODIND (IN=R RENAME=(MODALITE=MODAL2));
     BY VAR;
        IF U=1 AND R=1 THEN DO;
          %IF &MI>0 %THEN
          %DO;
           MODALITE=RIGHT(MODAL0);
          %END;
          %ELSE
          %DO;
           MODALITE=RIGHT(MODAL2);
          %END;
           VAR1=VAR0;
        END;
        IF U=1 THEN OUTPUT;
 %END;
 %ELSE
 %DO;
  DATA __MAR4(DROP=NUMVAR);
       LENGTH NUMVAR $7  VAR1 $32 MODALITE $8;
       SET __MAR4;
           NUMVAR=SUBSTR(SCAN(VAR,1,'_'),2);
           %DO I=1 %TO &NVARI;
               IF NUMVAR="&I" THEN
               DO;
                  VAR1="&&W&I";
                  MODALITE=SUBSTR(SCAN(VAR,2,'_'),1);
                  IF &&P&I=0 THEN MODALITE=' ';
               END;
           %END;
 %END;
%END;

%IF (&TYP=4 OR &TYP=5) AND &CAT3>0 %THEN
%DO;
 %IF &CK=1 %THEN
 %DO;
  PROC SORT DATA=__MAR4;
     BY VAR MODAL2;
  DATA __MAR4 (DROP=VAR0 MODAL0);
     MERGE __MAR4  (IN=U)
           __CODKIS (IN=R RENAME=(MODALITE=MODAL2));
     BY VAR;
        IF U=1 AND R=1 THEN
        DO;
          %IF &MK>0 %THEN
          %DO;
           MODALITE=RIGHT(MODAL0);
          %END;
          %ELSE
          %DO;
           MODALITE=RIGHT(MODAL2);
          %END;
           VAR1=VAR0;
        END;
        IF U=1 THEN OUTPUT;
 %END;
 %ELSE
 %DO;
  DATA __MAR4 (DROP=NUMVAR);
       LENGTH NUMVAR $7  VAR1 $32;
       SET __MAR4;
           NUMVAR=SUBSTR(SCAN(VAR,1,'_'),2);
           %DO I=1 %TO &NVARK;
               IF NUMVAR="&I" THEN
               DO;
                  VAR1="&&K&I";
                  MODALITE=SUBSTR(SCAN(VAR,2,'_'),1);
                  IF &&MK&I=0 THEN MODALITE=' ';
               END;
           %END;
 %END;
%END;

PROC SORT DATA=__MAR4;
     BY NIVEAU TYPE1 VAR1 MODALITE;


   /*  CONTROLE SUR LES EFFECTIFS DES MODALITÉS DES VARIABLES CATÉGORIELLES   */

%IF %UPCASE(&CONT)=OUI AND (&VC1 NE OR &CAT2>0 OR &CAT3>0) %THEN
%DO;

  %LET ERREUR2=0;

  DATA __VERIF;
    SET __MAR4(WHERE=(TYPE1="C"));
    BY VAR1 NOTSORTED;
    RETAIN TOTAL NUMERO 0;
    IF FIRST.VAR1 THEN
    DO;
      TOTAL=0;
      NUMERO=NUMERO+1;
    END;
    TOTAL=TOTAL+ECHANT;
    IF LAST.VAR1 THEN
    DO;
      TOTAL2=TOTAL;
      EFFPOND2=EFFPOND;
      IF ABS(TOTAL-EFFPOND)>0.0001 THEN
      DO;
        ERREUR="*";
        CALL SYMPUT ('ERREUR2','1');
      END;
    END;
  RUN;

  %IF &ERREUR2=1 %THEN
  %DO;

    PROC PRINT DATA=__VERIF SPLIT="*";
      ID VAR1;
      LABEL VAR1="VARIABLE"
            MODALITE="MODALITÉ"
            ECHANT="MARGE*ÉCHANTILLON"
            PCTECH="POURCENTAGE*ÉCHANTILLON"
            TOTAL2="EFFECTIF*CUMULÉ"
            EFFPOND2="EFFECTIF*ÉCHANTILLON"
            ERREUR="ERREUR";
      VAR MODALITE ECHANT PCTECH TOTAL2 EFFPOND2 ERREUR;
      TITLE4  "ERREUR : POUR AU MOINS UNE VARIABLE CATÉGORIELLE, L'EFFECTIF"
              " CUMULÉ (PONDÉRÉ) DES MODALITÉS N'EST PAS ÉGAL";
      TITLE5  "À L'EFFECTIF (PONDÉRÉ) DE L'ÉCHANTILLON";

    DATA __FREQ;
      SET __VERIF (WHERE=(ERREUR="*")  KEEP=VAR1 ERREUR NUMERO);
      MAF="ERR"!!LEFT(PUT(_N_,3.));
      CALL SYMPUT(MAF,VAR1);
    RUN;

    %NOBSS(__FREQ,NBVER)

    PROC FREQ DATA=__CALAGE(WHERE=(ELIM=0));
      TABLES %DO K=1 %TO &NBVER; &&ERR&K %END;
       %STR(;);
      WEIGHT &POIDS;
      TITLE4 "LES EFFECTIFS (PONDÉRÉS) DES MODALITÉS DES VARIABLES CATÉGORIELLES"
           " EN ERREUR";
    RUN;
    TITLE4;
    %GOTO FFIN;
  %END;

%END;

   /*  FIN DU CONTROLE  */


   /**************************************************************************
    * AVERTISSEMENT SI MÉTHODE=SINH ET PRÉSENCE DE NON-RÉPONSE NON REDRESSÉE *
    **************************************************************************/

%IF &M=5 AND %UPCASE(&NONREP)=NON AND &GAMMA=1 AND &EFFPOND<&EFFPOP %THEN
%DO;
  DATA _NULL_;
      FILE PRINT;
      PUT //  @2 77*"*";
      PUT @2 "* ATTENTION : LA SOMME DES POIDS INITIAUX (&EFFPOND) EST INFÉRIEURE" @78 "*";
      PUT @2 "*             À LA TAILLE DE LA POPULATION (&EFFPOP)"                @78 "*";
      PUT @2 "*             LA NON-RÉPONSE N'EST DONC PAS REDRESSÉE"               @78 "*";
      PUT @2 "*"                                                                   @78 "*";
      PUT @2 "* VOUS UTILISEZ LA FONCTION SINUS-HYPERBOLIQUE (M VAUT 5)"           @78 "*";
      PUT @2 "* SANS REDRESSER LA NON-RÉPONSE (ECHELLE VAUT 1 ET NONREP VAUT NON)" @78 "*";
      PUT @2 "*"                                                                   @78 "*";
      PUT @2 "* VOS RÉSULTATS (POIDS APRÈS CALAGE ET ESTIMATEURS DES VARIABLES D'ENQUÊTE) *";
      PUT @2 "* SERONT DIFFÉRENTS DE CEUX OBTENUS SUR UN FICHIER REDRESSÉ"         @78 "*";
      PUT @2 77*"*";
%END;

 /***************************************************************************************
  * AVERTISSEMENT SI MÉTHODE=SINH ET FACTEUR D'ÉCHELLE DIFFÉRENT DE N/(SOMME DES POIDS) *
  ***************************************************************************************/

%IF &M=5 AND %UPCASE(&NONREP)=NON AND &GAMMA NE 1 AND &EFFPOND NE &EFFPOP %THEN
%DO;
  DATA _NULL_;
      FILE PRINT;
      PUT // @2 77*"*";
      PUT @2 "* ATTENTION : LA SOMME DES POIDS INITIAUX (&EFFPOND) N'EST PAS ÉGALE" @78 "*";
      PUT @2 "*             À LA TAILLE DE LA POPULATION (&EFFPOP)"                 @78 "*";
      PUT @2 "*             LA NON-RÉPONSE EST REDRESSÉE UNIFORMÉMENT PAR LE PARAMÈTRE" @78 "*";
      PUT @2 "*             ECHELLE=&ECHELLE"                                       @78 "*";
      PUT @2 "*"                                                                    @78 "*";
      PUT @2 "* VOUS UTILISEZ LA FONCTION SINUS-HYPERBOLIQUE (M VAUT 5)"            @78 "*";
      PUT @2 "*"                                                                    @78 "*";
      PUT @2 "* VOS RÉSULTATS (POIDS APRÈS CALAGE ET ESTIMATEURS DES VARIABLES D'ENQUÊTE) *";
      PUT @2 "* SERONT DIFFÉRENTS DE CEUX OBTENUS SUR UN FICHIER REDRESSÉ PAR LE RAPPORT:" @78 "*";
      PUT @2 "* (TAILLE DE LA POPULATION)/(SOMME DES POIDS INITIAUX)"               @78 "*";
      PUT @2 77*"*";
%END;

   /**********************************************************
    ***  IMPRESSION DES MARGES (POPULATION ET ÉCHANTILLON) ***
    **********************************************************/

%IF &EDITION>=2 OR &PB1=1 %THEN
%DO;

PROC PRINT DATA=__MAR4 SPLIT="*";
 %IF &TYP=2B %THEN
 %DO;
  WHERE COMPRESS(VAR) NE 'MU';
 %END;
  BY VAR1 NOTSORTED;
  ID VAR1;
  LABEL VAR1="VARIABLE"
        MODALITE="MODALITÉ"
        ECHANT="MARGE*ÉCHANTILLON"
        PCTECH="POURCENTAGE*ÉCHANTILLON"
        MARGE="MARGE*POPULATION"
        PCTMARGE="POURCENTAGE*POPULATION"
        ERR="EFFECTIF*NUL";
  VAR MODALITE ECHANT MARGE PCTECH PCTMARGE
  %IF &PB1=1 %THEN %DO; ERR %END;
  %STR(;);
  FORMAT PCTECH PCTMARGE 6.2;
  TITLE4  "COMPARAISON ENTRE LES MARGES TIRÉES DE L'ÉCHANTILLON (AVEC LA"
          " PONDÉRATION INITIALE)";
  TITLE5  "ET LES MARGES DANS LA POPULATION (MARGES DU CALAGE)";

  %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
  %DO;
    TITLE7 "ATTENTION : LA PONDÉRATION UTILISÉE ICI EST ÉGALE AU POIDS INITIAL";
    TITLE8 "MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
  %END;
  %IF &PB1=1 %THEN
  %DO;
    TITLE9 "ERREUR : L'EFFECTIF D'UNE MODALITÉ (AU MOINS) D'UNE VARIABLE"
           " CATÉGORIELLE EST NUL";
    TITLE10 "ALORS QUE LA MARGE CORRESPONDANTE EST NON NULLE : LE CALAGE EST "
            "IMPOSSIBLE";
  %END;
RUN;
TITLE4;TITLE5;TITLE7;TITLE8;TITLE9;TITLE10;

%END;

%IF &PB1=1 %THEN %GOTO FFIN;


   /***************************************************************
    **** CRÉATION DE LA TABLE  __COEFF ET DES MACROS VARIABLES  ***
    ***  CONTENANT LES COEFFICIENTS DU VECTEUR LAMBDA
    ***************************************************************/

DATA __COEFF;
  LENGTH NOM $8 VAR $ 32;
  %DO J=1 %TO &JJ;
    %DO I=1 %TO &&N&J;
      VAR="&&VC&J";
      LAMBDA=0;
      NOM="C&J._&I";
      CALL SYMPUT(NOM,PUT(LAMBDA,12.));
      OUTPUT;
    %END;
  %END;

  %DO L=1 %TO &LLB;
      VAR="&&VNN&L";
      LAMBDA=0;
      NOM="CC&L";
      CALL SYMPUT(NOM,PUT(LAMBDA,12.));
      OUTPUT;
  %END;

RUN;

   /*  TITRE 3  */

 %IF &M=1 %THEN %DO; TITLE3 "MÉTHODE : LINÉAIRE " %STR(;); %END;
 %IF &M=2 %THEN %DO; TITLE3 "MÉTHODE : RAKING RATIO" %STR(;); %END;
 %IF &M=3 %THEN %DO; TITLE3 "MÉTHODE : LOGIT, INF=&LO, SUP=&UP" %STR(;); %END;
 %IF &M=4 %THEN %DO; TITLE3 "MÉTHODE : LINÉAIRE TRONQUÉE, INF=&LO, SUP=&UP" %STR(;); %END;
 %IF &M=5 %THEN %DO; TITLE3 "MÉTHODE : SINUS HYPERBOLIQUE"  %STR(;); %END;

RUN;

   /**************************************************
    ***********                            ***********
    ***********    DEBUT DES ITERATIONS    ***********
    ***********                            ***********
    **************************************************/

%DO %WHILE(&MAXDIF>&SEUIL);
%LET NITER=%EVAL(&NITER+1);

%IF &MAXITER=%EVAL(&NITER-1) %THEN
%DO;
  DATA _NULL_;
    FILE PRINT;
    PUT //@10 "*************************************************************";
    PUT   @10 "***   LE NOMBRE MAXIMUM D'ITÉRATIONS (&MAXITER) A ÉTÉ ATTEINT"
          @68 "***";
    PUT   @10 "***   SANS QU'IL Y AIT CONVERGENCE                        ***";
    PUT   @10 "*************************************************************";
    CALL SYMPUT('ARRET','1');
    CALL SYMPUT('MAXIT','1');
    %GOTO ARRET;
%END;

   /*  CALCUL DU VECTEUR PHI  */

%IF &POINEG=0 AND &NITER>1 %THEN
%DO;
  PROC MEANS DATA=__CALAGE
  %IF &NITER=1 %THEN
  %DO;
    (WHERE=(ELIM=0))
  %END;
  NOPRINT;
    VAR  %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
         %DO L=1 %TO &LL; &&VN&L   %END;
    %STR(;);
    WEIGHT __WFIN;
    OUTPUT OUT=__PHI SUM=;
%END;

%IF &POINEG=1 %THEN
%DO;
  PROC MEANS DATA=__CALAGE NOPRINT;
    VAR  %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Z&J._&I %END; %END;
         %DO L=1 %TO &LL; _Z&L   %END;
    %STR(;);
    WEIGHT __WFIN;
    OUTPUT OUT=__PHI SUM=
       %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
       %DO L=1 %TO &LL; &&VN&L   %END;
  %STR(;);
%END;

   /*  CALCUL DU "TABLEAU DE BURT"= MATRICE PHIPRIM  */

PROC CORR DATA=__CALAGE
  %IF &NITER=1 %THEN
  %DO;
    (WHERE=(ELIM=0))
  %END;
  NOPRINT NOCORR SSCP OUT=__BURT(TYPE=SSCP);

 %IF %UPCASE(&NONREP) NE OUI %THEN
 %DO;
  VAR %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
      %DO L=1 %TO &LLB; &&VNN&L %END; %STR(;);
 %END;

 %ELSE
 %DO;
  VAR &ZZ2;
 %END;
  WITH %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
       %DO L=1 %TO &LLB; &&VNN&L %END; %STR(;);
  WEIGHT __POIDS;
RUN;

%IF &SYSERR NE 0 %THEN                /*   CAS DE "FLOATING POINT OVERFLOW"   */
%DO;
  %PUT ********************************************************************;
  %PUT ***   LE CALAGE NE PEUT ETRE RÉALISÉ. POUR RENDRE LE CALAGE      ***;
  %PUT ***   POSSIBLE, VOUS POUVEZ :                                    ***;
  %PUT ***                                                              ***;
  %IF &M=3 OR &M=4 %THEN
  %DO;
  %PUT ***   - DIMINUER LA VALEUR DE LO                                 ***;
  %PUT ***   - AUGMENTER LA VALEUR DE UP                                ***;
  %END;
  %IF &M=5 %THEN
  %DO;
  %PUT ***   - DIMINUER LA VALEUR DE ALPHA                              ***;
  %END;
  %IF &M=2 OR &M=3 OR &M=4 OR &M=5 %THEN
  %DO;
  %PUT ***   - UTILISER LA MÉTHODE LINÉAIRE (M=1)                       ***;
  %END;
  %IF &VC1 NE %THEN
  %DO;
  %PUT ***   - OPÉRER DES REGROUPEMENTS DE MODALITÉS DE VARIABLES       ***;
  %PUT ***     CATÉGORIELLES                                            ***;
    %IF &EFFPOND NE &EFFPOP %THEN
    %DO;
  %PUT ***   - CHANGER LA VARIABLE DE PONDÉRATION INITIALE, CAR         ***;

  %PUT ***     L EFFECTIF PONDÉRÉ DE L ÉCHANTILLON VAUT &EFFPOND ;
  %PUT ***     ALORS QUE L EFFECTIF DE LA POPULATION VAUT &EFFPOP ;

    %END;
  %END;
  %PUT ********************************************************************;
  %GOTO FFIN;
%END;

   /*******************************
    ***  ON ENTRE DANS IML ...  ***
    *******************************/

PROC IML;
*RESET PRINT;

%IF &NITER=1 %THEN                 /*  ON CONSTRUIT LE VECTEUR DES MARGES TX  */
%DO;
  USE __MAR40;
  READ ALL VAR { MARGE } INTO MARGES;
  %IF &&VC1 NE %THEN               /*  SUPPRESSION DES MARGES "REDONDANTES"  */
  %DO;
    TX=MARGES[1:&M1,]
    %DO P=2 %TO &JJ;
      %LET PP=%EVAL(&P-1);
      %LET PPP=%EVAL(&PP-1);
      // MARGES[ %DO Q=1 %TO &PP;
                     &&N&Q +
                  %END;
      &PP: %DO Q=1 %TO &P;
             &&N&Q +
           %END;
      &PPP,]
    %END;
    %IF &LLB NE 0 %THEN
    %DO;
      // MARGES[ &M1
        %DO J=2 %TO &JJ ;
          + &&M&J
        %END;
        + 1 : &M1
        %DO J=2 %TO &JJ ;
          + &&M&J
        %END;
        + &LLB,]
    %END;
    %STR(;);
  %END;
  %IF &&VC1 = %THEN
  %DO;
    TX=MARGES;
  %END;
  STORE TX;
%END;

  USE __BURT;                            /*  ON CONSTRUIT LA MATRICE PHIPRIM  */
  READ POINT 1;
  READ AFTER WHERE(_TYPE_="SSCP") VAR
  %IF %UPCASE(&NONREP)=NON %THEN
   %DO;
    {    %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
         %DO L=1 %TO &LLB; &&VNN&L   %END;        }
   %END;
  %ELSE
   %DO;
    { &ZZ2 }
   %END;
      INTO PHIPRIM;
  %IF %UPCASE(&COLIN)=OUI %THEN
  %DO;
    INVERSE=GINV(PHIPRIM);
  %END;
  %ELSE
  %DO;
    INVERSE=INV(PHIPRIM);
  %END;
  FREE PHIPRIM;

  IF NCOL(INVERSE)=0 THEN            /*  CAS OÙ PHIPRIM N'EST PAS INVERSIBLE  */
  DO;
    CALL SYMPUT('PBIML','1');
  END;

  ELSE                               /*  CAS OÙ PHIPRIM EST INVERSIBLE  */
  DO;

  USE __PHI;                                 /*  ON CONSTRUIT LE VECTEUR PHI  */
  READ ALL  VAR
  {    %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
       %DO L=1 %TO &LLB; &&VNN&L   %END;        }
       INTO PHI;
  PHI=T(PHI);

  %IF &NITER>1 %THEN
  %DO;
    LOAD TX;
  %END;

  USE __COEFF;                      /*  ON CALCULE LE NOUVEAU VECTEUR LAMBDA  */
  READ ALL VAR "LAMBDA" INTO LAMBDA;
  LAMBDA=LAMBDA+INVERSE*(TX-PHI);
  EDIT __COEFF;
  REPLACE ALL VAR "LAMBDA";

  END;

   /***************************
    ***  ... ON SORT D'IML  ***
    ***************************/

   /*   CAS OÙ PHIPRIM N'EST PAS INVERSIBLE : L'ALGORITHME S'ARRETE   */

%IF &PBIML=1 AND &NITER=1 %THEN              /*  SI C'EST LA 1ÈRE ITÉRATION   */
%DO;
  DATA _NULL_;
    FILE PRINT;
    PUT //@10 "******************************************************";
    PUT   @10 "***   LES VARIABLES ANALYSÉES SONT COLINÉAIRES :   ***";
    PUT   @10 "***   LE CALAGE NE PEUT ETRE RÉALISÉ               ***";
    PUT   @10 "***                                                ***";
    PUT   @10 "***   POUR RENDRE LE CALAGE POSSIBLE VOUS POUVEZ   ***";
    PUT   @10 "***   UTILISER L'OPTION : COLIN=OUI                ***";
    PUT   @10 "******************************************************";

                                      /*   RECHERCHE DES LIAISONS LINÉAIRES   */

  PROC PRINCOMP DATA=__CALAGE(WHERE=(ELIM=0)) COV NOINT NOPRINT OUTSTAT=__VECP1;
    VAR %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
        %DO L=1 %TO &LLB; &&VNN&L %END;
        %IF %UPCASE(&NONREP)=OUI %THEN %DO; &ZZ2 %END;
        %STR(;);
    WEIGHT __POIDS;

  PROC TRANSPOSE DATA=__VECP1(WHERE=(_TYPE_="EIGENVAL") DROP=_NAME_)
                 OUT=__VECP2;

  DATA __VECP3;
    MERGE __VECP1(WHERE=(_TYPE_="USCORE")) __VECP2;
    IF COL1=0;
    ARRAY TAB1 %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
               %DO L=1 %TO &LLB; &&VNN&L %END;
               %STR(;);
    ARRAY TAB2 %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; ZY&J._&I %END; %END;
               %DO L=1 %TO &LLB; Z&L %END;
               %STR(;);
    DO OVER TAB1;TAB2=(TAB1=0)*2 + (TAB1 NE 0)*ABS(TAB1);END;
    MINI=MIN(OF %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; ZY&J._&I %END; %END;
                %DO L=1 %TO &LLB; Z&L %END; );
    DO OVER TAB1;TAB1=TAB1/MINI;END;

  PROC PRINT LABEL NOOBS;
    VAR %DO J=1 %TO &JJ; %DO I=1 %TO &&N&J; Y&J._&I %END; %END;
        %DO L=1 %TO &LLB; &&VNN&L %END;
        %IF %UPCASE(&NONREP)=OUI %THEN %DO; &ZZ2 %END; ;
    LABEL %DO J=1 %TO &JJ   ; %DO I=1 %TO &&N&J;   Y&J._&I=&&VC&J &I %END;%END;
          %DO J=1 %TO &CATZ1; %DO I=1 %TO &&MZM&J;ZM&J._&I=&&ZM&J &I %END;%END;
          %DO J=%EVAL(&CATZ1+1) %TO &NZM;         ZM&J._1  =&&ZM&J    %END;
        %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN
        %DO;
          %DO J=1 %TO &CAT2; %DO I=1 %TO &&P&J;    I&J._&I=&&W&J &I  %END;%END;
          %DO J=%EVAL(&CAT2+1) %TO &NVARI;         I&J._1 =&&W&J     %END;
          %DO J=1 %TO &CATZ2; %DO I=1 %TO &&MZI&J;ZI&J._&I=&&ZI&J &I %END;%END;
          %DO J=%EVAL(&CATZ2+1) %TO &NZI;         ZI&J._1  =&&ZI&J    %END;
        %END;
        %IF &TYP>=4 %THEN
        %DO;
          %DO J=1 %TO &CAT3; %DO I=1 %TO &&MK&J;   K&J._&I=&&K&J &I  %END;%END;
          %DO J=%EVAL(&CAT3+1) %TO &NVARK;         K&J._1 =&&K&J &I  %END;
          %DO J=1 %TO &CATZ3; %DO I=1 %TO &&MZK&J;ZK&J._&I=&&ZK&J &I %END;%END;
          %DO J=%EVAL(&CATZ3+1) %TO &NZK;         ZK&J._1  =&&ZK&J    %END;
        %END;
         ;
    TITLE3 "COEFFICIENTS DE LA (OU DES) COMBINAISON(S) LINÉAIRE(S)"
           " NULLE DES VARIABLES DU CALAGE";
    TITLE4 "(UNE VARIABLE DE NOM WXY 2 DÉSIGNE LA VARIABLE INDICATRICE"
           " ASSOCIÉE À LA MODALITÉ 2 DE LA VARIABLE CATÉGORIELLE WXY)";
    RUN;

    %GOTO FFIN;
%END;

%IF &PBIML=1 AND &NITER>1 %THEN       /*  SI CE N'EST PAS LA 1ÈRE ITÉRATION   */
%DO;
  DATA _NULL_;
    FILE PRINT;
 PUT //@5 "*******************************************************************";
 PUT @5   "***   LE CALAGE NE PEUT ETRE RÉALISÉ. POUR RENDRE LE CALAGE     ***";
 PUT @5   "***   POSSIBLE, VOUS POUVEZ :                                   ***";
 PUT @5   "***                                                             ***";
 %IF &M=3 OR &M=4 %THEN
 %DO;
 PUT @5   "***   - DIMINUER LA VALEUR DE LO                                ***";
 PUT @5   "***   - AUGMENTER LA VALEUR DE UP                               ***";
 %END;
 %IF &M=5 %THEN
 %DO;
 PUT @5   "***   - DIMINUER LA VALEUR DE ALPHA                             ***";
 %END;
 %IF &M=2 OR &M=3 OR &M=4 OR &M=5 %THEN
 %DO;
 PUT @5   "***   - UTILISER LA MÉTHODE LINÉAIRE (M=1)                      ***";
 %END;
 %IF &VC1 NE %THEN
 %DO;
 PUT @5   "***   - OPÉRER DES REGROUPEMENTS DE MODALITÉS DE VARIABLES      ***";
 PUT @5   "***     CATÉGORIELLES                                           ***";
 %IF &EFFPOND NE &EFFPOP %THEN
 %DO;
 PUT @5   "***   - CHANGER LA VARIABLE DE PONDÉRATION INITIALE, CAR        ***";
 PUT @5   "***     L'EFFECTIF PONDÉRÉ DE L'ÉCHANTILLON VAUT &EFFPOND" @69 "***";
 PUT @5   "***     ALORS QUE L'EFFECTIF DE LA POPULATION VAUT &EFFPOP"
     @69  "***";
 %END;
 %END;
 PUT @5   "*******************************************************************";
    CALL SYMPUT('ARRET','1');
    %GOTO ARRET;
%END;

   /*  CONSTRUCTION DE LA TABLE CONTENANT LES RÉCAPITULATIFS DES ITÉRATIONS  */

%IF &NITER=1 %THEN
%DO;
  DATA __RECAP2;
    SET __COEFF(KEEP=LAMBDA NOM VAR RENAME=(LAMBDA=LAMBDA1));
    T=SUBSTR(NOM,1,2);
    N=SUBSTR(NOM,2,1);
%END;
%ELSE
%DO;
  DATA __RECAP2;
    MERGE __RECAP2 __COEFF(KEEP=LAMBDA RENAME=(LAMBDA=LAMBDA&NITER));
%END;

DATA _NULL_;
  SET __COEFF;
  CALL SYMPUT(NOM,PUT(LAMBDA,17.14));
RUN;

   /******************************************
    ***  MISE À JOUR DE LA TABLE __CALAGE  ***
    ******************************************/

%IF %UPCASE(&NONREP)=NON %THEN
%DO;
 DATA __CALAGE;
   SET __CALAGE
   %IF &NITER=1 %THEN %DO; (WHERE=(ELIM=0)) ;_FINIT_=1;  %END;
   %ELSE %DO;  ;_FINIT_=_F_; %END;

    /*  CALCUL DU PRODUIT SCALAIRE X*LAMBDA */

   XLAMBDA = %DO J=1 %TO &JJ;
            + Y&J._1 * &&C&J._1 %DO I=2 %TO &&N&J; + Y&J._&I * &&C&J._&I %END;
            %END;
            %DO L=1 %TO &LLB;  + &&VNN&L * &&CC&L
            %END;
   %STR(;);

   /*  CALCUL DE F(X*LAMBDA)  */

  %IF &M=1 %THEN %DO; _F_=1 + XLAMBDA*&PONDQK; %END;
  %IF &M=2 %THEN %DO; _F_= EXP(XLAMBDA*&PONDQK); %END;
  %IF &M=3 %THEN
  %DO;
    _F_=(&LO*(&UP-1)+&UP*(1-&LO)*EXP( XLAMBDA*&PONDQK
        *(&UP-&LO)/(1-&LO)/(&UP-1)))
        /(&UP-1+(1-&LO)*EXP( XLAMBDA*&PONDQK
        *(&UP-&LO)/(1-&LO)/(&UP-1)))  %STR(;);
  %END;
  %IF &M=4 %THEN
  %DO;
    _SOM_=1+ XLAMBDA*&PONDQK;
    _F_=MAX(&LO,_SOM_)+MIN(&UP,_SOM_)-_SOM_; DROP _SOM_;
  %END;
  %IF &M=5 %THEN
  %DO;
    _F_=0.5*((1/&ALPHA)*LOG(2*&ALPHA*XLAMBDA*&PONDQK+SQRT(4*((&ALPHA*XLAMBDA*&PONDQK)**2)+1))
         +SQRT(4+1/(&ALPHA**2)*(LOG(2*&ALPHA*XLAMBDA*&PONDQK
                                   +SQRT(4*((&ALPHA*XLAMBDA*&PONDQK)**2)+1)))**2))    ;
  %END;

   /*  CALCUL DE F'(X*LAMBDA)  */

  %IF &M=1 %THEN %DO; _FPRIM_=&PONDQK; %END;
  %IF &M=2 %THEN %DO; _FPRIM_=_F_; %END;
  %IF &M=3 %THEN
  %DO;
    _FPRIM_=( ( (&UP-&LO)**2 ) *EXP( XLAMBDA*&PONDQK
            * (&UP-&LO)/(1-&LO)/(&UP-1)))
            /(((&UP-1)+(1-&LO)*EXP( XLAMBDA*&PONDQK
            * (&UP-&LO)/(1-&LO)/(&UP-1)))**2) %STR(;);
  %END;
  %IF &M=4 %THEN %DO; _FPRIM_=(_F_>&LO)*(_F_<&UP); %END;
  %IF &M=5 %THEN
  %DO;
    _FPRIM_=(1/SQRT(4*((&ALPHA*XLAMBDA*&PONDQK)**2)+1))
            *(1+(LOG(2*&ALPHA*XLAMBDA*&PONDQK+SQRT(4*((&ALPHA*XLAMBDA*&PONDQK)**2)+1)))
                /&ALPHA/SQRT(4+1/(&ALPHA**2)*(LOG(2*&ALPHA*XLAMBDA*&PONDQK
                                          +SQRT(4*((&ALPHA*XLAMBDA*&PONDQK)**2)+1)))**2)) ;
  %END;

  __WFIN=&POIDS*&GAMMA*_F_;
  __POIDS=&POIDS*&GAMMA*_FPRIM_*&PONDQK;
  DIF=ABS(_FINIT_-_F_);
  POINEG=(__WFIN<0);

   /*  CAS OÙ IL PEUT EXISTER DES POIDS NÉGATIFS  */

%IF &M=1 OR &M=5 OR (&M=3 AND %INDEX(&LO,-) NE 0) OR (&M=4 AND %INDEX(&LO,-) NE 0) %THEN
%DO;
  __ZWFIN=__WFIN;
  ARRAY TAB1 %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
             %DO L=1 %TO &LL; &&VN&L %END; __WFIN __UN
             %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND   %END;
             %IF &TYP=4  OR &TYP=5           %THEN %DO; __KISH  %END; ;
  ARRAY TAB2 %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Z&J._&I %END; %END;
             %DO L=1 %TO &LL; _Z&L %END; __WFIN  __ZUN
             %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __ZIND   %END;
             %IF &TYP=4  OR &TYP=5           %THEN %DO; __ZKISH  %END; ;
  IF __WFIN<0 THEN
  DO;
    DO OVER TAB2;TAB2=-TAB1;END;
  END;
  ELSE
  DO;
    DO OVER TAB2;TAB2= TAB1;END;
  END;
%END;
%END;

%ELSE %IF %UPCASE(&NONREP)=OUI %THEN
%DO;
 PROC IML;                                     /* CALCUL DU VECTEUR Z*LAMBDA */
    USE __CALAGE (WHERE=(ELIM=0));
       READ ALL VAR { &ZZ2 } INTO Z ;
    USE __COEFF ;
       READ ALL VAR  "LAMBDA" INTO BETA  ;
    PRODUIT=Z*BETA ;
    CREATE ZLAMBDA FROM PRODUIT[COLNAME='ZLAMBDA'];
    APPEND FROM PRODUIT;
    FREE BETA Z PRODUIT;
 QUIT;
 DATA __CALAGE;
      MERGE ZLAMBDA __CALAGE
   %IF &NITER=1 %THEN %DO; (WHERE=(ELIM=0)) ;_FINIT_=1;  %END;
   %ELSE %DO; (DROP=ZLAMBDA) ;_FINIT_=_F_; %END;

   /*  CALCUL DE F(Z*LAMBDA)  */

  %IF &M=1 %THEN %DO; _F_=1 + ZLAMBDA*&PONDQK; %END;
  %IF &M=2 %THEN %DO; _F_= EXP(ZLAMBDA*&PONDQK); %END;
  %IF &M=3 %THEN
  %DO;
    _F_=(&LO*(&UP-1)+&UP*(1-&LO)*EXP( ZLAMBDA*&PONDQK
        *(&UP-&LO)/(1-&LO)/(&UP-1)))
        /(&UP-1+(1-&LO)*EXP( ZLAMBDA*&PONDQK
        *(&UP-&LO)/(1-&LO)/(&UP-1)))  %STR(;);
  %END;
  %IF &M=4 %THEN
  %DO;
    _SOM_=1+ ZLAMBDA*&PONDQK;
    _F_=MAX(&LO,_SOM_)+MIN(&UP,_SOM_)-_SOM_; DROP _SOM_;
  %END;
  %IF &M=5 %THEN
  %DO;
    _F_=0.5*((1/&ALPHA)*LOG(2*&ALPHA*ZLAMBDA*&PONDQK+SQRT(4*((&ALPHA*ZLAMBDA*&PONDQK)**2)+1))
         +SQRT(4+1/(&ALPHA**2)*(LOG(2*&ALPHA*ZLAMBDA*&PONDQK
                                   +SQRT(4*((&ALPHA*ZLAMBDA*&PONDQK)**2)+1)))**2))    ;
  %END;

   /*  CALCUL DE F'(Z*LAMBDA)  */

  %IF &M=1 %THEN %DO; _FPRIM_=&PONDQK; %END;
  %IF &M=2 %THEN %DO; _FPRIM_=_F_; %END;
  %IF &M=3 %THEN
  %DO;
    _FPRIM_=( ( (&UP-&LO)**2 ) *EXP( ZLAMBDA*&PONDQK
            * (&UP-&LO)/(1-&LO)/(&UP-1)))
            /(((&UP-1)+(1-&LO)*EXP( ZLAMBDA*&PONDQK
            * (&UP-&LO)/(1-&LO)/(&UP-1)))**2) %STR(;);
  %END;
  %IF &M=4 %THEN %DO; _FPRIM_=(_F_>&LO)*(_F_<&UP); %END;
  %IF &M=5 %THEN
  %DO;
    _FPRIM_=(1/SQRT(4*((&ALPHA*ZLAMBDA*&PONDQK)**2)+1))
            *(1+(LOG(2*&ALPHA*ZLAMBDA*&PONDQK+SQRT(4*((&ALPHA*ZLAMBDA*&PONDQK)**2)+1)))
                /&ALPHA/SQRT(4+1/(&ALPHA**2)*(LOG(2*&ALPHA*ZLAMBDA*&PONDQK
                                          +SQRT(4*((&ALPHA*ZLAMBDA*&PONDQK)**2)+1)))**2)) ;
  %END;

  __WFIN=&POIDS*&GAMMA*_F_;
  __POIDS=&POIDS*&GAMMA*_FPRIM_*&PONDQK;
  DIF=ABS(_FINIT_-_F_);
  POINEG=(__WFIN<0);

   /*  CAS OÙ IL PEUT EXISTER DES POIDS NÉGATIFS  */

%IF &M=1 OR &M=5 OR (&M=3 AND %INDEX(&LO,-) NE 0) OR (&M=4 AND %INDEX(&LO,-) NE 0) %THEN
%DO;
  __ZWFIN=__WFIN;
  ARRAY TAB1 %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
             %DO L=1 %TO &LL; &&VN&L %END; __WFIN __UN
             %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND   %END;
             %IF &TYP=4  OR &TYP=5           %THEN %DO; __KISH  %END; ;
  ARRAY TAB2 %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Z&J._&I %END; %END;
             %DO L=1 %TO &LL; _Z&L %END; __WFIN  __ZUN
             %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __ZIND  %END;
             %IF &TYP=4  OR &TYP=5           %THEN %DO; __ZKISH %END; ;
  IF __WFIN<0 THEN
  DO;
    DO OVER TAB2;TAB2=-TAB1;END;
  END;
  ELSE
  DO;
    DO OVER TAB2;TAB2= TAB1;END;
  END;
%END;
%END;

   /*  CALCUL DU CRITÈRE D'ARRET  */

PROC MEANS DATA=__CALAGE NOPRINT;
  VAR DIF POINEG;
  OUTPUT OUT=__TESTER MAX(DIF)=TEST SUM(POINEG)=POIDSNEG;

DATA _NULL_;
  SET __TESTER;
  IF POIDSNEG>0 THEN
  DO;
    CALL SYMPUT('POINEG','1');
  END;
RUN;

PROC APPEND BASE=__RECAP1 DATA=__TESTER;

DATA _NULL_;
  SET __TESTER;
  CALL SYMPUT('MAXDIF',PUT(TEST,7.5));
RUN;

DATA _NULL_;
  FILE LOG;
  PUT /@10 "***************************************************************";
  PUT  @10 "***   VALEUR DU CRITÈRE D'ARRÊT À L'ITÉRATION &NITER : &MAXDIF"
       @70 "***";
  PUT  @10 "***************************************************************";
  PUT /;

%IF NOT (&M=1 OR (&M=3 AND %INDEX(&LO,-) NE 0) OR (&M=4 AND %INDEX(&LO,-) NE 0))
AND &POINEG=1 %THEN
%DO;
  DATA _NULL_;
    FILE PRINT;
 PUT //@5 "*******************************************************************";
 PUT @5   "***   LE CALAGE NE PEUT ETRE RÉALISÉ. POUR RENDRE LE CALAGE     ***";
 PUT @5   "***   POSSIBLE, VOUS POUVEZ :                                   ***";
 PUT @5   "***                                                             ***";
 %IF &M=3 OR &M=4 %THEN
 %DO;
 PUT @5   "***   - DIMINUER LA VALEUR DE LO                                ***";
 PUT @5   "***   - AUGMENTER LA VALEUR DE UP                               ***";
 %END;
 %IF &M=5 %THEN
 %DO;
 PUT @5   "***   - DIMINUER LA VALEUR DE ALPHA                             ***";
 %END;
 %IF &M=2 OR &M=3 OR &M=4 OR &M=5 %THEN
 %DO;
 PUT @5   "***   - UTILISER LA MÉTHODE LINÉAIRE (M=1)                      ***";
 %END;
 %IF &VC1 NE %THEN
 %DO;
 PUT @5   "***   - OPÉRER DES REGROUPEMENTS DE MODALITÉS DE VARIABLES      ***";
 PUT @5   "***     CATÉGORIELLES                                           ***";
 %IF &EFFPOND NE &EFFPOP %THEN
 %DO;
 PUT @5   "***   - CHANGER LA VARIABLE DE PONDÉRATION INITIALE, CAR        ***";
 PUT @5   "***     L'EFFECTIF PONDÉRÉ DE L'ÉCHANTILLON VAUT &EFFPOND" @69 "***";
 PUT @5   "***     ALORS QUE L'EFFECTIF DE LA POPULATION VAUT &EFFPOP"
     @69  "***";
 %END;
 %END;
 PUT //@5 "*******************************************************************";
    CALL SYMPUT('ARRET','1');
    %GOTO ARRET;
%END;


%END;


   /************************************************
    ***********                          ***********
    ***********    FIN DES ITERATIONS    ***********
    ***********                          ***********
    ************************************************/

%ARRET : ;

   /**********************
    ***  LES ÉDITIONS  ***
    **********************/

DATA __RECAP1;
  SET __RECAP1 END=FIN;
  ITER=_N_;
  %IF &POINEG=1 %THEN           /*  RÉCUPÉRATION DU NOMBRE DE POIDS NÉGATIFS  */
  %DO;
    IF FIN THEN
    DO;
      CALL SYMPUT('NPOINEG',LEFT(PUT(POIDSNEG,10.)));
    END;
  %END;


   /*  TABLEAUX RÉCAPITULATIFS DE L'ALGORITHME  */


%IF &EDITION=3 %THEN
%DO;

PROC PRINT DATA=__RECAP1 SPLIT="*";
 ID ITER;
 VAR TEST POIDSNEG;
 LABEL TEST="CRITÈRE*D'ARRÊT"
       POIDSNEG="POIDS*NÉGATIFS"
       ITER="ITÉRATION";
 TITLE4 "PREMIER TABLEAU RÉCAPITULATIF DE L'ALGORITHME :";
 TITLE5 "LA VALEUR DU CRITÈRE D'ARRÊT ET LE NOMBRE DE POIDS NÉGATIFS"
         " APRÈS CHAQUE ITÉRATION";

DATA __RECAP2;
  SET __RECAP2;
  BY T NOTSORTED;
    ARRAY LAMBDA LAMBDA1-LAMBDA&NITER;
  IF LAST.T AND T NE 'CC' AND N NE "1" THEN
  DO;
    OUTPUT;
    DO OVER LAMBDA;LAMBDA=.;END;
    OUTPUT;
  END;
  ELSE IF T="CC" THEN DO;
       OUTPUT;
       %IF "&TYP"="3" OR "&TYP"="5" OR "&TYP"="2B" %THEN
       %DO I=2 %TO &CAT2;
          %LET Q&I=%EVAL(&&P&I-1);
          IF VAR="I&I._&&Q&I" THEN DO ;
             DO OVER LAMBDA;LAMBDA=.;END;
             OUTPUT;
          END;
       %END;
       %IF "&TYP"="4" OR "&TYP"="5" %THEN
       %DO J=2 %TO &CAT3;
          %LET R&J=%EVAL(&&MK&J-1);
          IF VAR="K&J._&&R&J" THEN DO ;
             DO OVER LAMBDA;LAMBDA=.;END;
             OUTPUT;
          END;
       %END;
  END;
  ELSE OUTPUT;

PROC SORT DATA=__MAR4;
     BY TYPE J MODAL2;

DATA __RECAP2;
   MERGE __MAR4(KEEP=VAR1 MODALITE TYPE1 TYPE NIVEAU)
         __RECAP2 (KEEP=LAMBDA1-LAMBDA&NITER);
   %IF &TYP=1 OR &TYP=2 %THEN %DO;
       IF TYPE="N" THEN MODALITE=" ";
   %END;
   %ELSE %IF &TYP>=3 OR &TYP=2B %THEN %DO;
         %DO I=1 %TO &NVARM;
             IF UPCASE(VAR1)=UPCASE("&&V&I") AND &&MM&I=0 THEN MODALITE=' ';
         %END;
         %IF &TYP=3 OR &TYP=5 OR &TYP=2B %THEN %DO I=1 %TO &NVARI;
             IF UPCASE(VAR1)=UPCASE("&&W&I") AND &&P&I=0 THEN MODALITE=' ';
         %END;
         %IF &TYP=4 OR &TYP=5 %THEN %DO I=1 %TO &NVARK;
             IF UPCASE(VAR1)=UPCASE("&&K&I") AND &&MK&I=0 THEN MODALITE=' ';
         %END;
    %END;
PROC SORT DATA=__RECAP2;
     BY NIVEAU TYPE1 VAR1 MODALITE;
PROC PRINT LABEL DATA=__RECAP2 (DROP=NIVEAU TYPE TYPE1)  ;
  %IF &TYP=2B %THEN %DO;
   WHERE COMPRESS(VAR1) NE 'MU';
  %END;
   ID VAR1;
   LABEL VAR1="VARIABLE"
         MODALITE="MODALITÉ";
   TITLE4 "DEUXIÈME TABLEAU RÉCAPITULATIF DE L'ALGORITHME :";
   TITLE5 "LES COEFFICIENTS DU VECTEUR LAMBDA DE MULTIPLICATEURS DE LAGRANGE"
          " APRÈS CHAQUE ITÉRATION";
RUN;
TITLE4;

%END;

%IF &ARRET=1 %THEN %GOTO FFIN;

   /*  IMPRESSION DES MARGES FINALES  */

%IF &POINEG=0 %THEN
%DO;
  PROC MEANS DATA=__CALAGE NOPRINT;
    VAR  %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND   %END;
         %IF &TYP=4  OR &TYP=5           %THEN %DO; __KISH  %END;
        __UN
        %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Y&J._&I %END; %END;
        %DO L=1 %TO &LL; &&VN&L   %END;
    %STR(;);
    WEIGHT __WFIN;
    OUTPUT OUT=__PHI SUM=;
%END;

%IF &POINEG=1 %THEN
%DO;
  PROC MEANS DATA=__CALAGE NOPRINT;
    VAR   %IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __ZIND   %END;
          %IF &TYP=4  OR &TYP=5           %THEN %DO; __ZKISH  %END;
          __ZUN
          %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J; Z&J._&I %END; %END;
          %DO L=1 %TO &LL; _Z&L   %END;
    %STR(;);
    WEIGHT __WFIN;
    OUTPUT OUT=__PHI SUM=%IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO; __IND   %END;
                         %IF &TYP=4  OR &TYP=5           %THEN %DO; __KISH  %END;
                                                                    __UN
                         %DO J=1 %TO &JJ; %DO I=1 %TO &&M&J;        Y&J._&I %END; %END;
                         %DO L=1 %TO &LL;                           &&VN&L  %END;
  %STR(;);
%END;

%IF &TYP=2B OR &TYP>=3 %THEN
%DO;
   DATA _NULL_;
      SET __PHI;
        %IF &TYP NE 4        %THEN %DO; CALL SYMPUT('EFIND2',LEFT(PUT(__IND,8.)));   %END;
        %IF &TYP=4 OR &TYP=5 %THEN %DO; CALL SYMPUT('EFKISH2',LEFT(PUT(__KISH,8.))); %END;
   RUN;
%END;

PROC TRANSPOSE DATA=__PHI OUT=__PHI2;

DATA __PHI2;
  SET __PHI2(FIRSTOBS=
              %IF &TYP=1 OR &TYP=2 %THEN %DO;                  3 %END;
              %ELSE %IF &TYP=2B OR &TYP=3 OR &TYP=4 %THEN %DO; 4 %END;
              %ELSE %IF &TYP=5 %THEN %DO;                      5 %END;
             RENAME=(COL1=ECHANT));
  RETAIN EFFPOND;
  IF _N_=1 THEN EFFPOND=ECHANT;

%LET PB=0;

DATA __MAR5;
  LENGTH VAR1 $32. MODALITE $8.;
  MERGE __PHI2(FIRSTOBS=2) __MAR3(WHERE=(MARGE NE .))
        __MAR4(KEEP=MODALITE VAR1);
  %IF &EFIND2 NE %STR( ) %THEN
  %DO;
    IF NIVEAU='2' THEN EFFPOND=&EFIND2;
  %END;
  %IF &EFKISH2 NE %STR( ) %THEN
  %DO;
   IF NIVEAU='3' THEN EFFPOND=&EFKISH2;
  %END;
  PCTECH=ECHANT/EFFPOND*100;
  IF TYPE1="N" THEN PCTECH=.;
  ERREUR=" ";
  IF ABS(MARGE-ECHANT) > 0.00001  THEN
  DO;
    ERREUR="*";
    CALL SYMPUT('PB','1');
  END;
RUN;

PROC SORT;
     BY NIVEAU TYPE1 VAR1 MODALITE;


%IF &PB=1 %THEN %DO;
  DATA _NULL_;
    FILE PRINT;
    PUT //@10 "***************************************************************";
    PUT   @10 "***   ATTENTION : L'ALGORITHME A CONVERGÉ, MAIS LE CALAGE   ***";
    PUT   @10 "***               N'EST PAS PARFAITEMENT RÉALISÉ            ***";
    PUT   @10 "***************************************************************";
%END;


%IF &EDITION>=2 OR &PB=1 %THEN
%DO;

PROC PRINT DATA=__MAR5 SPLIT="*";
 %IF &TYP=2B %THEN
 %DO;
  WHERE COMPRESS(VAR) NE 'MU';
 %END;
  BY VAR1 NOTSORTED;
  ID VAR1;
  LABEL VAR1="VARIABLE"
        MODALITE="MODALITÉ"
        ECHANT="MARGE*ÉCHANTILLON"
        PCTECH="POURCENTAGE*ÉCHANTILLON"
        MARGE="MARGE*POPULATION"
        ERREUR="ERREUR"
        PCTMARGE="POURCENTAGE*POPULATION";
  VAR MODALITE ECHANT MARGE PCTECH PCTMARGE
  %IF &PB=1 %THEN %DO; ERREUR %END;
  %STR(;);
  FORMAT PCTECH PCTMARGE 6.2;
  TITLE4  "COMPARAISON ENTRE LES MARGES FINALES DANS L'ÉCHANTILLON"
          " (AVEC LA PONDÉRATION FINALE)";
  TITLE5 " ET LES MARGES DANS LA POPULATION (MARGES DU CALAGE)";
RUN;

%END;

   /*  S'IL Y A DES POIDS NÉGATIFS, LA VARIABLE __WFIN DOIT ETRE RÉTABLIE  */

%IF &POINEG=1 %THEN
%DO;

  PROC DATASETS NOLIST;
    MODIFY __CALAGE;
    RENAME __WFIN=__ABSPOI __ZWFIN=__WFIN;

%END;

   /*  EDITION DES POIDS  */

%IF %UPCASE(&EDITPOI)=OUI %THEN
%DO;

  %IF &TYP>=2B AND &TYP NE 4 %THEN
  %DO;
    %DO I=1 %TO &CAT2;
     %DO J=1 %TO &&P&I;
         %LOCAL OI&I._&J;
	 %END;
	%END;

    DATA _NULL_ ;
	     SET __CODIND;
		 %DO I=1 %TO &CAT2;
		   IF UPCASE(VAR0)="%UPCASE(%TRIM(&&W&I))" THEN 
           DO;
		     I=&I;
             MACM='OI'!!trim(left(i))!!'_'!!trim(left(modalite));
             CALL SYMPUT(MACM,MODAL0);
		   END;
		 %END;
    RUN;
  %END;

  %IF &TYP>=4 %THEN
  %DO;
    %DO I=1 %TO &CAT3;
     %DO J=1 %TO &&mk&I;
         %LOCAL OK&I._&J;
	 %END;
	%END;
    DATA _NULL_;
	     SET __CODKIS;
		 %DO I=1 %TO &CAT3;
		   IF UPCASE(VAR0)="%UPCASE(%TRIM(&&K&I))" THEN 
           DO;
		     I=&I;
             MACM='OK'!!trim(left(i))!!'_'!!trim(left(modalite));
             CALL SYMPUT(MACM,modal0);
		   END;
		 %END;
    RUN;
  %END;

  PROC SUMMARY NWAY DATA=__CALAGE;
    CLASS %IF &TYP NE 2B %THEN %DO J=1 %TO &JJ; _V&J  %END;  
          %DO L=1 %TO &LL; &&VN&L  %END;
    %STR(;);
    VAR  _F_;
    OUTPUT OUT=__SOR MEAN=;

  PROC PRINT DATA=__SOR(DROP=_TYPE_) SPLIT="+";
    LABEL _FREQ_=EFFECTIF+COMBINAISON
          _F_="RAPPORT+DE POIDS"
		  %IF &JJ>0 AND &TYP NE 2B %THEN
		  %DO;
		    %IF &TYP NE 2 %THEN %DO I=1 %TO &JJ; _V&I="&&V&I" %END;
            %ELSE               %DO I=1 %TO &JJ; _V&I="&&W&I" %END;
		  %END;
          %IF &CAT2>0 AND &TYP NE 2 %THEN %DO I=1 %TO &CAT2;%DO J=1 %TO &&P&I; I&I._&J="&&W&I=&&OI&I._&J"  %END;%END;
          %IF &NUM2>0 %THEN %DO I=%EVAL(&CAT2+1) %TO &NVARI; I&I._1="&&W&I" %END;
          %IF &CAT3>0 %THEN %DO I=1 %TO &CAT3;%DO J=1 %TO &&MK&I; K&I._&J="&&K&I=&&OK&I._&J" %END;%END;
          %IF &NUM3>0 %THEN %DO I=%EVAL(&CAT3+1) %TO &NVARK; K&I._1="&&K&I" %END;
          ;
    TITLE4 "RAPPORTS DE POIDS (PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
    TITLE5 "POUR CHAQUE COMBINAISON DE VALEURS DES VARIABLES";
  %IF &TYP NE 1 AND &TYP NE 2 %THEN 
  %DO;
   FOOTNOTE1 "Lecture : pour les variables de calage de niveau 1, on a dans la colonne 'XXX'";
   FOOTNOTE2 "les valeurs possibles de la variable XXX." ;
   FOOTNOTE3 "Pour les variables de calage de niveau 2 ou Kish, on a dans la colonne 'XXX=A'";
   FOOTNOTE4 "le nombre d'unités de niveau 2 (ou de niveau Kish) par unité primaire vérifiant la modalité A";
   FOOTNOTE5 "de la variable XXX ; sous le titre YY le cumul par unité primaire de la variable numérique YY." ;
  %END;
  RUN;
%END;

   /*  STATISTIQUES SUR LES POIDS  */

TITLE6;FOOTNOTE1;FOOTNOTE2;FOOTNOTE3;FOOTNOTE4;FOOTNOTE5;

%IF %UPCASE(&STAT)=OUI %THEN
%DO;

%IF &IDENT NE %STR( ) %THEN 
%DO;
  PROC DATASETS DDNAME=WORK NOLIST;
     MODIFY __CALAGE;
     INDEX CREATE &IDENT;
%END;

  PROC UNIVARIATE PLOT NORMAL DATA=__CALAGE;
    VAR  _F_  __WFIN;
    LABEL _F_    = "RAPPORT DE POIDS"
          __WFIN = "PONDÉRATION FINALE";
    %IF &IDENT NE %THEN
    %DO;
      ID &IDENT;
    %END;
    TITLE4 "STATISTIQUES SUR LES RAPPORTS DE POIDS"
    " (= PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
    TITLE5 "ET SUR LES PONDÉRATIONS FINALES";
  %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
  %DO;
    TITLE7 "ATTENTION : LA PONDÉRATION INITIALE UTILISÉE ICI AU DÉNOMINATEUR EST ÉGALE" ;
    TITLE8 " AU POIDS INITIAL DE SONDAGE MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
  %END;
  ODS LISTING SELECT BASICMEASURES QUANTILES EXTREMEOBS PLOTS;
  RUN;
  TITLE7;TITLE8;
  ODS LISTING SELECT ALL;

                  /* CALCUL DES RAPPORTS DE POIDS MOYENS PAR MODALITÉ DES VAR.CATÉG. */

 %IF &TYP NE 2 AND &TYP NE 2B AND &CAT1>0 %THEN
 %DO;
    %DO J=1 %TO &CAT1;
      PROC SUMMARY DATA=__CALAGE %IF &J NE &CAT1 %THEN %DO; NWAY %END; ;
           CLASS &&V&J ;
           VAR  _F_;
           OUTPUT OUT=__P&J
                 MEAN= ;
      DATA __P&J(DROP=_TYPE_  &&V&J);
          LENGTH VAR $32 MODALITE $8;
          SET __P&J;
              VAR=UPCASE("&&V&J");
              MODALITE=PUT(&&V&J,8.);
              IF _TYPE_=0 THEN VAR='ENSEMBLE';
    %END;
    DATA __POIMEN __TOTAL;
         SET  %DO J=1 %TO &CAT1;
               __P&J
              %END; ;
              IF VAR='ENSEMBLE' THEN OUTPUT __TOTAL;
              ELSE OUTPUT __POIMEN;
    PROC SORT DATA=__POIMEN;
         BY VAR MODALITE;
   %IF %SYSFUNC(EXIST(__CODMEN)) NE 0 %THEN %DO;
    DATA __POIMEN;
         LENGTH MODAL0 $ 8;
         MERGE __POIMEN (IN=X) __CODMEN ;
         BY VAR MODALITE;
            IF MODAL0 NE ' ' THEN MODALITE=MODAL0;
            IF X=1 THEN OUTPUT;
   %END;
    DATA __POIMEN;
         SET __POIMEN __TOTAL;
    PROC PRINT DATA=__POIMEN LABEL SPLIT="+";
       TITLE4 "RAPPORTS DE POIDS MOYENS (PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
       TITLE5 "POUR CHAQUE VALEUR DES VARIABLES";
  %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
  %DO;
    TITLE7 "ATTENTION : LA PONDÉRATION INITIALE UTILISÉE ICI AU DÉNOMINATEUR EST ÉGALE" ;
    TITLE8 "AU POIDS INITIAL DE SONDAGE MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
  %END;
       ID VAR;
       VAR MODALITE _FREQ_ _F_;
       LABEL VAR  ="VARIABLE"
             _FREQ_="NOMBRE+D'OBSERVATIONS+DE NIVEAU 1"
             _F_   ="RAPPORT+DE POIDS" ;
    RUN;
    TITLE7 ; TITLE8;
    PROC DATASETS DDNAME=WORK NOLIST;
         DELETE %DO J=1 %TO &NVARM;  __P&J  %END; ;
    QUIT;
 %END;

 %IF &TYP=2 AND &CAT2 >0 %THEN
 %DO;
    %DO J=1 %TO &CAT2;
      PROC SUMMARY DATA=__CALAGE %IF &J NE &CAT2 %THEN %DO; NWAY %END;;
           CLASS &&W&J ;
           VAR  _F_;
           OUTPUT OUT=__P&J
                 MEAN= ;
      DATA __P&J(DROP=_TYPE_  &&W&J);
          LENGTH VAR $32 MODALITE $8;
          SET __P&J;
              VAR=UPCASE("&&W&J");
              MODALITE=PUT(&&W&J,8.);
              IF _TYPE_=0 THEN VAR='ENSEMBLE';
    %END;
    DATA __POIIND __TOTAL;
         SET %DO J=1 %TO &CAT2;
               __P&J
             %END; ;
             IF VAR='ENSEMBLE' THEN OUTPUT __TOTAL;
             ELSE OUTPUT __POIIND;
    PROC SORT DATA=__POIIND;
         BY VAR MODALITE;
    %IF %SYSFUNC(EXIST(__CODIND)) NE 0 %THEN
    %DO;
     DATA __POIIND;
          MERGE __POIIND(IN=X) __CODIND ;
          BY VAR MODALITE;
             IF MODAL0 NE ' ' THEN MODALITE=MODAL0;
             IF X=1 THEN OUTPUT;
    %END;
    DATA __POIIND;
         SET __POIIND __TOTAL;
    PROC PRINT DATA=__POIIND LABEL SPLIT="+";
       TITLE4 "RAPPORTS DE POIDS MOYENS (PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
       TITLE5 "POUR CHAQUE VALEUR DES VARIABLES";
      %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
      %DO;
       TITLE7 "ATTENTION : LA PONDÉRATION INITIALE UTILISÉE ICI AU DÉNOMINATEUR EST ÉGALE" ;
       TITLE8 "AU POIDS INITIAL DE SONDAGE MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
      %END;
       ID VAR;
       VAR MODALITE _FREQ_ _F_;
       LABEL VAR  ="VARIABLE"
             _FREQ_="NOMBRE+D'OBSERVATIONS"
             _F_   ="RAPPORT+DE POIDS" ;
     RUN;
     TITLE7;TITLE8;
    PROC DATASETS DDNAME=WORK NOLIST;
         DELETE %DO J=1 %TO &NVARI;  __P&J  %END; ;
    QUIT;
 %END;

 %IF (&TYP=2B OR &TYP=3 OR &TYP=5) AND &CAT2>0  %THEN
 %DO;
  %IF %INDEX(&DATAIND,.) NE 0 %THEN
   %DO;
       %LET BASEI=%SCAN(&DATAIND,1,.);
       %LET TABI=%SCAN(&DATAIND,2,.);
   %END;
  %ELSE
   %DO;
      %LET BASEI=WORK;
      %LET TABI=&DATAIND;
   %END;
   RUN;
   PROC DATASETS DDNAME=&BASEI NOLIST;
        MODIFY &TABI;
        INDEX CREATE &IDENT;
   QUIT;
   DATA __INDIV2;
        MERGE &DATAIND (KEEP=&IDENT %DO J=1 %TO &CAT2;&&W&J %END;)
              __CALAGE (KEEP=&IDENT _F_ IN=__CAL);
        BY &IDENT;
            IF __CAL=1;
  %DO J=1 %TO &CAT2;
   PROC SUMMARY DATA=__INDIV2 DESCENDING %IF &J NE &CAT2 %THEN %DO; NWAY %END;;
           CLASS &&W&J ;
           VAR  _F_;
           OUTPUT OUT=__P&J
                 MEAN= ;
   DATA __P&J(DROP=_TYPE_  &&W&J);
        LENGTH VAR0 $32 MODALITE $8;
        SET __P&J;
            VAR0=UPCASE("&&W&J");
            MODALITE=PUT(&&W&J,8.);
            IF _TYPE_=0 THEN VAR0='ENSEMBLE';
  %END;
   DATA __POIIND ;
        SET %DO J=1 %TO &CAT2;
             __P&J
            %END; ;
   PROC PRINT DATA=__POIIND LABEL SPLIT="+";
       TITLE4 "RAPPORTS DE POIDS MOYENS (PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
       TITLE5 "POUR CHAQUE VALEUR DES VARIABLES";
     %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
     %DO;
       TITLE7 "ATTENTION : LA PONDÉRATION INITIALE UTILISÉE ICI AU DÉNOMINATEUR EST ÉGALE" ;
       TITLE8 "AU POIDS INITIAL DE SONDAGE MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
     %END;
       ID VAR0;
       VAR MODALITE _FREQ_ _F_;
       LABEL VAR0="VARIABLE"
          _FREQ_="NOMBRE+D'OBSERVATIONS+DE NIVEAU 2"
             _F_="RAPPORT+DE POIDS" ;
     RUN;
     TITLE7;TITLE8;
    PROC DATASETS DDNAME=WORK NOLIST;
         DELETE %DO J=1 %TO &NVARI;  __P&J  %END; ;
    QUIT;
 %END;

 %IF &TYP>=4 AND &CAT3>0 %THEN
 %DO;
   %IF %INDEX(&DATAKISH,.) NE 0 %THEN
   %DO;
       %LET BASEK=%SCAN(&DATAKISH,1,.);
       %LET TABK=%SCAN(&DATAKISH,2,.);
   %END;
   %ELSE %DO;
       %LET BASEK=WORK;
       %LET TABK=&DATAKISH;
   %END;
   RUN;
   PROC DATASETS DDNAME=&BASEK NOLIST;
        MODIFY &TABK;
        INDEX CREATE &IDENT;
   QUIT;
   RUN;
   DATA __KISH2;
        MERGE &DATAKISH (KEEP=&IDENT %DO J=1 %TO &CAT3;&&K&J %END;)
              __CALAGE (KEEP=&IDENT _F_ IN=__CAL);
        BY &IDENT;
           IF __CAL=1;
  %DO J=1 %TO &CAT3;
   PROC SUMMARY DATA=__KISH2 DESCENDING %IF &J NE &CAT3 %THEN %DO; NWAY %END;;
           CLASS &&K&J ;
           VAR  _F_;
           OUTPUT OUT=__P&J
                 MEAN= ;
   DATA __P&J(DROP=_TYPE_  &&K&J);
        LENGTH VAR0 $32 MODALITE $8;
        SET __P&J;
            VAR0=UPCASE("&&K&J");
            MODALITE=PUT(&&K&J,8.);
            IF _TYPE_=0 THEN VAR0='ENSEMBLE';
  %END;
   DATA __POIKIS ;
        SET %DO J=1 %TO &CAT3;
             __P&J
            %END; ;
   PROC PRINT DATA=__POIKIS LABEL SPLIT="+";
       TITLE4 "RAPPORTS DE POIDS MOYENS (PONDÉRATIONS FINALES / PONDÉRATIONS INITIALES)";
       TITLE5 "POUR CHAQUE VALEUR DES VARIABLES";
     %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
     %DO;
       TITLE7 "ATTENTION : LA PONDÉRATION INITIALE UTILISÉE ICI AU DÉNOMINATEUR EST ÉGALE" ;
       TITLE8 "AU POIDS INITIAL DE SONDAGE MULTIPLIÉ PAR LE FACTEUR D'ÉCHELLE &GAMMA";
     %END;
       ID VAR0;
       VAR MODALITE _FREQ_ _F_;
       LABEL VAR0="VARIABLE"
          _FREQ_="NOMBRE+D'INDIVIDUS+KISH"
             _F_="RAPPORT+DE POIDS" ;
    RUN;
    TITLE7;TITLE8;
    PROC DATASETS DDNAME=WORK NOLIST;
         DELETE %DO J=1 %TO &NVARK;  __P&J  %END; ;
    QUIT;
 %END;

%END;

    /*********************************************
     *** STOCKAGE DES POIDS DANS UNE TABLE SAS ***
     *********************************************/

%IF &POIDSFIN NE %THEN
%DO;

 %IF &TYP NE 2 AND &TYP NE 2B %THEN
 %DO;
  %LET EXISTE=NON;

  PROC CONTENTS NOPRINT DATA=&BASE1.._ALL_ OUT=__SOR(KEEP=MEMNAME);

  DATA _NULL_;
    SET __SOR;
    IF MEMNAME="%UPCASE(&TABLE1)" THEN CALL SYMPUT('EXISTE','OUI');
  RUN;
 %END;

 %IF &TYP=2 OR &TYP=2B OR &TYP=3 OR &TYP=5 %THEN
 %DO;
  %LET EXIST2=NON;

  PROC CONTENTS NOPRINT DATA=&BASE2.._ALL_ OUT=__SOR2(KEEP=MEMNAME);

  DATA _NULL_;
    SET __SOR2;
    IF MEMNAME="%UPCASE(&TABLE2)" THEN CALL SYMPUT('EXIST2','OUI');
  RUN;
 %END;

 %IF (&TYP=4 OR &TYP=5) %THEN
 %DO;
  %LET EXIST3=NON;

  PROC CONTENTS NOPRINT DATA=&BASE3.._ALL_ OUT=__SOR3(KEEP=MEMNAME);

  DATA _NULL_;
    SET __SOR3;
    IF MEMNAME="%UPCASE(&TABLE3)" THEN CALL SYMPUT('EXIST3','OUI');
  RUN;
 %END;


%IF &TYP NE 2B AND &TYP NE 2 %THEN
%DO;

DATA __POIDS;
     SET __CALAGE (KEEP=__WFIN &IDENT RENAME=(__WFIN=&POIDSFIN));
     LABEL &POIDSFIN="&LABELPOI ";

  %IF &EXISTE=OUI AND %UPCASE(&MISAJOUR)=OUI %THEN            /*   LA TABLE EXISTE     */
  %DO;                                                        /*  ET EST MISE À JOUR   */
    DATA &DATAPOI;
      MERGE &DATAPOI  __POIDS;
  %END;

  %IF &EXISTE=NON OR (&EXISTE=OUI AND %UPCASE(&MISAJOUR)=NON)  %THEN
  %DO;                                               /*       LA TABLE N'EXISTE PAS     */
    DATA &DATAPOI;                                   /*  OU ELLE N'EST PAS MISE À JOUR  */
         SET __POIDS;
  %END;

%END;

%IF &TYP=2 %THEN
%DO;

DATA __POIDS;
     SET __CALAGE (KEEP=__WFIN &IDENT2 RENAME=(__WFIN=&POIDSFIN));
     LABEL &POIDSFIN="&LABELPOI ";

  %IF &EXIST2=OUI AND %UPCASE(&MISAJOUR)=OUI %THEN            /*   LA TABLE EXISTE     */
  %DO;                                                        /*  ET EST MISE À JOUR   */
    DATA &DATAPOI2;
      MERGE &DATAPOI2  __POIDS;
  %END;

  %IF &EXIST2=NON OR (&EXIST2=OUI AND %UPCASE(&MISAJOUR)=NON)  %THEN
  %DO;                                               /*       LA TABLE N'EXISTE PAS     */
    DATA &DATAPOI2;                                   /*  OU ELLE N'EST PAS MISE À JOUR  */
         SET __POIDS;
  %END;

%END;

%IF &TYP=2B %THEN
%DO;

   DATA __POIDS;
       SET __CALAGE (KEEP=__WFIN &IDENT RENAME=(__WFIN=&POIDSFIN));
       LABEL &POIDSFIN="&LABELPOI ";
   DATA __ID2;
        SET &DATAIND (KEEP=&IDENT &IDENT2);
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __ID2;
        INDEX CREATE &IDENT;
   QUIT;
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __POIDS;
        INDEX CREATE &IDENT;
   QUIT;
   DATA __POIDS;
        MERGE __ID2 __POIDS(IN=P);
        BY &IDENT;
		   IF P=1 THEN OUTPUT;
  %IF &EXIST2=OUI AND %UPCASE(&MISAJOUR)=OUI %THEN            /*   LA TABLE EXISTE     */
  %DO;                                                        /*  ET EST MISE À JOUR   */
    DATA &DATAPOI2;
      MERGE &DATAPOI2  __POIDS;
  %END;

  %IF &EXIST2=NON OR (&EXIST2=OUI AND %UPCASE(&MISAJOUR)=NON)  %THEN
  %DO;                                               /*       LA TABLE N'EXISTE PAS     */
    DATA &DATAPOI2;                                   /*  OU ELLE N'EST PAS MISE À JOUR  */
         SET __POIDS;
  %END;

%END;

%ELSE %IF &TYP=3 OR &TYP=5  %THEN
%DO;

   DATA __ID2;
        SET &DATAIND (KEEP=&IDENT &IDENT2);
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __ID2 ;
        INDEX CREATE &IDENT;
   QUIT;
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __POIDS;
        INDEX CREATE &IDENT;
   QUIT;
   DATA __POIDS2;
        MERGE __ID2 __POIDS(IN=P);
        BY &IDENT;
		   IF P=1 THEN OUTPUT;
  %IF &EXIST2=OUI AND %UPCASE(&MISAJOUR)=OUI %THEN            /*   LA TABLE EXISTE     */
  %DO;                                                        /*  ET EST MISE À JOUR   */
    DATA &DATAPOI2;
      MERGE &DATAPOI2  __POIDS2;
  %END;

  %IF &EXIST2=NON OR (&EXIST2=OUI AND %UPCASE(&MISAJOUR)=NON)  %THEN
  %DO;                                                /*       LA TABLE N'EXISTE PAS     */
    DATA &DATAPOI2;                                   /*  OU ELLE N'EST PAS MISE À JOUR  */
         SET __POIDS2;
  %END;

%END;

%IF (&TYP=4 OR &TYP=5) %THEN
%DO;

   DATA __IDKISH;
        SET &DATAKISH (KEEP=&IDENT &IDENT2 &POIDKISH);
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __IDKISH ;
        INDEX CREATE &IDENT;
   QUIT;
  %IF &TYP=4  %THEN
  %DO;
   PROC DATASETS DDNAME=WORK NOLIST;
        MODIFY __POIDS;
        INDEX CREATE &IDENT;
   QUIT;
  %END;
   DATA __POIDS3(DROP=&POIDKISH);
        MERGE __IDKISH __POIDS(IN=P);
        BY &IDENT;
		   &POIDSKISHFIN=&POIDKISH*&POIDSFIN;
		   LABEL &POIDSKISHFIN="&LABELPOIKISH";
		   IF P=1 THEN OUTPUT;
  %IF &EXIST3=OUI AND %UPCASE(&MISAJOUR)=OUI %THEN            /*   LA TABLE EXISTE     */
  %DO;                                                        /*  ET EST MISE À JOUR   */
    DATA &DATAPOI3;
      MERGE &DATAPOI3  __POIDS3;
  %END;

  %IF &EXIST3=NON OR (&EXIST3=OUI AND %UPCASE(&MISAJOUR)=NON)  %THEN
  %DO;                                                /*       LA TABLE N'EXISTE PAS     */
    DATA &DATAPOI3;                                   /*  OU ELLE N'EST PAS MISE À JOUR  */
         SET __POIDS3;
  %END;

%END;


  %IF %UPCASE(&CONTPOI)=OUI %THEN
  %DO;
    %if &TYP NE 2 AND &TYP NE 2B %then 
    %do; 
       PROC CONTENTS DATA=&DATAPOI;
            TITLE4 "CONTENU DE LA TABLE &DATAPOI CONTENANT LA NOUVELLE"
             " PONDÉRATION &POIDSFIN";
	%end;
    %IF &TYP NE 1 AND &TYP NE 4 %THEN
    %DO;
      PROC CONTENTS DATA=&DATAPOI2;
        TITLE4 "CONTENU DE LA TABLE &DATAPOI2 CONTENANT LA NOUVELLE"
             " PONDÉRATION &POIDSFIN";

    %END;
    %IF &TYP=4 OR &TYP=5 %THEN
    %DO;
      PROC CONTENTS DATA=&DATAPOI3;
        TITLE4 "CONTENU DE LA TABLE &DATAPOI3 CONTENANT LA NOUVELLE"
             " PONDÉRATION &POIDSFIN";

    %END;
  %END;
  RUN;

%END;

    /**************************************
     ***   EDITION DU BILAN DU CALAGE   ***
     **************************************/

%IF &EDITION>=1 %THEN
%DO;

     /*   POUR AVOIR LA DATE EN FRANÇAIS (OU EN CANADIEN FRANÇAIS) ...   */

%LET JOUR = %SUBSTR(&SYSDATE,1,2);
%LET MOIS = %SUBSTR(&SYSDATE,3,3);
%LET AN   = %SUBSTR(&SYSDATE,6,2);
      %IF &MOIS=JAN %THEN %LET MOIS=JANVIER ;
%ELSE %IF &MOIS=FEB %THEN %LET MOIS=FEVRIER ;
%ELSE %IF &MOIS=MAR %THEN %LET MOIS=MARS;
%ELSE %IF &MOIS=APR %THEN %LET MOIS=AVRIL ;
%ELSE %IF &MOIS=MAY %THEN %LET MOIS=MAI ;
%ELSE %IF &MOIS=JUN %THEN %LET MOIS=JUIN ;
%ELSE %IF &MOIS=JUL %THEN %LET MOIS=JUILLET;
%ELSE %IF &MOIS=AUG %THEN %LET MOIS=AOUT ;
%ELSE %IF &MOIS=SEP %THEN %LET MOIS=SEPTEMBRE;
%ELSE %IF &MOIS=OCT %THEN %LET MOIS=OCTOBRE;
%ELSE %IF &MOIS=NOV %THEN %LET MOIS=NOVEMBRE;
%ELSE %IF &MOIS=DEC %THEN %LET MOIS=DECEMBRE;

%IF &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %LET INDECH =%EVAL(&NOBSIND-&INDELI);
%IF &TYP=4  OR &TYP=5           %THEN %LET KISHECH=%EVAL(&NOBSKISH-&KISHELI);


DATA _NULL_;
  FILE PRINT;
  PUT //@20 "*********************";
  PUT   @20 "***     BILAN     ***";
  PUT   @20 "*********************";
  PUT @2 "*";
  PUT @2 "*   DATE : &JOUR &MOIS 20&AN" @40 "HEURE : &SYSTIME";
  PUT @2 "*";
%IF &TYP NE 2 AND &TYP NE 2B %THEN %DO;
  PUT @2 "*" @6 35*"*";
  PUT @2 "*   TABLE EN ENTRÉE : %UPCASE(&DATAMEN)";
  PUT @2 "*" @6 35*"*";
  PUT @2 "*";
  PUT @2 "*   NOMBRE D'OBSERVATIONS DANS LA TABLE EN ENTRÉE  : " @66 "&EFFINIT";
  PUT @2 "*   NOMBRE D'OBSERVATIONS ÉLIMINÉES                : " @66 "&EFFELIM";
  PUT @2 "*   NOMBRE D'OBSERVATIONS CONSERVÉES               : " @66 "&EFFECH";
  PUT @2 "*";
  %IF &PONDGEN=0 %THEN
  %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION : %UPCASE(&POIDS)";
  %END;
  %ELSE
  %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION : TAILLE DE LA POPULATION (&EFFPOP)"
           " / NOMBRE D'OBSERVATIONS (&EFFECH) (GÉNÉRÉE)";
  %END;
  %IF &PONDQK NE __UN AND &PONDQK NE %THEN %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION QK : %UPCASE(&PONDQK)";
  %END;
  PUT @2 "*";

  %IF &CAT1>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES CATÉGORIELLES : &CAT1";
    PUT @2 "*   LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
        " MODALITÉS :";
    PUT @8
     %DO J=1 %TO &CAT1;
          "%CMPRES(&&V&J) (%LEFT(&&MM&J)) "
     %END;  @@;
    PUT /@2 "*";
  %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
  %DO;
    PUT  @2 "*   SOMME DES POIDS INITIAUX "  @64 ": &SPOIDS";
    PUT  @2 "*   SOMME DES POIDS INITIAUX DILATÉS PAR LE FACTEUR D'ÉCHELLE : "
                                             @66 "&EFFPOND";
  %END;
  %ELSE %DO;
    PUT  @2 "*   SOMME DES POIDS INITIAUX "  @64 ": &EFFPOND";
  %END;
    PUT  @2 "*   TAILLE DE LA POPULATION "   @64 ": &EFFPOP";
    PUT  @2 "*";
  %END;

  %IF &NUM1>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES NUMÉRIQUES : &NUM1";
    PUT @2 "*   LISTE DES VARIABLES NUMÉRIQUES :";
       PUT @8
     %DO L=1 %TO &NVARM;
       %IF &&MM&L=0 %THEN %DO;
         "%CMPRES(&&V&L) "
       %END;
     %END;   @@;
    PUT / @2 "*";
  %END;

  %IF %UPCASE(&NONREP)=OUI %THEN
  %DO;
       PUT @2 "* VARIABLES DE NON-REPONSE";
    %IF &CATZ1>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES CATEGORIELLES : &CATZ1";
       PUT @2 "*    LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
              " MODALITÉS :";
       PUT @8 %DO I=1 %TO &CATZ1;"%CMPRES(&&ZM&I) (%LEFT(&&MZM&I))  " %END; ;
    %END;
    %IF &NUMZ1>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES NUMERIQUES : &NUMZ1";
       PUT @2 "*    LISTE DES VARIABLES NUMERIQUES :";
       PUT @8 %DO I=%EVAL(&CATZ1+1) %TO &&NZM;"%CMPRES(&&ZM&I) " %END; ;
    %END;
  %END;

%END;

%IF &TYP=3 OR &TYP=5 OR &TYP=2B %THEN %DO;
  PUT @2 "*";
  PUT @2 "*" @6 35*"*";
  PUT @2 "*   TABLE EN ENTRÉE : %UPCASE(&DATAIND)";
  PUT @2 "*" @6 35*"*";
  PUT @2 "*";
  PUT @2 "*   NOMBRE D'OBSERVATIONS DANS LA TABLE EN ENTRÉE  : " @66 "&NOBSIND";
  PUT @2 "*   NOMBRE D'OBSERVATIONS ÉLIMINÉES                : " @66 "&INDELI";
  PUT @2 "*   NOMBRE D'OBSERVATIONS CONSERVÉES               : " @66 "&INDECH";
  PUT @2 "*";
  %IF &CAT2>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES CATÉGORIELLES : &CAT2";
    PUT @2 "*   LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
        " MODALITÉS :";
    PUT @8
     %DO J=1 %TO &NVARI;
      %IF &&P&J>0 %THEN %DO;
          "%CMPRES(&&W&J) (%LEFT(&&P&J)) "
      %END;
     %END;  @@;
    PUT @2 "*";
   %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
   %DO;
    PUT / @2 "*   SOMME DES POIDS INITIAUX "  @64 ": %TRIM(&EFIND1)";
    PUT   @2 "*   SOMME DES POIDS INITIAUX DILATÉS PAR LE FACTEUR D'ÉCHELLE : "
                                              @66 "%TRIM(&EFIND)";
   %END;
   %ELSE %DO;
    PUT / @2 "*   SOMME DES POIDS INITIAUX "  @64 ": %TRIM(&EFIND)";
   %END;
    PUT   @2 "*   TAILLE DE LA POPULATION "   @64 ": %TRIM(&POPIND)";
    PUT @2 "*";
  %END;

  %IF &NUM2>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES NUMÉRIQUES : &NUM2";
    PUT @2 "*   LISTE DES VARIABLES NUMÉRIQUES :";
       PUT @8
     %DO L=1 %TO &NVARI;
       %IF &&P&L=0 %THEN %DO;
         "%CMPRES(&&W&L) "
       %END;
     %END;   @@;
    PUT / @2 "*";
  %END;

  %IF %UPCASE(&NONREP)=OUI %THEN
  %DO;
       PUT @2 "* VARIABLES DE NON-REPONSE";
    %IF &CATZ2>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES CATEGORIELLES : &CATZ2";
       PUT @2 "*    LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
              " MODALITÉS :";
       PUT @8 %DO I=1 %TO &CATZ2;"%CMPRES(&&ZI&I) (%LEFT(&&MZI&I))  " %END; ;
    %END;
    %IF &NUMZ2>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES NUMERIQUES : &NUMZ2";
       PUT @2 "*    LISTE DES VARIABLES NUMERIQUES :";
       PUT @8 %DO I=%EVAL(&CATZ2+1) %TO &&NZI;"%CMPRES(&&ZI&I) " %END; ;
    %END;
  %END;

%END;

%IF &TYP=4 OR &TYP=5 %THEN %DO;
  PUT @2 "*" @6 35*"*";
  PUT @2 "*   TABLE EN ENTRÉE : %UPCASE(&DATAKISH)";
  PUT @2 "*" @6 35*"*";
  PUT @2 "*";
  PUT @2 "*   NOMBRE D'OBSERVATIONS DANS LA TABLE EN ENTRÉE  : " @66 "&NOBSKISH";
  PUT @2 "*   NOMBRE D'OBSERVATIONS ÉLIMINÉES                : " @66 "&KISHELI";
  PUT @2 "*   NOMBRE D'OBSERVATIONS CONSERVÉES               : " @66 "&KISHECH";
  PUT @2 "*";
  PUT @2 "*   VARIABLE DE PONDÉRATION CONDITIONNELLE         : " @66 "%UPCASE(&POIDKISH)";
  PUT @2 "*   NOMBRE MAXIMUM D'UNITES SECONDAIRES PAR UP     : " @66 "%UPCASE(&NKISH)";
  PUT @2 "*";
  %IF &CAT3>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES CATÉGORIELLES : &CAT3";
    PUT @2 "*   LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
        " MODALITÉS :";
    PUT @8
     %DO J=1 %TO &NVARK;
      %IF &&MK&J>0 %THEN %DO;
          "%CMPRES(&&K&J) (%LEFT(&&MK&J)) "
      %END;
     %END;  @@;
    PUT /@2 "*";
   %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
   %DO;
    PUT / @2 "*   SOMME DES POIDS INITIAUX "             @64 ": %TRIM(&EFKISH1)";
    PUT   @2 "*   SOMME DES POIDS INITIAUX DILATÉS PAR LE FACTEUR D'ÉCHELLE : "
                                                         @66 "%TRIM(&EFKISH)";
   %END;
   %ELSE %DO;                                              /* correction du 30/07/2009 */
    PUT  @2  "*   SOMME DES POIDS INITIAUX "             @64 ": %TRIM(&EFKISH)";   
   %END;
    PUT  @2  "*   TAILLE DE LA POPULATION "              @64 ": %TRIM(&POPKISH)";
    PUT  @2 "*";
  %END;

  %IF &NUM3>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES NUMÉRIQUES : &NUM3";
    PUT @2 "*   LISTE DES VARIABLES NUMÉRIQUES :";
       PUT @8
     %DO L=1 %TO &NVARK;
       %IF &&MK&L=0 %THEN %DO;
         "%CMPRES(&&K&L) "
       %END;
     %END;   @@;
    PUT / @2 "*";
  %END;

  %IF %UPCASE(&NONREP)=OUI %THEN
  %DO;
       PUT @2 "* VARIABLES DE NON-REPONSE";
    %IF &CATZ3>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES CATEGORIELLES : &CATZ3";
       PUT @2 "*    LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
              " MODALITÉS :";
       PUT @8 %DO I=1 %TO &CATZ3;"%CMPRES(&&ZK&I) (%LEFT(&&MZK&I))  " %END; ;
    %END;
    %IF &NUMZ3>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES NUMERIQUES : &NUMZ3";
       PUT @2 "*    LISTE DES VARIABLES NUMERIQUES :";
       PUT @8 %DO I=%EVAL(&CATZ3+1) %TO &&NZK;"%CMPRES(&&ZK&I) " %END; ;
    %END;
  %END;

%END;

%IF &TYP=2 %THEN %DO;
  PUT @2 "*" @6 35*"*";
  PUT @2 "*   TABLE EN ENTRÉE : %UPCASE(&DATAIND)";
  PUT @2 "*" @6 35*"*";
  PUT @2 "*   NOMBRE D'OBSERVATIONS DANS LA TABLE EN ENTRÉE  : " @66 "&EFFINIT";
  PUT @2 "*   NOMBRE D'OBSERVATIONS ÉLIMINÉES                : " @66 "&EFFELIM";
  PUT @2 "*   NOMBRE D'OBSERVATIONS CONSERVÉES               : " @66 "&EFFECH";
  PUT @2 "*";
  %IF &PONDGEN=0 %THEN
  %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION : %UPCASE(&POIDS)";
  %END;
  %ELSE
  %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION : TAILLE DE LA POPULATION (&EFFPOP)"
           " / NOMBRE D'OBSERVATIONS (&EFFECH) (GÉNÉRÉE)";
  %END;
  %IF &PONDQK NE __UN AND &PONDQK NE %THEN %DO;
    PUT @2 "*   VARIABLE DE PONDÉRATION QK : %UPCASE(&PONDQK)";
  %END;
  PUT @2 "*";
  %IF &CAT2>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES CATÉGORIELLES : &CAT2";
    PUT @2 "*   LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
        " MODALITÉS :";
    PUT @8
     %DO J=1 %TO &NVARI;
      %IF &&P&J>0 %THEN %DO;
          "%CMPRES(&&W&J) (%LEFT(&&P&J)) "
      %END;
     %END;  @@;
    PUT /@2 "*";
  %IF &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
  %DO;
    PUT  @2 "*   SOMME DES POIDS INITIAUX "  @64 ": &SPOIDS";
    PUT  @2 "*   SOMME DES POIDS INITIAUX DILATÉS PAR LE FACTEUR D'ÉCHELLE : "
                                             @66 "&EFFPOND";
  %END;
  %ELSE %DO;
    PUT  @2 "*   SOMME DES POIDS INITIAUX "  @64 ": &EFFPOND";
  %END;
    PUT  @2 "*   TAILLE DE LA POPULATION "   @64 ": &EFFPOP";
    PUT  @2 "*";
  %END;

  %IF &NUM2>0 %THEN
  %DO;
    PUT @2 "*   NOMBRE DE VARIABLES NUMÉRIQUES : &NUM2";
    PUT @2 "*   LISTE DES VARIABLES NUMÉRIQUES :";
       PUT @8
     %DO L=1 %TO &NVARI;
       %IF &&P&L=0 %THEN %DO;
         "%CMPRES(&&W&L) "
       %END;
     %END;   @@;
    PUT / @2 "*";
   %END;

  %IF %UPCASE(&NONREP)=OUI %THEN
  %DO;
       PUT @2 "* VARIABLES DE NON-REPONSE";
    %IF &CATZ2>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES CATEGORIELLES : &CATZ2";
       PUT @2 "*    LISTE DES VARIABLES CATÉGORIELLES ET DE LEURS NOMBRES DE"
              " MODALITÉS :";
       PUT @8 %DO I=1 %TO &CATZ2;"%CMPRES(&&ZI&I) (%LEFT(&&MZI&I))  " %END; ;
    %END;
    %IF &NUMZ2>0 %THEN
    %DO;
       PUT @2 "*    NOMBRE DE VARIABLES NUMERIQUES : &NUMZ2";
       PUT @2 "*    LISTE DES VARIABLES NUMERIQUES :";
       PUT @8 %DO I=%EVAL(&CATZ2+1) %TO &&NZI;"%CMPRES(&&ZI&I) " %END; ;
    %END;
  %END;

%END;

  PUT @2 "*";
  PUT @2 "*   MÉTHODE UTILISÉE : "
        %IF &M=1 %THEN %DO; "LINÉAIRE" %END;
  %ELSE %IF &M=2 %THEN %DO; "RAKING RATIO" %END;
  %ELSE %IF &M=3 %THEN %DO; "LOGIT, BORNE INFÉRIEURE = &LO,"
                            " BORNE SUPÉRIEURE = &UP" %END;
  %ELSE %IF &M=4 %THEN %DO; "LINÉAIRE TRONQUÉE,  BORNE INFÉRIEURE = &LO,"
                            "  BORNE SUPÉRIEURE = &UP" %END;
  %ELSE %IF &M=5 %THEN %DO; "SINUS HYPERBOLIQUE,  COEFFICIENT ALPHA = &ALPHA" %END;
  %STR(;);
 %IF %UPCASE(&COLIN)=OUI %THEN
 %DO;
  PUT @2 "*   TRAITEMENT DES COLINÉARITÉS PAR MATRICE INVERSE GÉNÉRALISÉE";
 %END;

      /*   SI TOUT S'EST BIEN PASSÉ   */

  %IF &ARRET=0 %THEN
  %DO;
    %IF &PB=0 %THEN
    %DO;
      PUT @2 "*   LE CALAGE A ÉTÉ RÉALISÉ EN &NITER ITÉRATIONS";
    %END;
    %ELSE
    %DO;
      PUT @2 "*   LE CALAGE N'A PU ETRE RÉALISÉ QU'APPROXIMATIVEMENT"
             " EN &NITER ITÉRATIONS";
    %END;
    %IF &POINEG=1 %THEN
    %DO;
      PUT @2 "*   IL Y A &NPOINEG POIDS NÉGATIFS";
    %END;
    %IF &POIDSFIN NE %THEN
    %DO;
     %IF &TYP NE 2 AND &TYP NE 2B %THEN
     %DO;
       PUT @2 "*   LES POIDS ONT ÉTÉ STOCKÉS DANS LA VARIABLE %UPCASE(&POIDSFIN)"
              " DE LA TABLE %UPCASE(&DATAPOI)";
     %END;
     %IF &TYP=2 OR &TYP=2B %THEN
     %DO;
       PUT @2 "*   LES POIDS ONT ÉTÉ STOCKÉS DANS LA VARIABLE %UPCASE(&POIDSFIN)"
              " DE LA TABLE %UPCASE(&DATAPOI2)";
     %END;
     %IF &TYP=3 OR &TYP=5 %THEN
     %DO;
       PUT @2 "*   ET DE LA TABLE %UPCASE(&DATAPOI2)";
     %END;
     %IF (&TYP=4 OR &TYP=5) %THEN
     %DO;
       PUT @2 "*   ET DE LA TABLE %UPCASE(&DATAPOI3)";
       PUT @2 "*   LES POIDS DES UNITES KISH ONT ÉTÉ STOCKÉS DANS LA VARIABLE %UPCASE(&POIDSKISHFIN)"
              " DE LA TABLE %UPCASE(&DATAPOI3)";
     %END;
	 
    %END;
  %END;

      /*   SI TOUT NE S'EST PAS BIEN PASSÉ   */

  %ELSE
  %DO;
    %IF &MAXIT=1 %THEN
    %DO;
      PUT @2 "*   LE NOMBRE MAXIMUM D'ITÉRATIONS (&MAXITER) A ÉTÉ ATTEINT"
             " SANS QU'IL Y AIT CONVERGENCE";
    %END;
    %ELSE
    %DO;
      PUT @2 "*   LE CALAGE N'A PU ETRE RÉALISÉ";
    %END;
  %END;

%END;

%FFIN : TITLE3;

  %IF (&TYP=2B OR &TYP=3 OR &TYP=5) AND &CAT2>0 AND %UPCASE(&STAT)=OUI %THEN
  %DO;
   PROC DATASETS DDNAME=&BASEI NOLIST;
        MODIFY &TABI;
        INDEX DELETE &IDENT;
   QUIT;
  %END;

  %IF (&TYP=4 OR &TYP=5) AND &CAT3>0 AND %UPCASE(&STAT)=OUI %THEN
  %DO;
   PROC DATASETS DDNAME=&BASEK NOLIST;
        MODIFY &TABK;
        INDEX DELETE &IDENT;
  %END;


PROC DATASETS DDNAME=WORK NOLIST;
  DELETE  __BURT  __COEFF  __LEC1 __MAR1   __CALAGE   ZLAMBDA
          __MAR3 __MAR30 __MAR31  __MAR4   __MAR5  __NOMVAR __PHI __PHI2
          __RECAP1 __RECAP2 __SOR __TESTER  __EFFELI   __POIDS
          __IDENT  __PONDQK  __MARY __VECP1 __VECP2 __VECP3
          __VERIF  __MAR40 __MAR40N __PHIIND __PHIKI __PHI2IN __PHI2KI
          __POIMEN __POIIND __POIKIS __INDIV2 __KISH2  __TOTAL
          __ID2 __IDKISH __POIDS2 __POIDS3 __SOR2 __SOR3;
  QUIT;

RUN;

%MEND CALMAR1;
