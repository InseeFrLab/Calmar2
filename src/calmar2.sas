*************************************************************************************;
**************  CALAGE AVEC RECODIFICATION DES VARIABLES QUALITATIVES  **************;
**************        ET CALAGE SIMULTAN� M�NAGES-INDIVIDUS-KISH       **************;
*************************************************************************************;

%MACRO CALMAR2(NONREP=NON,
               DATAMEN= ,
               MARMEN= ,
               DATAIND= ,
               MARIND= ,
               DATAKISH= ,
               MARKISH= ,
               IDENT= ,
               IDENT2= ,
               POIDS= ,
               POIDKISH= ,
               PONDQK=__UN,
               EGALPOI=,
               DATAPOI= ,
               DATAPOI2= ,
               DATAPOI3= ,
               POIDSFIN= ,
               POIDSKISHFIN= ,
               LABELPOI= ,
               LABELPOIKISH= ,
               MISAJOUR=OUI,
               PCT=NON,
               POPMEN= ,
               POPIND= ,
               POPKISH= ,
               M=1,
               LO= ,
               UP= ,
               ALPHA=1,
               ECHELLE=1,
               SEUIL=0.0001,
               MAXITER=15,
               COLIN=NON,
               OBSELI=NON,
               CONT=OUI,
               EDITION=3,
               EDITPOI=NON,
               STAT=OUI,
               CONTPOI=OUI,
               NOTES=NON,
               TABMEN=__MENAGE,
               TABIND=__INDIV,
               TABKISH=__KISH) / store;

    /********************************************
     ***  EDITION DES PARAM�TRES DE LA MACRO  ***
     ********************************************/

FOOTNOTE1;FOOTNOTE2;FOOTNOTE3;FOOTNOTE4;FOOTNOTE5;

%IF %UPCASE(&NOTES) = OUI %THEN
%DO;
  OPTIONS NOTES;
%END;
%ELSE
%DO;
  OPTIONS NONOTES;
%END;

%IF &EDITION>=1 %THEN
%DO;

DATA _NULL_;
  FILE PRINT;
  PUT //@28 "**********************************";
  PUT   @28 "***   PARAM�TRES DE LA MACRO   ***";
  PUT   @28 "**********************************";
  PUT //@2 "TABLE(S) EN ENTR�E :";
  PUT   @2 " TABLE DE DONN�ES DE NIVEAU 1              DATAMEN   =  %UPCASE(&DATAMEN)";
  PUT   @2 "    IDENTIFIANT DU NIVEAU 1                IDENT     =  %UPCASE(&IDENT)";
  PUT   @2 " TABLE DE DONN�ES DE NIVEAU 2              DATAIND   =  %UPCASE(&DATAIND)";
  PUT   @2 "    IDENTIFIANT DU NIVEAU 2                IDENT2    =  %UPCASE(&IDENT2)";
  PUT   @2 " TABLE DES INDIVIDUS KISH                  DATAKISH  =  %UPCASE(&DATAKISH)";
  PUT   @2 " POND�RATION INITIALE                      POIDS     =  %UPCASE(&POIDS)";
  PUT   @2 " FACTEUR D'�CHELLE                         ECHELLE   =  &ECHELLE";
  PUT   @2 " POND�RATION QK                            PONDQK    =  %UPCASE(&PONDQK)";
  PUT   @2 " POND�RATION KISH                          POIDKISH  =  %UPCASE(&POIDKISH)";
%IF (&DATAIND=  AND &DATAKISH= )OR (&DATAMEN=  AND &DATAKISH= ) %THEN %DO;
  PUT   @2 " �GALIT� DES POIDS DANS UN M�NAGE          EGALPOI   ="
        %IF %UPCASE(&EGALPOI)=OUI %THEN @58 "OUI" ;
		%ELSE                           @58 "NON" ; ;
%END;
  PUT  /@2 "TABLE(S) DES MARGES :";
  PUT   @2 " DE NIVEAU 1                               MARMEN    =  %UPCASE(&MARMEN)";
  PUT   @2 " DE NIVEAU 2                               MARIND    =  %UPCASE(&MARIND)";
  PUT   @2 " DE NIVEAU KISH                            MARKISH   =  %UPCASE(&MARKISH)";
  PUT   @2 " MARGES EN POURCENTAGES                    PCT       =  %UPCASE(&PCT)";
  PUT   @2 " EFFECTIF DANS LA POPULATION :";
  PUT   @2 "  DES �L�MENTS DE NIVEAU 1                 POPMEN    =  &POPMEN";
  PUT   @2 "  DES �L�MENTS DE NIVEAU 2                 POPIND    =  &POPIND";
  PUT   @2 "  DES �L�MENTS KISH                        POPKISH   =  &POPKISH";
%IF %UPCASE(&NONREP)=OUI %THEN
%DO;
  PUT  /@2 "REDRESSEMENT DE LA NON-R�PONSE DEMAND� :   NONREP    =  &NONREP";
%END;
  PUT  /@2 "M�THODE UTILIS�E                           M         =  &M";
  PUT   @2 " BORNE INF�RIEURE                          LO        =  &LO";
  PUT   @2 " BORNE SUP�RIEURE                          UP        =  &UP";
  PUT   @2 " COEFFICIENT DU SINUS HYPERBOLIQUE         ALPHA     =  &ALPHA";
  PUT   @2 " SEUIL D'ARR�T                             SEUIL     =  &SEUIL";
  PUT   @2 " NOMBRE MAXIMUM D'IT�RATIONS               MAXITER   =  &MAXITER";
  PUT   @2 " TRAITEMENT DES COLIN�ARIT�S               COLIN     =  &COLIN";
  PUT  /@2 "TABLE(S) CONTENANT LA POND. FINALE";
  PUT   @2 " DE NIVEAU 1                               DATAPOI       =  %UPCASE(&DATAPOI)";
  PUT   @2 " DE NIVEAU 2                               DATAPOI2      =  %UPCASE(&DATAPOI2)";
  PUT   @2 " DE NIVEAU KISH                            DATAPOI3      =  %UPCASE(&DATAPOI3)";
  PUT   @2 " MISE � JOUR DE(S) TABLE(S) DATAPOI(2)(3)  MISAJOUR      =  %UPCASE(&MISAJOUR)";
  PUT   @2 " POND�RATION FINALE                        POIDSFIN      =  %UPCASE(&POIDSFIN)";
  PUT   @2 " LABEL DE LA POND�RATION FINALE            LABELPOI      =  %UPCASE(&LABELPOI)";
  PUT   @2 " POND�RATION FINALE DES UNITES KISH        POIDSKISHFIN  =  %UPCASE(&POIDSKISHFIN)";
  PUT   @2 " LABEL DE LA POND�RATION KISH              LABELPOIKISH  =  %UPCASE(&LABELPOIKISH)";
  PUT   @2 " CONTENU DE(S) TABLE(S) DATAPOI(2)(3)      CONTPOI       =  %UPCASE(&CONTPOI)";
  PUT  /@2 "�DITION DES R�SULTATS                      EDITION       =  &EDITION";
  PUT   @2 " �DITION DES POIDS                         EDITPOI       =  %UPCASE(&EDITPOI)";
  PUT   @2 " STATISTIQUES SUR LES POIDS                STAT          =  %UPCASE(&STAT)";
  PUT  /@2 "CONTR�LES                                  CONT          =  %UPCASE(&CONT)";
  PUT   @2 "TABLE CONTENANT LES OBS. �LIMIN�ES         OBSELI        =  %UPCASE(&OBSELI)";
  PUT   @2 "NOTES SAS                                  NOTES         =  %UPCASE(&NOTES)";

%END;

%LOCAL ER ERREUR1 ERREUR3 ERRTOT ERMOD EREGAL NOBSMEN NOBSIND NOBSKISH NVARXM NR NVARM NVARI
       NVARK NZM NZI NZK NZ NID ERRPOID NMAX1 NMAX2 NMAX3 NMAX EXPONDQK
       TYP NUM1 NUM2 NUM3 CAT1 CAT2 CAT3 CATZ1 CATZ2 CATZ3 NUMZ1 NUMZ2 NUMZ3
       ZZ0 ZZ1 ZZ2 I J L ;

**************************************************************************;
********       D�TERMINATION DU TYPE DE CALAGE DEMAND�          **********;
**************************************************************************;


      %IF &DATAMEN NE %STR() AND &DATAIND=   %STR() AND &DATAKISH=%STR() %THEN %LET TYP=1;
%ELSE %IF &DATAMEN=   %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR()
                                            AND %UPCASE(&EGALPOI) NE OUI %THEN %LET TYP=2;
%ELSE %IF &DATAMEN=   %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR()
                                            AND %UPCASE(&EGALPOI)=OUI   %THEN %LET TYP=2B;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR() %THEN %LET TYP=3;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND=   %STR() AND &DATAKISH NE %STR()
                                                                         %THEN %LET TYP=4;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND NE %STR() AND &DATAKISH NE %STR()
                                                                         %THEN %LET TYP=5;


 /**************************************************************************
  ******** CONTROLES SUR LES PARAMETRES RENTRES PAR L'UTILISATEUR **********
  **************************************************************************/


  /***** PR�SENCE DES PARAM�TRES LI�S � UNE TABLE DE DONN�ES *******/

%IF &DATAMEN=%STR() AND &DATAIND=%STR() AND &DATAKISH=%STR() %THEN %DO;
DATA _NULL_ ;
     FILE PRINT;
     PUT @8 68*"*";
     PUT @8 "***** ERREUR : AUCUN NOM DE TABLE DE DONN�ES N'EST RENSEIGN� ! *****";
     PUT @8 68*"*";
%GOTO FIN;
%END;

%IF %UPCASE(&EGALPOI)=OUI %THEN 
%DO;
  %LET EREGAL=0;
  %IF &DATAIND= %THEN 
  %DO;
     %LET EREGAL=1;
     DATA _NULL_;
	   FILE PRINT;
	   PUT 93*"*";
	   PUT "** ERREUR : le param�tre DATAIND contenant le nom de la table de donn�es "     
           "de niveau 2" @92 "**";
       PUT "**          n'est pas renseign� alors que le param�tre EGALPOI vaut OUI." 
           @92 "**";
	   PUT "**"  @92 "**";
	   PUT "** EGALPOI=OUI signifie que vous avez un sondage en grappes et que vous "
	       "souhaitez conserver *";
       PUT "** des poids �gaux dans une meme unit� primaire malgr� l'absence de donn�es "
           "au niveau de" @92 "**";
       PUT "** l'unit� primaire. Ce sont les param�tres de niveau 2 qui doivent etre renseign�s" 
           @92 "**";
	   PUT 93*"*";
   %END;
  %IF &MARIND= %THEN 
  %DO;
     %LET EREGAL=1;
     DATA _NULL_;
	   FILE PRINT;
	   PUT 93*"*";
	   PUT "** ERREUR : le param�tre MARIND contenant le nom de la table de marges " 
           "de niveau 2" @92 "**";
       PUT "**          n'est pas renseign� alors que le param�tre EGALPOI vaut OUI." 
           @92 "**";
	   PUT "**"  @92 "**";
	   PUT "** EGALPOI=OUI signifie que vous avez un sondage en grappes et que vous "
	       "souhaitez conserver *";
       PUT "** des poids �gaux dans une meme unit� primaire malgr� l'absence de donn�es "
           "au niveau de" @92 "**";
       PUT "** l'unit� primaire. Ce sont les param�tres de niveau 2 qui doivent etre renseign�s" 
           @92 "**";
	   PUT 93*"*";
   %END;
  %IF &IDENT= %THEN 
  %DO;
     %LET EREGAL=1;
     DATA _NULL_;
	   FILE PRINT;
	   PUT @2 88*"*";
	   PUT @2 "*** ERREUR : LE PARAMETRE IDENT CONTENANT L'IDENTIFIANT DES OBSERVATIONS " 
              "DE NIVEAU 1 ***";
       PUT @2 "***          N'EST PAS RENSEIGNE ALORS QUE LE PARAMETRE EGALPOI VAUT OUI." 
           @87 "***";
	   PUT @2 88*"*";
   %END;
   %IF &POPMEN=  %THEN 
   %DO;
     %LET EREGAL=1;
     DATA _NULL_;
	   FILE PRINT;
	   PUT @2 85*"*";
	   PUT @2 "*** ERREUR : LE PARAMETRE POPMEN CONTENANT LA TAILLE DE LA POPULATION DE NIVEAU 1 ***"; 
	   PUT @2 "***          N'EST PAS RENSEIGNE" @84 "***" ;
	   PUT @2 "***          CE PARAMETRE EST OBLIGATOIRE LORSQUE EGALPOI VAUT OUI" @84 "***"; 
	   PUT @2 85*"*";
   %END;
   %IF &EREGAL=1 %THEN %GOTO FIN;
%END;

%IF &IDENT=%STR() AND &TYP NE 1 AND &TYP NE 2 %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 80*"*";
 PUT @2 "*** ERREUR : L'IDENTIFIANT IDENT DES DONN�ES DE NIVEAU 1 N'EST PAS RENSEIGN� ***";
 PUT @2 "***          ALORS QUE VOUS DEMANDEZ UN CALAGE SIMULTANE                     ***";
 PUT @2 80*"*";
%GOTO FIN;
%END;

%IF &IDENT2=%STR() AND &DATAIND NE %STR()  %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 79*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 DES DONN�ES DE NIVEAU 2 N'EST PAS RENSEIGN� **";
 PUT @2 "**          ALORS QUE LE PARAM�TRE DATAIND EST RENSEIGN�                     **";
 PUT @2 79*"*";
%GOTO FIN;
%END;

%IF &IDENT2=%STR() AND &DATAKISH NE %STR() %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 86*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 DES DONN�ES DE NIVEAU KISH N'EST PAS RENSEIGN� "
     @85 "**";
 PUT @2 "**          ALORS QUE LE PARAM�TRE DATAKISH EST RENSEIGN�"  @85 "**";
 PUT @2 86*"*";
%GOTO FIN;
%END;

%IF &IDENT NE %STR() AND &IDENT2 NE %STR() AND &IDENT=&IDENT2 %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 71*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 (=&IDENT2) DES DONN�ES DE NIVEAU 2 EST LE M�ME **";
 PUT @2 "**          QUE L'IDENTIFIANT IDENT (=&IDENT) DES DONN�ES DE NIVEAU 1           **";
 PUT @2 71*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &DATAMEN=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 68*"*";
 PUT @2 "***** ERREUR : UN NOM DE TABLE DE DONN�ES KISH EST RENSEIGN�   *****";
 PUT @2 "*****          MAIS PAS LE NOM DE LA TABLE DE DONN�ES DATAMEN  *****";
 PUT @2 68*"*";
%GOTO FIN;
%END;

%IF &DATAMEN NE %STR() AND &MARMEN=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 69*"*";
 PUT @2 "***                        ERREUR :"                         @68 "***";
 PUT @2 "*** LE NOM DE LA TABLE DES MARGES MARMEN N'EST PAS RENSEIGN�      ***";
 PUT @2 "*** ALORS QU'UNE TABLE DE DONN�ES DATAMEN : &DATAMEN EST INDIQU�E ***";
 PUT @2 69*"*";
%GOTO FIN;
%END;

%IF &DATAIND NE %STR() AND &MARIND=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 69*"*";
 PUT @2 "***                        ERREUR :"                         @68 "***";
 PUT @2 "*** LE NOM DE LA TABLE DES MARGES MARIND N'EST PAS RENSEIGN�      ***";
 PUT @2 "*** ALORS QU'UNE TABLE DE DONN�ES DATAIND : &DATAIND EST INDIQU�E ***";
 PUT @2 69*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &MARKISH=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @8 66*"*";
 PUT @8 "***                        ERREUR :"                            @71 "***";
 PUT @8 "*** LE NOM DE LA TABLE DES MARGES DES INDIVIDUS-KISH (MARKISH)" @71 "***";
 PUT @8 "*** N'EST PAS RENSEIGN�"                                        @71 "***";
 PUT @8 "*** ALORS QU'UNE TABLE DE DONN�ES INDIVIDUS-KISH EST INDIQU�E"  @71 "***";
 PUT @8 66*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &POIDKISH=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @8 74*"*";
 PUT @8 "*** ERREUR : LA VARIABLE DE POND�RATION POIDKISH N'EST PAS RENSEIGN�E  ***";
 PUT @8 "***          ALORS QU'UNE TABLE DE DONN�ES INDIVIDUS-KISH EST INDIQU�E ***";
 PUT @8 "***          (DATAKISH=&DATAKISH)                                      ***";
 PUT @8 74*"*";
%GOTO FIN;
%END;

%IF &DATAMEN=%STR() AND &DATAIND NE %STR() AND %UPCASE(&EGALPOI)=OUI
    AND &POIDS=%STR() %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @8 79*"*";
 PUT @8 "*** ERREUR : LA VARIABLE DE POND�RATION INITIALE POIDS N'EST PAS RENSEIGN�E ***";
 PUT @8 "***          LA PR�SENCE DE LA POND�RATION INITIALE DANS LA TABLE DATAIND   ***";
 PUT @8 "***          EST OBLIGATOIRE QUAND EGALPOI=OUI                              ***";
 PUT @8 79*"*";
%GOTO FIN;
%END;



   /*************************************************************************
    ***  CONTROLES LORSQUE L'ON VEUT CONSERVER LES POND�RATIONS FINALES   ***
    *************************************************************************/

%IF &DATAMEN NE %STR( ) AND &POIDSFIN NE %STR( )
                         AND &DATAPOI=%STR( ) %THEN
%DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "**************";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI N'EST PAS RENSEIGNE ALORS QUE"
                      @74 "***";
        PUT @2 "***   LE CALAGE DEMAND� IMPLIQUE UN NIVEAU 1 ET QUE LE STOCKAGE "
                      @74 "***";
        PUT @2 "***   DES POIDS EST DEMAND� (POIDSFIN=%UPCASE(&POIDSFIN))"
                      @74 "***";
        PUT @2 "**************************************************************"
               "*************";
        %GOTO FIN;
%END;

%IF %SCAN(&DATAPOI,1) NE %THEN
%DO;

  %IF &POIDSFIN = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 66*"*";
      PUT @2 "***   ERREUR : LE PARAM�TRE POIDSFIN N'EST PAS RENSEIGN�"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAM�TRE DATAPOI"
             " VAUT %UPCASE(&DATAPOI)" @65 "***";
      PUT @2 66*"*";
    %GOTO FIN;
  %END;

   /*  SI LA TABLE &DATAPOI CONTIENT UN POINT  */

  %IF %INDEX(&DATAPOI,.) NE 0 %THEN
  %DO;

    %LET BASE1=%SCAN(&DATAPOI,1,.);
    %LET TABLE1=%SCAN(&DATAPOI,2,.);

    PROC CONTENTS NOPRINT DATA=&BASE1.._ALL_;
    RUN;

    %IF &SYSERR NE 0 %THEN                        /*  LE DDNAME N'EXISTE PAS  */
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "*******";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI VAUT %UPCASE(&DATAPOI),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOU�E AU DDNAME"
               " %UPCASE(&BASE1)"
            @67 "***";
        PUT @2 "**************************************************************"
               "******";
        %GOTO FIN;
    %END;

    %IF &SYSERR =  0 %THEN                              /*  LE DDNAME EXISTE  */
    %DO;
      DATA &BASE1..______UN;
      RUN;
      %IF &SYSERR NE 0 %THEN
      %DO;
        %PUT %STR( ********************************************************);
        %PUT %STR( ***   ERREUR : PAS D%'ACC�S EN �CRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOU�E AU DDNAME %UPCASE(&BASE1) )      ;
        %PUT %STR( ***            SP�CIFI� DANS LE PARAM�TRE DATAPOI ) ;
        %PUT %STR( ********************************************************);
        %GOTO FIN;
      %END;
      %ELSE
      %DO;
        PROC DATASETS DDNAME=&BASE1 NOLIST;
          DELETE ______UN;
        QUIT;
      %END;
    %END;
  %END;

  %ELSE
  %DO;
    %LET BASE1=WORK;
    %LET TABLE1=&DATAPOI;
  %END;

%END;

%IF &DATAIND NE %STR( ) AND &POIDSFIN NE %STR( )
                         AND &DATAPOI2=%STR( ) %THEN
%DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "**************";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI2 N'EST PAS RENSEIGNE ALORS QUE"
                      @74 "***";
        PUT @2 "***   LE CALAGE DEMAND� IMPLIQUE UN NIVEAU 2 ET QUE LE STOCKAGE "
                      @74 "***";
        PUT @2 "***   DES POIDS EST DEMAND� (POIDSFIN=%UPCASE(&POIDSFIN))"
                      @74 "***";
        PUT @2 "**************************************************************"
               "*************";
        %GOTO FIN;
%END;

%IF &DATAKISH NE %STR( )  AND &POIDSFIN NE %STR( )
                          AND &DATAPOI3=%STR( ) %THEN
%DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "**************";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI3 N'EST PAS RENSEIGNE ALORS QUE"
                      @74 "***";
        PUT @2 "***   UN CALAGE SIMULTANE ENTRE NIVEAUX 1 ET KISH EST DEMANDE AINSI QUE"
                      @74 "***";
        PUT @2 "***   LE STOCKAGE DES POIDS (POIDSFIN=%UPCASE(&POIDSFIN))"
                      @74 "***";
        PUT @2 "**************************************************************"
               "*************";
        %GOTO FIN;
%END;

%IF %SCAN(&DATAPOI2,1) NE %THEN
%DO;

  %IF &POIDSFIN = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 66*"*";
      PUT @2 "***   ERREUR : LE PARAM�TRE POIDSFIN N'EST PAS RENSEIGN�"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAM�TRE DATAPOI2"
             " VAUT %UPCASE(&DATAPOI2)" @65 "***";
      PUT @2 66*"*";
    %GOTO FIN;
  %END;

   /*  SI LA TABLE &DATAPOI2 CONTIENT UN POINT  */

  %IF %INDEX(&DATAPOI2,.) NE 0 %THEN
  %DO;

    %LET BASE2=%SCAN(&DATAPOI2,1,.);
    %LET TABLE2=%SCAN(&DATAPOI2,2,.);

    PROC CONTENTS NOPRINT DATA=&BASE2.._ALL_;
    RUN;

    %IF &SYSERR NE 0 %THEN                        /*  LE DDNAME N'EXISTE PAS  */
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "*******";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI2 VAUT %UPCASE(&DATAPOI2),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOU�E AU DDNAME"
               " %UPCASE(&BASE2)"
            @67 "***";
        PUT @2 "**************************************************************"
               "******";
        %GOTO FIN;
    %END;

    %IF &SYSERR =  0 %THEN                              /*  LE DDNAME EXISTE  */
    %DO;
      DATA &BASE2..______UN;
      RUN;
      %IF &SYSERR NE 0 %THEN
      %DO;
        %PUT %STR( ********************************************************);
        %PUT %STR( ***   ERREUR : PAS D%'ACC�S EN �CRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOU�E AU DDNAME %UPCASE(&BASE2) )      ;
        %PUT %STR( ***            SP�CIFI� DANS LE PARAM�TRE DATAPOI2 ) ;
        %PUT %STR( ********************************************************);
        %GOTO FIN;
      %END;
      %ELSE
      %DO;
        PROC DATASETS DDNAME=&BASE2 NOLIST;
          DELETE ______UN;
        RUN;
        QUIT;
      %END;
    %END;
  %END;

  %ELSE
  %DO;
    %LET BASE2=WORK;
    %LET TABLE2=&DATAPOI2;
  %END;

%END;

%IF %SCAN(&DATAPOI3,1) NE %THEN
%DO;

  %IF &POIDSKISHFIN = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 66*"*";
      PUT @2 "***   ERREUR : LE PARAM�TRE POIDSKISHFIN N'EST PAS RENSEIGN�"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAM�TRE DATAPOI3"
             " VAUT %UPCASE(&DATAPOI3)" @65 "***";
      PUT @2 66*"*";
    %GOTO FIN;
  %END;

   /*  SI LA TABLE &DATAPOI3 CONTIENT UN POINT  */

  %IF %INDEX(&DATAPOI3,.) NE 0 %THEN
  %DO;

    %LET BASE3=%SCAN(&DATAPOI3,1,.);
    %LET TABLE3=%SCAN(&DATAPOI3,2,.);

    PROC CONTENTS NOPRINT DATA=&BASE3.._ALL_;
    RUN;

    %IF &SYSERR NE 0 %THEN                        /*  LE DDNAME N'EXISTE PAS  */
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "*******";
        PUT @2 "***   ERREUR : LE PARAM�TRE DATAPOI3 VAUT %UPCASE(&DATAPOI3),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOU�E AU DDNAME"
               " %UPCASE(&BASE3)"
            @67 "***";
        PUT @2 "**************************************************************"
               "******";
        %GOTO FIN;
    %END;

    %IF &SYSERR =  0 %THEN                              /*  LE DDNAME EXISTE  */
    %DO;
      DATA &BASE3..______UN;
      RUN;
      %IF &SYSERR NE 0 %THEN
      %DO;
        %PUT %STR( ********************************************************);
        %PUT %STR( ***   ERREUR : PAS D%'ACC�S EN �CRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOU�E AU DDNAME %UPCASE(&BASE3) )      ;
        %PUT %STR( ***            SP�CIFI� DANS LE PARAM�TRE DATAPOI3 ) ;
        %PUT %STR( ********************************************************);
        %GOTO FIN;
      %END;
      %ELSE
      %DO;
        PROC DATASETS DDNAME=&BASE3 NOLIST;
          DELETE ______UN;
        RUN;
        QUIT;
      %END;
    %END;
  %END;

  %ELSE
  %DO;
     %LET BASE3=WORK;
     %LET TABLE3=&DATAPOI3;
  %END;

%END;


  /*************************************
   *** CONTR�LE DU PARAM�TRE ECHELLE ***
   *************************************/

%IF %DATATYP(&ECHELLE) NE NUMERIC AND &ECHELLE NE %STR( ) %THEN
%DO;
 DATA _NULL_;
   FILE PRINT;
   PUT @2 71*"*";
   PUT @2 "*** ERREUR : LE COEFFICIENT MULTIPLICATIF DES POIDS INITIAUX RENTR� ***";
   PUT @2 "***          DANS LE PARAM�TRE ECHELLE N'EST PAS NUM�RIQUE" @70 "***";
   PUT @2 "***          ECHELLE VAUT &ECHELLE" @70 "***";
   PUT @2 71*"*";
 %GOTO FIN;
%END;


 /**************************************************************************
  **** V�RIFICATION DE LA COH�RENCE DE LA DEMANDE EN CAS DE NON-R�PONSE ****
  **************************************************************************/

%IF %UPCASE(&NONREP)=OUI AND &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
%DO;
   DATA _NULL_;
     FILE PRINT;
      PUT // @2 69*"*";
      PUT    @2 "* ERREUR : VOUS DEMANDEZ UN REDRESSEMENT UNIFORME DE LA NON-R�PONSE *";
      PUT    @2 "*          (LE PARAM�TRE ECHELLE VAUT &ECHELLE)" @70 "*";
      PUT    @2 "*          ET UN REDRESSEMENT DE NON-R�PONSE PAR CALAGE G�N�RALIS�  *";
      PUT    @2 "*          (LE PARAM�TRE NONREP VAUT &NONREP)"   @70 "*";
      PUT    @2 "*          LES DEUX OPTIONS SONT INCOMPATIBLES"  @70 "*";
      PUT    @2 69*"*";
 %GOTO FIN;
%END;


                        /*************************
                         * CONTR�LES FACULTATIFS *
                         *************************/

 /**************************************************************************
  **** V�RIFICATION DE L'EXISTENCE DES TABLES DE DONN�ES ET DE MARGES ******
  **************************************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

%LET ER=0;

%EXISTENC(&DATAMEN)
RUN;
%EXISTENC(&DATAIND)
RUN;
%EXISTENC(&DATAKISH)
RUN;
%EXISTENC(&MARMEN)
RUN;
%EXISTENC(&MARIND)
RUN;
%EXISTENC(&MARKISH)
RUN;
%IF &ER=1 %THEN %GOTO FIN;

%END;

 /*****************************************************
  **** V�RIFICATION DE L'EXISTENCE DES VARIABLES ******
  ****  DANS LES TABLES DE DONN�ES ET DE MARGES  ******
  *****************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

%LET ER=0;

%IF &DATAMEN NE %STR() AND &IDENT NE %STR() %THEN %EXISVAR(DATAMEN,&IDENT);
RUN;
%IF &DATAMEN NE %STR() AND &POIDS NE %STR() %THEN %EXISVAR(DATAMEN,&POIDS);
RUN;
%IF &DATAIND NE %STR() AND &IDENT NE %STR() %THEN %EXISVAR(DATAIND,&IDENT);
RUN;
%IF &DATAIND NE %STR() AND &IDENT2 NE %STR() %THEN %EXISVAR(DATAIND,&IDENT2);
RUN;
%IF &DATAKISH NE %STR() AND &IDENT2 NE %STR() %THEN %EXISVAR(DATAKISH,&IDENT2);
RUN;
%IF &DATAIND NE %STR() AND &POIDS NE %STR() AND &DATAMEN=%STR()
    %THEN %EXISVAR(DATAIND,&POIDS);
RUN;
%IF &DATAKISH NE %STR() AND &IDENT NE %STR() %THEN %EXISVAR(DATAKISH,&IDENT) ;
RUN;
%IF &DATAKISH NE %STR() AND &POIDKISH NE %STR() %THEN %EXISVAR(DATAKISH,&POIDKISH) ;
RUN;

%IF &ER=1 %THEN %GOTO FIN;

%END;

               /*********************************
                * CONTROLES SUR LE PARAM�TRE M  *
                *********************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

  %IF &M NE 1 AND &M NE 2 AND &M NE 3 AND &M NE 4 AND &M NE 5 %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "******************************************************";
      PUT   @2 "***   ERREUR : LA VALEUR DU PARAM�TRE M (&M)       ***";
      PUT   @2 "***            EST DIFF�RENTE DE 1, 2, 3, 4 ET 5   ***";
      PUT   @2 "******************************************************";
    %GOTO FIN;
  %END;

  %IF (&M=3 OR &M=4) AND %SCAN(&LO,1) = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "***********************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE M VAUT (&M)                 ***";
      PUT   @2 "***            ET LE PARAM�TRE LO N'EST PAS RENSEIGN�   ***";
      PUT   @2 "***********************************************************";
    %GOTO FIN;
  %END;

  %IF (&M=3 OR &M=4) AND %SCAN(&UP,1) = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "***********************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE M VAUT (&M)                 ***";
      PUT   @2 "***            ET LE PARAM�TRE UP N'EST PAS RENSEIGN�   ***";
      PUT   @2 "***********************************************************";
    %GOTO FIN;
  %END;

  %IF &M=5 AND &ALPHA= %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "**************************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE M VAUT 5                       ***";
      PUT   @2 "***            ET LE PARAM�TRE ALPHA N'EST PAS RENSEIGN�   ***";
      PUT   @2 "**************************************************************";
    %GOTO FIN;
  %END;

  %IF &M=5 AND %DATATYP(&ALPHA) NE NUMERIC %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "**************************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE M VAUT 5                       ***";
      PUT   @2 "***            ET LE PARAM�TRE ALPHA N'EST PAS NUM�RIQUE   ***";
      PUT   @2 "***            (ALPHA=&ALPHA)"                        @61 "***";
      PUT   @2 "**************************************************************";
    %GOTO FIN;
  %END;

%END;


               /*****************************************
                *  CONTROLE SUR LE PARAM�TRE D'�DITION  *
                *****************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

%IF &EDITION NE 0 AND &EDITION NE 1 AND &EDITION NE 2 AND &EDITION NE 3 %THEN
%DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*********************************************************";
      PUT   @2 "***   ERREUR : LA VALEUR DU PARAM�TRE &EDITION (&M)   ***";
      PUT   @2 "***            EST DIFF�RENTE DE 0, 1, 2, 3           ***";
      PUT   @2 "*********************************************************";
    %GOTO FIN;
%END;

%END;


               /*********************************************************
                *  CONTROLE SUR LES PARAM�TRES POPMEN, POPIND, POPKISH  *
                *********************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

  %IF &POPMEN= AND %UPCASE(&PCT)=OUI AND &MARMEN NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE POPMEN N'EST PAS RENSEIGN�    ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONN�ES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAM�TRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

  %IF &POPIND= AND %UPCASE(&PCT)=OUI AND &MARIND NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE POPIND N'EST PAS RENSEIGN�    ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONN�ES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAM�TRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

  %IF &POPKISH= AND %UPCASE(&PCT)=OUI AND &MARKISH NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAM�TRE POPKISH N'EST PAS RENSEIGN�   ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONN�ES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAM�TRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

%END;

               /*****************************************
                *   CONTROLE SUR LE FACTEUR D'�CHELLE   *
                *****************************************/

  %IF %UPCASE(&CONT)=OUI %THEN
  %DO;
      %IF &ECHELLE NE  AND &ECHELLE NE 1 AND &ECHELLE NE 0 AND &POIDS=  %THEN
      %DO;
          DATA _NULL_;
           FILE PRINT;
           PUT @2 "*************************************************************";
           PUT @2 "*** ERREUR : LA VALEUR DU PARAM�TRE ECHELLE (&ECHELLE)    ***";
           PUT @2 "***          EST DIFF�RENTE DE 1 ET DE 0                  ***";
           PUT @2 "***          ALORS QUE LE POIDS INITIAL (PARAM�TRE POIDS) ***";
           PUT @2 "***          N'EST PAS RENSEIGN�                          ***";
           PUT @2 "*************************************************************";
      %END;
  %END;


   /*****************************************************
    **** CR�ATION DES MACRO-VARIABLES CONTENANT     *****
    **** LE NBRE D'OBSERV. DANS LA TABLE DE DONN�ES *****
    **** ET LE NBRE MAXIMUM DE MODALIT�S            *****
    *****************************************************/

%IF &DATAMEN NE %STR() %THEN
%DO;
   %CONTENU(&DATAMEN,1)
   %NMOD(MARMEN,NMAX1)
   %NOBSS(&DATAMEN,NOBSMEN)
   RUN;
  %IF %UPCASE(&CONT)=OUI AND &NOBSMEN=0 %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 74*"*";
      PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAMEN)" @73 "***";
      PUT @2 "***            SP�CIFI�E DANS LE PARAM�TRE DATAMEN A 0 OBSERVATION" @73 "***";
      PUT @2 74*"*";
    RUN;
    %GOTO FFIN;
  %END;
%END;

%IF &DATAIND NE %STR() %THEN
%DO;
   %CONTENU(&DATAIND,2)
   %NMOD(MARIND,NMAX2)
   %NOBSS(&DATAIND,NOBSIND)
   RUN;
 %IF %UPCASE(&CONT)=OUI AND &NOBSIND=0 %THEN
 %DO;
   DATA _NULL_;
     FILE PRINT;
     PUT //@2 74*"*";
     PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAIND)" @73 "***";
     PUT @2 "***            SP�CIFI�E DANS LE PARAM�TRE DATAIND A 0 OBSERVATION" @73 "***";
     PUT @2 74*"*";
   RUN;
   %GOTO FFIN;
 %END;
%END;

%IF &DATAKISH NE %STR() %THEN
%DO;
   %CONTENU(&DATAKISH,3)
   %NMOD(MARKISH,NMAX3)
   %NOBSS(&DATAKISH,NOBSKISH)
   RUN;
 %IF %UPCASE(&CONT)=OUI AND &NOBSKISH=0 %THEN
 %DO;
   DATA _NULL_;
     FILE PRINT;
     PUT //@2 74*"*";
     PUT @2 "***   ERREUR : LA TABLE %UPCASE(&DATAKISH)" @73 "***";
     PUT @2 "***            SP�CIFI�E DANS LE PARAM�TRE DATAKISH A 0 OBSERVATION" @73 "***";
     PUT @2 74*"*";
   RUN;
   %GOTO FFIN;
 %END;
%END;


 /****************************************************************************************
  **** V�RIFICATION DE LA COH�RENCE ENTRE NOMBRE DE M�NAGES ET NOMBRE D'INDIVIDUS-KISH ***
  ****************************************************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

%IF &DATAKISH NE %STR() AND &MARKISH NE %STR() AND &POIDKISH NE %STR() %THEN
 %DO;
  %IF &NOBSKISH < &NOBSMEN %THEN
  %DO;
   DATA _NULL_;
    FILE PRINT;
    PUT @8 "**** ERREUR : LE NOMBRE D'UNITES DANS LA TABLE &DATAKISH" @70 "****";
    PUT @8 "****          EST INFERIEUR AU NOMBRE D'OBSERVATIONS"     @70 "****";
    PUT @8 "****          DANS LA TABLE &DATAMEN"                     @70 "****";
   %GOTO FIN;
  %END;
 %END;

%END;


    /******************************************************
     * CONTR�LES EN CAS DE REDRESSEMENT DE LA NON-R�PONSE *
     ******************************************************/


    DATA __MARG;
         SET &MARMEN &MARIND &MARKISH;
    RUN;
    %LET TT=%SYSFUNC(OPEN(__MARG));
    %LET NUM=%SYSFUNC(VARNUM(&TT,R));
    %LET TT=%SYSFUNC(CLOSE(&TT));
    RUN;
%IF %UPCASE(&NONREP)=OUI %THEN
%DO;
    DATA __ZM __XM;
        SET __MARG (KEEP=VAR R N);
            IF N=0 THEN _M=1;
            ELSE _M=N;
            IF R=1 THEN OUTPUT __ZM ;
            ELSE OUTPUT __XM;
    RUN;
    %NOBSS(__ZM,NZ)
    RUN;
%END;

%IF %UPCASE(&NONREP)=NON AND %UPCASE(&CONT)=OUI            /* REDRESSEMENT NON DEMANDE */
AND &NUM>0 %THEN
%DO;
    DATA __ERREUR;
        SET __MARG (WHERE=(R=1));
    RUN;
    %NOBSS(__ERREUR,NZ)
    RUN;
    %IF &NZ>0 %THEN
    %DO;
     DATA _NULL_;
      FILE PRINT;
        PUT //@2 65*"*";
        PUT @2 "***   ERREUR : LA VARIABLE R FIGURE DANS UNE TABLE DE MARGES" @63 "***";
        PUT @2 "***            AVEC LA VALEUR 1 POUR AU MOINS UNE VARIABLE"   @63 "***";
        PUT @2 "***            ALORS QUE NONREP=NON"                          @63 "***";
        PUT @2 65*"*";
     RUN;
     %GOTO FIN;
    %END;
%END;

%IF %UPCASE(&NONREP)=OUI AND %UPCASE(&CONT)=OUI %THEN        /* REDRESSEMENT DEMANDE */
%DO;

 %IF &NUM=0 %THEN                                          /* LA VARIABLE R EST ABSENTE */
 %DO;                                                      /* DES TABLES DE MARGES      */
     DATA _NULL_;
      FILE PRINT;
        PUT //@2 65*"*";
        PUT @2 "***   ERREUR : LA VARIABLE R NE FIGURE DANS AUCUNE"           @63 "***";
        PUT @2 "***            TABLE DE MARGES SP�CIFI�E DANS LES PARAM�TRES" @63 "***";
        PUT @2 "***            &MARMEN &MARIND &MARKISH"                      @63 "***";
        PUT @2 65*"*";
     RUN;
     %GOTO FIN;
 %END;

 %ELSE
 %DO;                                                    /* LA VARIABLE R EST PR�SENTE */
   %IF &NZ=0 %THEN                                       /*   DANS LA TABLE DE MARGES  */
    %DO;
        DATA _NULL_;
         FILE PRINT;
     PUT @2 74*"*";
     PUT @2  "ERREUR : IL N'Y A AUCUNE VARIABLE DE NON-R�PONSE DANS LES TABLES DE MARGES";
     PUT @2  "         POUR UNE VAR. DE NON-R�PONSE, ON DOIT AVOIR R=1 DANS LA TABLE";
     PUT @2  "         DES MARGES";
     PUT @2 74*"*";
     RUN;
     %GOTO FIN;
    %END;

     PROC SUMMARY DATA=__XM ;
          VAR _M;
          OUTPUT OUT=__NXM
                 SUM= ;
     DATA _NULL_;
          SET __NXM;
          CALL SYMPUT('DIMX',_M);
     PROC SUMMARY DATA=__ZM ;
          VAR _M;
          OUTPUT OUT=__NZM
                 SUM= ;
     DATA _NULL_;
          SET __NZM;
          CALL SYMPUT('DIMZ',_M);
     RUN;
     %IF &DIMX NE &DIMZ %THEN
      %DO;
        DATA _NULL_;
          FILE PRINT;
          PUT @2 78*"*";
          PUT @2  "ERREUR : LE NOMBRE DE MODALITES DE NON-R�PONSE N'EST PAS �GAL � CELUI";
          PUT @2  "         DES MODALITES DE CALAGE";
          PUT @2  "         IL Y A %LEFT(&DIMZ) MODALIT�S DE NON-R�PONSE"
                  " ET %LEFT(&DIMX) MODAL. DE CALAGE";
          PUT @2 78*"*";
        RUN;
        %GOTO FIN;
      %END;
   RUN;
 %END;

%END;

 PROC DATASETS DDNAME=WORK NOLIST;
      DELETE __MARG __ZM __XM __NXM __NZM __ERREUR ;
 QUIT;



    /******************************************************************
     *            CONTROLES SUR LES TABLES DES MARGES                 *
     ******************************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

**** CONTR�LE DE LA TABLE DES MARGES M�NAGES ****;

%IF &MARMEN NE %STR() %THEN
 %DO;

%LET ER=0;

%EXISVAR(MARMEN,VAR)
RUN;
%EXISVAR(MARMEN,N)
RUN;
%VERIF2(MARMEN)
RUN;
%VERIF3(MARMEN,1)
RUN;
%VERIF4(MARMEN)
RUN;
%VERIF5(MARMEN)
RUN;
%IF &ER=1 OR &ERREUR1=1 OR &ERREUR3=1 OR &ERRTOT=1 %THEN %GOTO FIN;

 %END;

**** CONTR�LE DE LA TABLE DES MARGES INDIVIDUS ****;

%IF &MARIND NE %STR() %THEN
 %DO;

%LET ER=0;

%EXISVAR(MARIND,VAR)
RUN;
%EXISVAR(MARIND,N)
RUN;
%VERIF2(MARIND)
RUN;
%VERIF3(MARIND,2)
RUN;
%VERIF4(MARIND)
RUN;
%VERIF5(MARIND)
RUN;
%IF &ER=1 OR &ERREUR1=1 OR &ERREUR3=1 OR &ERRTOT=1 %THEN %GOTO FIN;

 %END;

**** CONTR�LE DE LA TABLE DES MARGES INDIVIDUS-KISH ****;

%IF &MARKISH NE %STR() %THEN
 %DO;

%LET ER=0;

%EXISVAR(MARKISH,VAR)
RUN;
%EXISVAR(MARKISH,N)
RUN;
%VERIF2(MARKISH)
RUN;
%VERIF3(MARKISH,3)
RUN;
%VERIF4(MARKISH)
RUN;
%VERIF5(MARKISH)
RUN;
%IF &ER=1 OR &ERREUR1=1 OR &ERREUR3=1 OR &ERRTOT=1 %THEN %GOTO FIN;

 %END;

%END;


   /*****************************************************************
    *  CONTROLES SUR LES VARIABLES DE POND�RATION DE LA TABLE DATA  *
    *****************************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

  %IF &POIDS NE AND &DATAMEN NE  %THEN
  %DO;
    %LET POIDSCAR=;
    DATA __POIDS;
      SET _NOMVAR1(WHERE=(VAR="%UPCASE(&POIDS)"));
      CALL SYMPUT("POIDSCAR",TYPE);
    RUN;

    %IF &POIDSCAR=2 %THEN
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 74*"*";
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&POIDS) SP�CIFI�E DANS LE"
               " PARAM�TRE POIDS" @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAMEN)"                @73 "***";
        PUT @2 "***            N'EST PAS NUM�RIQUE"                 @73 "***";
        PUT @2 74*"*";
      %GOTO FIN;
    %END;
  %END;

  %ELSE %IF &POIDS NE AND &DATAMEN=  AND &DATAIND NE  %THEN
  %DO;
    %LET POIDSCAR=;
    DATA __POIDS;
      SET _NOMVAR2(WHERE=(VAR="%UPCASE(&POIDS)"));
      CALL SYMPUT("POIDSCAR",TYPE);
    RUN;

    %IF &POIDSCAR=2 %THEN
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 74*"*";
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&POIDS) SP�CIFI�E DANS LE"
               " PARAM�TRE POIDS" @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAIND)"             @73 "***";
        PUT @2 "***            N'EST PAS NUM�RIQUE"                 @73 "***";
        PUT @2 74*"*";
      %GOTO FIN;
    %END;
  %END;

  %IF &PONDQK NE AND &PONDQK NE __UN %THEN
  %DO;
    %LET PONDQCAR=;
    DATA __PONDQK;
      SET _NOMVAR1(WHERE=(VAR="%UPCASE(&PONDQK)"));
      CALL SYMPUT("PONDQCAR",TYPE);
    RUN;

    %NOBSS(__PONDQK,EXPONDQK)

    %IF &EXPONDQK=0 %THEN
    %DO;
      DATA _NULL_;
        FILE PRINT;
          PUT //@2 74*"*";
          PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&PONDQK) SP�CIFI�E DANS LE"
              @73 "***";
          PUT @2 "***            PARAM�TRE PONDQK NE FIGURE PAS DANS" @73 "***";
          PUT @2 "***            LA TABLE %UPCASE(&DATAMEN)" @73 "***";
          PUT @2 74*"*";
      %GOTO FIN;
    %END;

    %ELSE %IF &PONDQCAR=2 %THEN
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 74*"*";
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&PONDQK) SP�CIFI�E DANS"
               " LE PARAM�TRE PONDQK"  @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAMEN)"                @73 "***";
        PUT @2 "***            N'EST PAS NUM�RIQUE"                 @73 "***";
        PUT @2 74*"*";
      %GOTO FIN;
    %END;
  %END;

  %IF &POIDKISH NE %STR( ) AND &DATAKISH NE %STR( ) %THEN
  %DO;
    DATA _NULL_;
      T=OPEN("&DATAKISH");
      N=VARNUM(T,"&POIDKISH");
      TYP=VARTYPE(T,N);
      IF TYP NE "N" THEN
      DO;
       FILE PRINT;
       PUT @2 75*"*";
       PUT @2 "*** ERREUR : LA VARIABLE &POIDKISH INDIQU�E DANS LE PARAM�TRE POIDKISH"
           @74 "***";
       PUT @2 "***          ET FIGURANT DANS LA TABLE &DATAKISH" @74 "***";
       PUT @2 "***          N'EST PAS NUM�RIQUE"                 @74 "***";
       PUT @2 75*"*";
      END;
      TT=CLOSE(T);
      CALL SYMPUT('TP',TYP);
    RUN;
   %IF &TP=C %THEN %GOTO FIN;
  %END;

%END;

   /*  FIN DES CONTROLES  */


  /**************************************************************************
   CALAGE S�PAR� SUR LES INDIVIDUS AVEC �GALIT� DES POIDS DANS UN M�NAGE
   **************************************************************************/

%IF &TYP=2B %THEN
%DO;

                            /* V�RIFICATION DE LA PR�SENCE D'UN IDENTIFIANT DU M�NAGE */

%IF &CONT=OUI %THEN
 %DO;

 PROC FREQ DATA=&DATAIND ;
      TABLES &IDENT/NOPRINT OUT=__NIDENT;
 RUN;
 %NOBSS(__NIDENT,NID)
 RUN;
 %IF &NID=&NOBSIND %THEN
  %DO;
   DATA _NULL_;
    FILE PRINT;
    PUT @2 74*"*";
    PUT @2 "* ERREUR : L'IDENTIFIANT &IDENT RENSEIGN� DANS LE PARAM�TRE IDENT       *";
    PUT @2 "*          N'EST PAS UN IDENTIFIANT DU M�NAGE.                          *";
    PUT @2 "*          IL Y A &NID IDENTIFIANTS DIFF�RENTS ET &NOBSIND OBSERVATIONS *";
    PUT @2 "*          DANS LA TABLE &DATAIND INDIQU�E DANS LE PARAM�TRE DATAIND    *";
    PUT @2 74*"*";
    %GOTO FIN;
  %END;
                            /* V�RIFICATION DE L'UNICIT� DES POIDS INDIVIDUS PAR M�NAGE */

 PROC FREQ DATA=&DATAIND ;
      TABLES &IDENT*&POIDS/NOPRINT OUT=__MENPOI;
 PROC FREQ DATA=__MENPOI;
      TABLES &IDENT/NOPRINT OUT=__NBPOI;
 DATA __ERR;
      SET __NBPOI(WHERE=(COUNT>1));
 RUN;
 %NOBSS(__ERR,ERRPOID)
 RUN;
 %IF &ERRPOID>=1 %THEN
  %DO;
   DATA _NULL_;
    FILE PRINT;
  PUT @2 80*"*";
  PUT @2 "* ERREUR : DANS &ERRPOID M�NAGES, DEUX INDIVIDUS ONT DES POIDS DIFF�RENTS     *";
  PUT @2 "*          LE CALAGE NE PEUT FOURNIR DES POIDS �GAUX POUR LES INDIVIDUS       *";
  PUT @2 "*          D'UN M�ME M�NAGE QUE SI CETTE �GALIT� EST V�RIFI�E ENTRE LES       *";
  PUT @2 "*          POIDS INITIAUX DANS VOTRE TABLE &DATAIND INDIQU�E DANS LE          *";
  PUT @2 "*          PARAM�TRE DATAIND.                                                 *";
  PUT @2 "* SOIT IL Y A UNE ERREUR DANS VOTRE TABLE &DATAIND, SOIT VOUS FAITES UN       *";
  PUT @2 "* CALAGE SANS DEMANDER UNE �GALIT� DES POIDS ENTRE INDIVIDUS D'UN M�ME M�NAGE *";
  PUT @2 "* (EGALPOI � BLANC)                                                           *";
  PUT @2 80*"*";
  
  PROC PRINT DATA=__ERR LABEL SPLIT='!';
        TITLE 'LISTE DES M�NAGES EN ERREUR';
        VAR &IDENT COUNT;
        LABEL COUNT='NOMBRE DE POIDS!DIFF�RENTS!PAR M�NAGE';
   RUN;
   %GOTO FIN;
  %END;

 %END;

                            /* CR�ATION D'UNE TABLE M�NAGES */

 PROC SORT DATA=&DATAIND OUT=__INDIV;
      BY &IDENT;
 DATA __MENAGE (KEEP=&IDENT &POIDS MU %IF %UPCASE(&NONREP)=OUI %THEN %DO; ZMU %END;);
      SET __INDIV;
      BY &IDENT;
         MU='1';
       %IF %UPCASE(&NONREP)=OUI %THEN
       %DO;
         ZMU='1';
       %END;
         IF FIRST.&IDENT THEN OUTPUT;

                            /* CR�ATION D'UNE TABLE DE MARGES M�NAGES */


 DATA __MARM;
      LENGTH VAR $ 32 ;
          VAR='MU';
          N=1;
          R=0;
       %IF %UPCASE(&PCT)=OUI %THEN %STR(MAR1=100;);
	   %ELSE MAR1=&POPMEN; ;
          OUTPUT;
       %IF %UPCASE(&NONREP)=OUI %THEN
       %DO;
          VAR='ZMU';
          N=1;
          R=1;
          OUTPUT;
       %END;

PROC DATASETS DDNAME=WORK NOLIST;
     DELETE __INDIV;
QUIT;

 %LET DATAMEN=__MENAGE;
 %LET MARMEN=__MARM;

%END;

******************************************************************************************;
*********  CALCUL DU NOMBRE DE VARIABLES DE CALAGE                             ***********;
*********  STOCKAGE DES NOMS ET DU NOMBRE DE MODALIT�S DES VARIABLES DE CALAGE ***********;
*********  DANS UNE TABLE DE MACRO-VARIABLES                                   ***********;
******************************************************************************************;

%LET CAT1=0;
%LET NUM1=0;
%LET CAT2=0;
%LET NUM2=0;
%LET CAT3=0;
%LET NUM3=0;
%LET CATZ1=0;
%LET NUMZ1=0;
%LET CATZ2=0;
%LET NUMZ2=0;
%LET CATZ3=0;
%LET NUMZ3=0;
%LET NZM=0;
%LET NZI=0;
%LET NZK=0;
%LET ZZM= ;
%LET ZZMV= ;
%LET ZZ0= ;
%LET ZZ1= ;
%LET ZZ2= ;
%LET A= ;
%LET B= ;
%LET C= ;
%LET ERREP=0;

%IF &TYP=1 OR &TYP=2B OR &TYP=3 OR &TYP=4 OR &TYP=5 %THEN            /* NIVEAU M�NAGES */
%DO;
 DATA __MARMEN
      __ZMEN   ;
	  LENGTH VAR $32;
      SET &MARMEN;
          IF N=0 THEN TYPE='N';
          ELSE        TYPE='C';
         %IF %UPCASE(&NONREP)=OUI %THEN
         %DO;
          IF R NE 1 THEN OUTPUT __MARMEN;
          ELSE IF R=1 THEN OUTPUT __ZMEN;
         %END;
         %ELSE
         %DO;
           OUTPUT __MARMEN;
         %END;
 PROC SORT DATA=__MARMEN;
      BY TYPE VAR;
 PROC SORT DATA=__ZMEN;
      BY TYPE VAR;
 RUN;
 %NOBSS(__MARMEN,NVARM)
 RUN;
 %DO I=1 %TO &NVARM;
   %LOCAL V&I;
   %LOCAL MM&I;
 %END;
 DATA __MARMEN (DROP=NUM CAT TYPE);
     SET __MARMEN;
         VARNUM=COMPRESS('V'!!_N_);
         MODNUM=COMPRESS('MM'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUM1',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CAT1',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __MARMEN;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;

 %NOBSS(__ZMEN,NZM)
 RUN;

 %IF &NZM NE 0 %THEN
 %DO;
  %DO I=1 %TO &NZM;
   %LOCAL ZM&I MZM&I MMZM&I;
  %END;
 DATA __ZMEN (DROP=NUM CAT TYPE);
     SET __ZMEN;
         VARNUM=COMPRESS('ZM'!!_N_);
         MODNUM=COMPRESS('MZM'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUMZ1',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CATZ1',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __ZMEN;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;
 %LET MMZM1=%EVAL(&MZM1);
 %IF &CATZ1>1 %THEN
   %DO I=2 %TO &CATZ1 ;
       %LET MMZM&I=%EVAL(&&MZM&I-1);
   %END;
 %END;

%IF %UPCASE(&NONREP)=OUI AND %UPCASE(&CONT)=OUI %THEN
%DO;
 %IF &CAT1 NE &CATZ1 %THEN
 %DO;
    %LET ERREP=1;
    DATA _NULL_;
         FILE PRINT;
          PUT @2 78*"*";
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CAT�GORIELLES DE CALAGE N'EST PAS �GAL";
          PUT @2  "         � CELUI DES VARIABLES CAT�GORIELLES DE NON-R�PONSE";
          PUT @2  "         DANS LA TABLE &MARMEN INDIQU�E DANS LE PARAM�TRE MARMEN";
          PUT @2  "         IL Y A &CAT1 VARIABLES CAT�GORIELLES DE CALAGE"
                  " ET &CATZ1 VAR.CAT.DE NON-R�PONSE";
          PUT @2 78*"*";
     RUN;
 %END;
%END;

%END;


%IF &TYP=2 OR &TYP=2B OR &TYP=3 OR &TYP=5 %THEN %DO;               /* NIVEAU INDIVIDUS */
 DATA __MARIND
      __ZIND  ;
     SET &MARIND;
          IF N=0 THEN TYPE='N';
          ELSE        TYPE='C';
         %IF %UPCASE(&NONREP)=OUI %THEN
         %DO;
          IF R NE 1 THEN OUTPUT __MARIND;
          ELSE IF R=1 THEN OUTPUT __ZIND;
         %END;
         %ELSE
         %DO;
           OUTPUT __MARIND;
         %END;
 PROC SORT DATA=__MARIND;
      BY TYPE VAR;
 PROC SORT DATA=__ZIND;
      BY TYPE VAR;
 RUN;
 %NOBSS(__MARIND,NVARI)
 RUN;
 %DO I=1 %TO &NVARI;
   %LOCAL W&I P&I;
 %END;
 DATA __MARIND (DROP=NUM CAT TYPE);
     SET __MARIND;
         VARNUM=COMPRESS('W'!!_N_);
         MODNUM=COMPRESS('P'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUM2',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CAT2',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __MARIND ;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;

 %NOBSS(__ZIND,NZI)
 RUN;
 %IF &NZI>0 %THEN
 %DO;
  %DO I=1 %TO &NZI;
   %LOCAL ZI&I MZI&I MMZI&I;
  %END;

 DATA __ZIND (DROP=NUM CAT TYPE);
     SET __ZIND;
         VARNUM=COMPRESS('ZI'!!_N_);
         MODNUM=COMPRESS('MZI'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUMZ2',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CATZ2',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __ZIND ;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;
 %LET MMZI1=%EVAL(&MZI1);
 %IF &CATZ2>1 %THEN
  %DO I=2 %TO &CATZ2;
   %LET MMZI&I=%EVAL(&&MZI&I-1);
  %END;
 %END;

%IF %UPCASE(&NONREP)=OUI AND %UPCASE(&CONT)=OUI %THEN
%DO;
 %IF &CAT2 NE &CATZ2 %THEN
 %DO;
    %LET ERREP=1;
    DATA _NULL_;
         FILE PRINT;
          PUT @2 78*"*";
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CAT�GORIELLES DE CALAGE N'EST PAS �GAL";
          PUT @2  "         � CELUI DES VARIABLES CAT�GORIELLES DE NON-R�PONSE";
          PUT @2  "         DANS LA TABLE &MARIND INDIQU�E DANS LE PARAM�TRE MARIND";
          PUT @2  "         IL Y A &CAT2 VARIABLES CAT�GORIELLES DE CALAGE"
                  " ET &CATZ2 VAR.CAT.DE NON-R�PONSE";
          PUT @2 78*"*";
 %END;
%END;

%END;


%IF &TYP>=4 %THEN                            /* NIVEAU INDIVIDUS KISH */
%DO;
 DATA __MARKIS
      __ZKISH  ;
     SET &MARKISH;
          IF N=0 THEN TYPE='N';
          ELSE        TYPE='C';
         %IF %UPCASE(&NONREP)=OUI %THEN
         %DO;
          IF R NE 1 THEN OUTPUT __MARKIS;
          ELSE IF R=1 THEN OUTPUT __ZKISH;
         %END;
         %ELSE
         %DO;
           OUTPUT __MARKIS;
         %END;
 PROC SORT DATA=__MARKIS;
      BY TYPE VAR;
 PROC SORT DATA=__ZKISH;
      BY TYPE VAR;
 RUN;
 %NOBSS(__MARKIS,NVARK)
 RUN;
 %DO I=1 %TO &NVARK;
   %LOCAL K&I MK&I ;
 %END;
 DATA __MARKIS (DROP=NUM CAT TYPE);
     SET __MARKIS;
         VARNUM=COMPRESS('K'!!_N_);
         MODNUM=COMPRESS('MK'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUM3',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CAT3',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __MARKIS;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;

 %NOBSS(__ZKISH,NZK)
 RUN;

 %IF &NZK>0 %THEN
 %DO;
  %DO I=1 %TO &NZK;
   %LOCAL ZK&I MZK&I MMZK&I;
  %END;
 DATA __ZKISH (DROP=NUM CAT TYPE);
     SET __ZKISH;
         VARNUM=COMPRESS('ZK'!!_N_);
         MODNUM=COMPRESS('MZK'!!_N_);
         IF N=0 THEN NUM+1;
         ELSE IF N>0 THEN CAT+1;
         CALL SYMPUT ('NUMZ3',TRIM(LEFT(PUT(NUM,9.))));
         CALL SYMPUT ('CATZ3',TRIM(LEFT(PUT(CAT,9.))));
 DATA _NULL_;
     SET __ZKISH;
     CALL SYMPUT (VARNUM,VAR);
     CALL SYMPUT (MODNUM,TRIM(LEFT(PUT(N,9.))));
 RUN;
 %LET MMZK1=%EVAL(&MZK1);
 %IF &CATZ3>1 %THEN
  %DO I=2 %TO &CATZ3;
   %LET MMZK&I=%EVAL(&&MZK&I-1);
  %END;
 %END;

%IF %UPCASE(&NONREP)=OUI AND %UPCASE(&CONT)=OUI %THEN
%DO;
 %IF &CAT3 NE &CATZ3 %THEN
 %DO;
    %LET ERREP=1;
    DATA _NULL_;
         FILE PRINT;
          PUT @2 78*"*";
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CAT�GORIELLES DE CALAGE N'EST PAS �GAL";
          PUT @2  "         � CELUI DES VARIABLES CAT�GORIELLES DE NON-R�PONSE";
          PUT @2  "         DANS LA TABLE &MARKISH INDIQU�E DANS LE PARAM�TRE MARKISH";
          PUT @2  "         IL Y A &CAT3 VARIABLES CAT�GORIELLES DE CALAGE"
                  " ET &CATZ3 VAR.CAT.DE NON-R�PONSE";
          PUT @2 78*"*";
 %END;
%END;

 /* CALCUL DU NOMBRE MAXIMUM D'UNITES KISH PAR MENAGE */

%IF &NOBSKISH=&NOBSMEN %THEN %LET NKISH=1;

%ELSE %DO;
   PROC FREQ DATA=&DATAKISH NOPRINT;
        TABLES &IDENT / OUT=__NBUS;
   PROC SUMMARY DATA=__NBUS ;
        VAR COUNT;
		OUTPUT OUT=__MAXK
		       MAX=MAXKISH;
   DATA _NULL_;
        SET __MAXK;
		CALL SYMPUT('NKISH',MAXKISH);
   RUN;
   PROC DATASETS NOLIST;
        DELETE __NBUS __MAXK;
   QUIT;
%END;

%END;

RUN;

%IF &ERREP =1 %THEN %GOTO FIN;

%IF %UPCASE(&NONREP)=OUI %THEN
%DO;

%IF &NZM>0 %THEN
 %DO I=1 %TO &NZM;
     %LET ZZM=&ZZM &&ZM&I;
     %LET ZZMV=&ZZMV &&ZM&I,;
 %END;

%ELSE %IF &TYP=2  AND &NZI>0 %THEN
 %DO I=1 %TO &NZI;
     %LET ZZM=&ZZM &&ZI&I;
     %LET ZZMV=&ZZMV &&ZI&I,;
 %END;

%IF &CATZ1>0 %THEN
 %DO I=1 %TO &CATZ1;
  %DO J=1 %TO &&MZM&I;
     %LET A=&A ZM&I._&J;
  %END;
 %END;
%IF &NUMZ1>0 %THEN
 %DO L=%EVAL(&CATZ1+1) %TO &NZM;
     %LET A=&A ZM&L._1;
 %END;

%IF &CATZ2>0 %THEN
 %DO I=1 %TO &CATZ2;
  %DO J=1 %TO &&MZI&I;
     %LET B=&B ZI&I._&J;
  %END;
 %END;
%IF &NUMZ2>0 %THEN
 %DO L=%EVAL(&CATZ2+1) %TO &NZI;
     %LET B=&B ZI&L._1;
 %END;

%IF &CATZ3>0 %THEN
 %DO I=1 %TO &CATZ3;
  %DO J=1 %TO &&MZK&I;
     %LET C=&C ZK&I._&J;
  %END;
 %END;
%IF &NUMZ3>0 %THEN
 %DO L=%EVAL(&CATZ3+1) %TO &NZK;
     %LET C=&C ZK&L._1;
 %END;

%IF &CATZ1>0 %THEN
 %DO I=1 %TO &CATZ1;
  %DO J=1 %TO &&MMZM&I;
     %LET ZZ2=&ZZ2 ZM&I._&J;
  %END;
 %END;
%IF &NUMZ1>0 %THEN
 %DO L=%EVAL(&CATZ1+1) %TO &NZM;
     %LET ZZ2=&ZZ2 ZM&L._1;
 %END;

%IF &CATZ2>0 %THEN
 %DO I=1 %TO &CATZ2;
  %DO J=1 %TO &&MMZI&I;
     %LET ZZ2=&ZZ2 ZI&I._&J;
  %END;
 %END;
%IF &NUMZ2>0 %THEN
 %DO L=%EVAL(&CATZ2+1) %TO &NZI;
     %LET ZZ2=&ZZ2 ZI&L._1;
 %END;

%IF &CATZ3>0 %THEN
 %DO I=1 %TO &CATZ3;
  %DO J=1 %TO &&MMZK&I;
     %LET ZZ2=&ZZ2 ZK&I._&J;
  %END;
 %END;
%IF &NUMZ3>0 %THEN
 %DO L=%EVAL(&CATZ3+1) %TO &NZK;
     %LET ZZ2=&ZZ2 ZK&L._1;
 %END;

%LET ZZ0=&ZZM &B &C;
%LET ZZ1=&A &B &C;

%END;

*************************************************** ;
****************  CALAGE AVEC :  ****************** ;
*************************************************** ;

%IF &TYP=1 %THEN %DO;                             /* UN SEUL FICHIER DE NIVEAU M�NAGE */

DATA __MARMEN;
     LENGTH NIVEAU $1;
     SET __MARMEN;
         NIVEAU='1';
                           /* LA TABLE M�NAGE CONTIENT AU MOINS UNE VAR. CAT�GORIELLE */

 %IF (&CAT1>0 OR &CATZ1>0) %THEN %DO;
    %CODIF(TABIN=&DATAMEN,
           TABOUT=&TABMEN,
           XV=V,
           XM=MM)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E1;
    %CALMAR1(DATA=&TABMEN,
            DATAMAR=__MARMEN,
            IDENT=&IDENT,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPMEN,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
     RUN;
%E1: PROC DATASETS DDNAME=WORK NOLIST;
         DELETE __MARMEN __MENAGE;
    QUIT;
 %END;
                         /* LA TABLE M�NAGE NE CONTIENT PAS DE VARIABLES CAT�GORIELLES */

 %ELSE %IF (&CAT1=0 AND &CATZ1=0)  %THEN
  %DO;
    %CALMAR1(DATA=&DATAMEN,
            DATAMAR=__MARMEN,
            IDENT=&IDENT,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPMEN,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
    PROC DATASETS DDNAME=WORK NOLIST;
         DELETE __MARMEN ;
    QUIT;
  %END;
%END;

%ELSE %IF &TYP=2 %THEN %DO;                      /* UN SEUL FICHIER DE NIVEAU INDIVIDU */

DATA __MARIND;
     LENGTH NIVEAU $1;
     SET __MARIND;
         NIVEAU='2';

                          /* LA TABLE INDIVIDU CONTIENT AU MOINS UNE VAR. CAT�GORIELLE */
 %IF (&CAT2>0 OR &CATZ2>0) %THEN
  %DO;
      %CODIF(TABIN=&DATAIND,
             TABOUT=&TABIND,
             XV=W,
             XM=P)
      RUN;
      %IF &ERMOD=1 %THEN %GOTO E2;
      %CALMAR1(DATA=&TABIND,
              DATAMAR=__MARIND,
              IDENT=&IDENT2,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPIND,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
     RUN;
%E2: PROC DATASETS DDNAME=WORK NOLIST;
         DELETE __MARIND __INDIV;
    QUIT;
  %END;
                       /* LA TABLE INDIVIDU NE CONTIENT PAS DE VARIABLES CAT�GORIELLES */
 %ELSE %DO;
      %CALMAR1(DATA=&DATAIND,
              DATAMAR=__MARIND,
              IDENT=&IDENT2,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPIND,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
 %END;
%END;

%ELSE %IF &TYP=2B OR &TYP=3 %THEN %DO;           /* CALAGE SIMULTANE M�NAGES + INDIVIDUS */

                             /* LA TABLE M�NAGES CONTIENT AU MOINS UNE VAR. CAT�GORIELLE */

 %IF (&CAT1>0 OR &CATZ1>0) AND &TYP NE 2B %THEN
  %DO;
    %CODIF(TABIN=&DATAMEN,
           TABOUT=&TABMEN ,
           XV=V,
           XM=MM)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E3 ;
  %END;
                           /* LA TABLE INDIVIDUS CONTIENT AU MOINS UNE VAR. CAT�GORIELLE */
 %IF (&CAT2>0 OR &CATZ2>0) %THEN
  %DO;
      %CODIF(TABIN=&DATAIND,
             TABOUT=&TABIND,
             XV=W,
             XM=P)
      RUN;
      %IF &ERMOD=1 %THEN %GOTO E3;
  %END;
      %REMONTEE
      %MARGES(ENTREE=__MARIND)
      %CALMAR1(DATA=__MENAGE,
              DATAMAR=__MARGES,
              IDENT=&IDENT,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPMEN,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
     RUN;
%E3: PROC DATASETS DDNAME=WORK NOLIST;
         DELETE __MARMEN __MARIND  __MENAGE  __MARGES
                %IF &CAT2>0 %THEN %DO;  __INDIV   %END;  ;
    QUIT;
%END;

%ELSE %IF &TYP=4 %THEN %DO;                          /* CALAGE SIMULTANE MENAGES + KISH */
 %IF (&CAT1>0 OR &CATZ1>0) %THEN
  %DO;
    %CODIF(TABIN=&DATAMEN,
           TABOUT=&TABMEN ,
           XV=V,
           XM=MM)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E4;
  %END;
 %IF (&CAT3>0 OR &CATZ3>0) %THEN
  %DO;
    %CODIF(TABIN=&DATAKISH,
           TABOUT=&TABKISH,
           XV=K,
           XM=MK)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E4;
  %END;
 %REMONTKI
 %MARGES(ENTREE=__MARKIS)
 %CALMAR1(DATA=__MENAGE,
              DATAMAR=__MARGES,
              IDENT=&IDENT,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPMEN,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
     RUN;
%E4: PROC DATASETS DDNAME=WORK NOLIST;
         DELETE __MARMEN __MARKIS __MENAGE  __MARGES  __MARIND
                %IF &CAT3>0 %THEN %DO; __KISH    %END;   ;
    QUIT;
%END;

                                          /* CALAGE SIMULTANE MENAGES + INDIVIDUS + KISH */
%ELSE %IF &TYP=5 %THEN %DO;
 %IF (&CAT1>0 OR &CATZ1>0) %THEN
  %DO;
    %CODIF(TABIN=&DATAMEN,
           TABOUT=&TABMEN ,
           XV=V,
           XM=MM)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E5;
  %END;
 %IF (&CAT2>0 OR &CATZ2>0) %THEN
  %DO;
    %CODIF(TABIN=&DATAIND,
           TABOUT=&TABIND,
           XV=W,
           XM=P)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E5;
  %END;
 %IF (&CAT3>0 OR &CATZ3>0) %THEN
  %DO;
    %CODIF(TABIN=&DATAKISH,
           TABOUT=&TABKISH,
           XV=K,
           XM=MK)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E5;
  %END;
 %REMONTEE
 %MARGES(ENTREE=__MARIND)
 %REMONTKI
 %MARGES(ENTREE=__MARKIS)
 %CALMAR1(DATA=__MENAGE,
              DATAMAR=__MARGES,
              IDENT=&IDENT,
               POIDS=&POIDS,
               PONDQK=&PONDQK,
               DATAPOI=&DATAPOI,
               POIDSFIN=&POIDSFIN,
               LABELPOI=&LABELPOI,
               MISAJOUR=&MISAJOUR,
               M=&M,
               LO=&LO,
               UP=&UP,
               PCT=&PCT,
               EFFPOP=&POPMEN,
               SEUIL=&SEUIL,
               MAXITER=&MAXITER,
               OBSELI=&OBSELI,
               CONT=&CONT,
               EDITPOI=&EDITPOI,
               STAT=&STAT,
               CONTPOI=&CONTPOI,
               NOTES=&NOTES)
     RUN;
%E5: PROC DATASETS DDNAME=WORK NOLIST;
      DELETE __MARMEN __MARIND __MARKIS __MENAGE  __MARGES
             %IF &CAT2>0 %THEN %DO; __INDIV           %END;
             %IF &CAT3>0 %THEN %DO; __KISH            %END;  ;
    QUIT;

%END;

%FIN:

PROC DATASETS DDNAME=WORK NOLIST;
     DELETE _NOMVAR1 _NOMVAR2 _NOMVAR3 __ZMEN __ZIND __ZKISH __MARG __ZM __XM __NXM __NZM
            __ERREUR __POIDS __MARM __CODMEN __CODIND __CODKIS __MENPOI __NBPOI __ERR __NIDENT;
    QUIT;

OPTIONS NOTES ;

%MEND CALMAR2;
