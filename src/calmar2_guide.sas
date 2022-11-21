 /************************************************************************************* 
  ***             CALAGE AVEC RECODIFICATION DES VARIABLES QUALITATIVES             *** 
  ***                    CALAGE SIMULTANÉ MÉNAGES-INDIVIDUS-KISH                    *** 
  ***                   REDRESSEMENT GENERALISE DE LA NON-REPONSE                   *** 
  *************************************************************************************/

%MACRO CALMAR2_GUIDE(NONREP=NON,
               PONDQK=__UN,
               MISAJOUR=OUI,
               PCT=NON,
               M=1,
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
               TABKISH=__KISH)  /store;

  OPTIONS NONOTES;

FOOTNOTE1;FOOTNOTE2;FOOTNOTE3;FOOTNOTE4;FOOTNOTE5;

%LOCAL ER ERREUR1 ERREUR3 ERRTOT ERMOD NOBSMEN NOBSIND NOBSKISH NVARXM NR NVARM NVARI NVARK
       NZM NZI NZK NZ NID ERRPOID NMAX1 NMAX2 NMAX3 NMAX EXPONDQK
       TYP NUM1 NUM2 NUM3 CAT1 CAT2 CAT3 CATZ1 CATZ2 CATZ3 NUMZ1 NUMZ2 NUMZ3
       ZZ0 ZZ1 ZZ2 I J L simul sim1 sim2 sim3;
%global datamen marmen dataind marind datakish markish egalpoi ident ident2 poids poidkish 
   datapoi datapoi2 datapoi3 poidsfin poidskishfin labelpoi labelpoikish popmen popind popkish 
   lo up ;

     /*   POUR AVOIR LA DATE EN FRANÇAIS (OU EN CANADIEN FRANÇAIS) ...   */

%LET JOUR = %SUBSTR(&SYSDATE,1,2);
%LET AN   = %SUBSTR(&SYSDATE9,6,4);

%macro jour;
        %if %upcase(&sysday)=MONDAY    %then Lundi;
  %else %if %upcase(&sysday)=TUESDAY   %then Mardi;
  %else %if %upcase(&sysday)=WEDNESDAY %then Mercredi;
  %else %if %upcase(&sysday)=THURSDAY  %then Jeudi;
  %else %if %upcase(&sysday)=FRIDAY    %then Vendredi;
  %else %if %upcase(&sysday)=SATURDAY  %then Samedi;
  %else %if %upcase(&sysday)=SUNDAY    %then Dimanche;
%mend;

%macro mois;
      %IF %substr(&sysdate,3,3)=JAN %THEN janvier ;
%ELSE %IF %substr(&sysdate,3,3)=FEB %THEN février ;
%ELSE %IF %substr(&sysdate,3,3)=MAR %THEN mars;
%ELSE %IF %substr(&sysdate,3,3)=APR %THEN avril ;
%ELSE %IF %substr(&sysdate,3,3)=MAY %THEN mai ;
%ELSE %IF %substr(&sysdate,3,3)=JUN %THEN juin ;
%ELSE %IF %substr(&sysdate,3,3)=JUL %THEN juillet;
%ELSE %IF %substr(&sysdate,3,3)=AUG %THEN aout ;
%ELSE %IF %substr(&sysdate,3,3)=SEP %THEN septembre;
%ELSE %IF %substr(&sysdate,3,3)=OCT %THEN octobre;
%ELSE %IF %substr(&sysdate,3,3)=NOV %THEN novembre;
%ELSE %IF %substr(&sysdate,3,3)=DEC %THEN décembre;
%mend mois;


            /*************************************
             * ENTREE INTERACTIVE DES PARAMETRES *
             *************************************/


             /* DESSIN DES FENETRES DE DIALOGUE */

%window fenetre1 color=blue
 #3  @70 "%jour &jour %mois &an"
 #10 @38 "***************"  color=white
 #11 @38 "*             *"  color=white
 #12 @38 "* C A L M A R *"  color=white
 #13 @38 "*             *"  color=white
 #14 @38 "***************"  color=white
 #18 @5 "CALMAR (CALage sur MARge) est un logiciel de redressement d'enquete par repondération."
           color=white 
 #20 @5 "Vous aurez en sortie une table contenant, pour chaque unité enquetée, son identifiant"
        color=white 
 #21 @5 "et son poids de sondage redressé"  color=white
 #23 @5 "Le fonctionnement du programme CALMAR est décrit dans le manuel de l'utilisateur : "
		color=white 
 #24 @5 "La macro CALMAR, O.Sautory et J.Le Guennec, INSEE, document de travail n°   , octobre 2000. "
		color=white
 #26 @5 "La théorie du calage est exposée dans : Redressement d'échantillons d'enquetes par"
         color=white " calage"  color=white 
 #27 @5 "sur marges, O.Sautory, INSEE, document de travail n°F9103, mars 1991." color=white 
 #30 @32  "Faire ENTREE pour continuer"  color=yellow  
 #32 @32  "Taper F pour abandonner l'application : "  color=yellow 
           FIN 1 attr=underline color=yellow;

%window fenetre1b color=blue
 #10 @5 "Vous allez spécifier vos paramètres en renseignant les champs indiqués." color=white
 #12 @5 "Pour positionner le curseur sur un champ, cliquer avec la souris ou utiliser la touche"
         color=white 
 #13 @5 " de tabulation."  color=white
 #14 @5 "Pour valider un paramètre et passer au paramètre suivant, taper ENTREE."  color=white
 #17 @5 "On passe à l'écran suivant en tapant ENTREE sur le dernier champ de saisie" color=white 
        " ou en tapant" color=white
 #18 @5 "V ou ENTREE dans le champ prévu à cet effet." color=white  
 #21 @5 "On revient à l'écran précédent en tapant R dans le champ prévu à cet effet."  
         color=white
 #24 @5 "Vous pouvez à tout moment interrompre l'application sans exécuter le calage en tapant F"
         color=white 
 #25 @5 "dans le champ prévu à cet effet." color=white
 #30 @32  "Faire ENTREE pour continuer"  color=yellow  
 #31 @32  "Pour revenir à l'écran précédent, taper R"  color=yellow 
 #32 @32  "Pour abandonner l'application, taper    F : "  color=yellow 
           FIN 1 attr=underline color=yellow;


%window fenetre2 color=blue
 group=g1
 #5 @2 "Souhaitez-vous un calage simultané entre plusieurs niveaux d'observation ?"
          color=white " (réponse=OUI ou NON)" color=white
 #7 @47  SIMUL 3  attr=rev_video color=white required=yes  autoskip=yes
 #28 @30  "Faire ENTREE pour continuer"                      color=yellow 
 #31 @30  "Pour revenir à l'écran précédent, taper    R"     color=yellow 
 #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow   
 group=g2
 #9 @2 "Si oui, indiquez les niveaux concernés en remplissant les champs ci-dessous par OUI"
          color=white
 #11 @15 "Niveau 1 (exemple : ménage)" color=white
     @47  SIM1 3 attr=rev_video color=white autoskip=yes
 #12 @15 "Niveau 2 (exemple : individu)" color=white
     @50  SIM2 3 attr=rev_video color=white autoskip=yes
 #13 @15 "Niveau Kish" color=white
     @53  SIM3 3 attr=rev_video color=white autoskip=yes
 #20 @2 "(On peut avoir les configurations suivantes : niveaux 1+2, niveaux 1+Kish, niveaux 1+2+Kish)"
          color=white
 #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
 #31 @30  "Pour revenir à l'écran précédent, taper    R"     color=yellow 
 #32 @77   FIN 1 attr=underline color=yellow ;
 
%window erreur1 color=blue
 #15 @20 "ERREUR ! les caractères saisis ne correspondent pas à OUI ou NON" color=white 
 #28 @30  "Faire ENTREE pour continuer" color=yellow ; 

%window erreur2 color=blue
 #15 @5 "ERREUR ! au moins une réponse ne correspond pas aux réponses possibles : OUI/NON/blanc"
         color=white
 #28 @30  "Faire ENTREE pour continuer"   color=yellow ;

%window erreur3 color=blue
 #15 @15 "ERREUR ! au moins deux champs doivent etre renseignés par OUI" color=white
 #28 @30  "Faire ENTREE pour continuer"   color=yellow ;

%window fenetre3 color=blue
 #15 @5 "Souhaitez-vous une égalité des poids de calage entre entités appartenant à une même grappe ?"
        color=white
 #17 @8 "(Exemple : enquête auprès des individus, sans données de niveau ménage," color=white
 #18 @8 "           mais avec des poids égaux entre individus du même ménage)" color=white
 #20 @5 "(réponse = OUI ou NON)" color=white
 #22 @29 "EGALPOI = " EGALPOI 3 color=white attr=rev_video autoskip=yes 
 #28 @30  "Faire ENTREE pour continuer"                     color=yellow 
 #31 @30  "Pour revenir sur l'écran précédent, taper R"     color=yellow 
 #32 @30  "Pour quitter l'application, taper         F : "  color=yellow 
           FIN 1 attr=underline color=yellow  ; 

%window fenetre4 color=blue
  group=niveau1
     #3  @5 "Données de niveau 1 (exemple : niveau ménage)" color=yellow attr=underline
     #10 @10 "Nom de la table d'enquête : " color=white "DATAMEN = " 
              DATAMEN 41 attr=rev_video color=white autoskip=yes
     #12 @10 "Nom de la variable identifiant les observations : " color=white "  IDENT = " 
              IDENT 32  attr=rev_video color=white  autoskip=yes
     #14 @10 "Nom de la variable contenant les poids de sondage : " color=white "POIDS = "
              POIDS 32  attr=rev_video color=white autoskip=yes
     #16 @10 "Nom de la variable contenant la pondération 'QK' (facultatif) : " color=white 
              "PONDQK = "
              PONDQK 16  attr=rev_video color=white autoskip=yes required=yes
     #19 @10 "Nom de la table de marges : " color=white " MARMEN = "
              MARMEN  41 attr=rev_video color=white  autoskip=yes
     #21 @10 "Les marges sont-elles données en pourcentage ? (réponse=OUI ou NON)" color=white
         @84  "PCT = " PCT 3  attr=rev_video color=white autoskip=yes required=yes
     #28 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 
  group=niveau1b
     #23 @10 "Effectif de la population : " color=white " POPMEN = "
              POPMEN 15 attr=rev_video color=white autoskip=yes   
     #32 @77  FIN 1 attr=underline color=yellow  ;

%window fenetre5 color=blue
 group=niveau2
     #3  @5 "Données de niveau 2 (exemple : niveau individus)" color=yellow attr=underline
     #10 @10 "Nom de la table d'enquête : " color=white "DATAIND = "
              DATAIND 41 attr=rev_video color=white  autoskip=yes
     #12 @10 "Nom de la variable identifiant les observations : " color=white "IDENT2 = "
              IDENT2 32  attr=rev_video color=white autoskip=yes
     #14 @10 "Nom de la table de marges : " color=white " MARIND = "
              MARIND  41 attr=rev_video color=white autoskip=yes
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 
 group=niveau2b
     #18 @10 "Nom de la variable identifiant les observations de niveau 1: " color=white
             "IDENT = " IDENT 32 attr=rev_video color=white autoskip=yes 
     #20 @10 "Nom de la variable contenant les poids de sondage : " color=white "POIDS = "
              POIDS 32  attr=rev_video color=white autoskip=yes
     #22 @10 "Les marges sont-elles données en pourcentage ? (réponse=OUI ou NON)" color=white
     #23 @20 "PCT = " PCT 3  attr=rev_video color=white autoskip=yes required=yes
     #32 @77  FIN 1 attr=underline color=yellow 

 group=niveau2c
     #25 @10 "Effectif de la population : " color=white  " POPIND = " 
              POPIND 15 attr=rev_video color=white autoskip=yes    
     #32 @77  FIN 1 attr=underline color=yellow 
  group=niveau2d
     #27 @10 "Effectif de la population de niveau 1 : " color=white " POPMEN = "
              POPMEN 15 attr=rev_video color=white autoskip=yes   
     #32 @77  FIN 1 attr=underline color=yellow  ;

%window fenetre6 color=blue
 group=niveau3
     #3  @5  "Données de niveau Kish (échantillon du 2ème degré)" color=yellow attr=underline
     #11 @7 "Nom de la table d'enquête : " color=white "DATAKISH = "
              DATAKISH 41 attr=rev_video color=white autoskip=yes
     #14 @7 "Nom de la variable contenant les poids de sondage au 2ème degré : " color=white
             "POIDKISH = " POIDKISH 16  attr=rev_video color=white autoskip=yes
     #17 @7 "Nom de la table de marges : " color=white " MARKISH = "
              MARKISH 41 attr=rev_video color=white autoskip=yes
     #28 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 
 group=niveau3b
     #22 @7 "Nom de la variable identifiant les observations dans la table Kish : "
             color=white "IDENT2 = "
             IDENT2 32  attr=rev_video color=white autoskip=yes
     #32 @77  FIN 1 attr=underline color=yellow autoskip=yes  

 group=niveau3C
     #25 @7 "Effectif de la population : " color=white " POPKISH = "
              POPKISH 15 attr=rev_video color=white autoskip=yes 
     #32 @77  FIN 1 attr=underline color=yellow  ;

%window fenetre7 color=blue
 group=met1
 	 #3  @5  "Méthode de calage" color=yellow attr=underline
	 #6  @15 "Souhaitez-vous redresser la non-réponse par calage généralisé ?" color=white
	 #7  @15 "Réponse=OUI ou NON" color=white "   NONREP = " 
	          NONREP 3 attr=rev_video color=white required=yes autoskip=yes
     #10 @15 "Choisissez la fonction de calage à utiliser parmi les suivantes :" color=white
	 #12 @25 "1=méthode linéaire" color=white 
	 #13 @25 "2=raking-ratio" color=white 
	 #14 @25 "3=méthode logit" color=white 
	 #15 @25 "4=méthode linéaire tronquée" color=white 
	 #16 @25 "5=sinus hyperbolique" color=white 
	 #18 @15 "Votre choix : " color=white "M = "
	          M 1 attr=rev_video color=white required=yes autoskip=yes
     #29 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 

 group=met2
	 #20 @15 "Borne inférieure : " color=white "LO = "
	         LO 8 attr=rev_video color=white autoskip=yes
	 #21 @15 "Borne supérieure : " color=white "UP = "
	         UP 8 attr=rev_video color=white autoskip=yes
     #32 @77  FIN 1 attr=underline color=yellow  

 group=met3
     #20 @15 "Coefficient alpha : " color=white "ALPHA = "
	         ALPHA 8 attr=rev_video color=white required=yes autoskip=yes
     #32 @77  FIN 1 attr=underline color=yellow 

 group=met4
     #23 @10 "Facteur d'échelle (constante numérique. 0 en cas de redressement uniforme de la non-réponse) : "
             color=white
	 #24 @15 "ECHELLE = "  ECHELLE 8 attr=rev_video color=white required=yes autoskip=yes
     #32 @77  FIN 1 attr=underline color=yellow  

 group=met4b
     #25 @10 "Effectif de la population" color=white
     #26 @10 "(entités de niveau 1 en cas de calage simultané ou si EGALPOI=OUI)"
              color=white
     #27 @15  "POPMEN = " POPMEN 15 attr=rev_video color=white autoskip=yes  
     #32 @77  FIN 1 attr=underline color=yellow  ;

%window fenetre8 color=blue
 	 #5  @5   "Méthode de calage (fin)" color=yellow attr=underline
     #8  @15  "Valeur du critère d'arret (constante numérique) : " color=white
     #10  @20 "SEUIL = " SEUIL 8 attr=rev_video color=white autoskip=yes required=yes
     #13 @15  "Nombre maximum d'itérations souhaité : " color=white
     #15 @20  "MAXITER = " MAXITER 2 attr=rev_video color=white autoskip=yes required=yes
     #18 @15  "Avez-vous des colinérités entre vos variables de calage (réponse=OUI ou NON) : "
              color=white
     #20 @20  "COLIN = " COLIN 3 attr=rev_video color=white autoskip=yes required=yes  
     #28 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow ;

%window fenetre9 color=blue
 group=poids1
     #4  @5  "Stockage des poids de calage associés aux unités de niveau 1" color=yellow
	         attr=underline
     #6  @10  "Nom de la table qui contiendra les poids de calage : " color=white 
     #7  @15 " DATAPOI = "  DATAPOI 41 attr=rev_video color=white autoskip=yes
     #29 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 

 group=poids2
     #9 @5  "Stockage des poids de calage associés aux unités de niveau 2" color=yellow
	         attr=underline
     #11 @10  "Nom de la table qui contiendra les poids de calage : " color=white 
     #12 @15 "DATAPOI2 = "  DATAPOI2 41 attr=rev_video color=white autoskip=yes
     #29 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow 

 group=poids3
     #14 @5  "Stockage des poids de calage associés aux unités Kish" color=yellow
	         attr=underline
     #16 @10  "Nom de la table qui contiendra les poids de calage : " color=white 
     #17 @15 "DATAPOI3 = "  DATAPOI3 41 attr=rev_video color=white autoskip=yes
     #32 @77  FIN 1 attr=underline color=yellow  

 group=poids4
     #20 @10 "Nom de la variable qui contiendra les poids de calage des unités de niveau 1 : "
              color=white
     #21 @15 "POIDSFIN = " POIDSFIN 32  attr=rev_video color=white autoskip=yes
     #23 @10 "Label associé au nom de cette variable : "
              color=white
     #24 @15  "LABELPOI = " LABELPOI 30  attr=rev_video color=white autoskip=yes
     #26 @10 "Si la (les) table(s) de poids existe(nt) déjà, souhaitez-vous conserver" color=white
             " l'information existante ? " color=white
     #27 @15 "réponse=OUI ou NON"  color=white "  MISAJOUR = "
              MISAJOUR 3  attr=rev_video color=white autoskip=yes
     #29 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow ;

%window fenetre9b color=blue
     #5 @10 "Nom de la variable qui contiendra le poids de calage total des unités Kish"
              color=white
     #6 @10 "dans la table &datapoi3 :" color=white
     #8 @15 "POIDSKISHFIN = " POIDSKISHFIN 32  attr=rev_video color=white autoskip=yes
     #12 @10 "Label associé au nom de cette variable : "
              color=white
     #14 @15  "LABELPOIKISH = " LABELPOIKISH 30  attr=rev_video color=white autoskip=yes
     #29 @30  "Faire ENTREE pour continuer"                      color=yellow 
     #30 @30  "Pour valider l'écran sans ressaisie, taper V"     color=yellow 
     #31 @30  "Pour revenir sur l'écran précédent, taper  R"     color=yellow 
     #32 @30  "Pour quitter l'application, taper          F : "  color=yellow 
           FIN 1 attr=underline color=yellow ;

%window fenetre10 color=blue
 group=edit1
     #1  @5  "Edition des résultats du calage" color=yellow attr=underline
     #3  @5  "Souhaitez-vous conserver dans une table SAS les observations éliminées ? (réponse=OUI ou NON)"
	         color=white
	 #4  @27 "OBSELI = "  @36 OBSELI 3 attr=rev_video color=white required=yes autoskip=yes
	 #6  @5  "Souhaitez-vous disposer de statistiques sur les poids de calage obtenus ? (réponse=OUI ou NON)"
	         color=white
	 #8 @29 "STAT = " @36 STAT 3 attr=rev_video color=white required=yes autoskip=yes
	 #10 @5  "Quel niveau de détail souhaitez-vous pour l'édition des résultats ?"
             color=white
	 #12 @7  "0 : aucun résultat n'est édité, sauf les statistiques sur les poids, si elles sont demandées"
             color=white
	 #13 @7  "1 : le programme édite la liste des paramètres rentrés par l'utilisateur et le bilan du calage"
             color=white
	 #14 @7  "2 : le programme édite la liste des paramètres, les tables de marges et le bilan du calage"
             color=white
	 #15 @7  "3 : memes éditions qu'en 2 avec en plus la valeur des coefficients lambda et du critère d'arret" 
             color=white
	 #17 @5  "Votre choix : " color=white @26 "EDITION = "
         @36 EDITION 1 attr=rev_video color=white required=yes autoskip=yes
 	 #19 @5  "Souhaitez-vous une édition détaillée des rapports de poids par croisement de variable ?"
	         color=white
     #21 @5  "Réponse=OUI ou NON"  color=white @23 "   EDITPOI = "  
	     @36 EDITPOI 3 attr=rev_video color=white required=yes autoskip=yes
 	 #23 @5  "Souhaitez-vous un controle de vos paramètres par le programme (réponse=OUI ou NON)" 
             color=white
     #24 @29 "CONT = " @36 CONT 3 attr=rev_video color=white required=yes autoskip=yes
 	 #26 @5  "Souhaitez-vous avoir les notes produites par SAS dans le fichier LOG ? (réponse=OUI ou NON)" 
             color=white
     #27 @28 "NOTES = " @36  NOTES 3 attr=rev_video color=white required=yes autoskip=yes
     #31 @5  "Pour valider l'écran, taper V ;pour revenir sur l'écran précédent, taper  R ; "
             color=yellow 
     #32 @5  "pour quitter l'application, taper F : " color=yellow 
              FIN 1 attr=underline color=yellow 

 group=edit2
 	 #29 @5 "Souhaitez-vous éditer le contenu de la table des poids de calage ? (Réponse=OUI ou NON)"  
             color=white
     #30 @26 "CONTPOI = " @36 CONTPOI 3 attr=rev_video color=white required=yes autoskip=yes 
     #32 @43   FIN 1 attr=underline color=yellow  ;

%window fenetre11 color=blue
 #13 @38 "***************"  color=white
 #14 @38 "*             *"  color=white
 #15 @38 "* ATTENTION ! *"  color=white
 #16 @38 "*             *"  color=white
 #17 @38 "***************"  color=white
 #25 @10 "Tous les paramètres ont été saisis."  color=white
 #28 @10 "Si vous souhaitez faire exécuter le calage, faire Entrée ou taper V"     color=white
 #30 @10 "Si vous souhaitez abandonner l'application sans l'exécuter, taper F"     color=white
 #32 @10 "Si vous souhaitez revenir à l'écran précédent, taper              R : "  color=white
         FIN 1 attr=underline color=white ;


	 /* AFFICHAGE DES FENETRES POUR SAISIE DES PARAMETRES */

%let simul= ;
%let sim1= ; 
%let sim2= ;
%let sim3= ;

%f1:  
  %let fin= ;
  %display fenetre1 ;
   %if %upcase(&fin)=F %then %goto fin;
%f1b:
  %let fin= ;
  %display fenetre1b;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then %goto f1;

%f2a:
  %let fin= ;
  %display fenetre2.g1;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then %goto f1b;

  %if %upcase(&simul) ne OUI and %upcase(&simul) ne NON %then 
  %do;
    %display erreur1;
	%goto f2a;
  %end;

  %IF %upcase(&SIMUL)=NON %THEN 
  %DO;
	%let datakish= ; 
	%let markish= ; 
	%let poidkish= ; 
	%let datapoi3= ;
	%let poidskishfin= ; 
	%let labelpoikish= ; 
	%let popkish= ;
    %let sim1=%str( );
    %let sim2=%str( );
    %let sim3=%str( );
%f3:
      %let fin= ;
      %display fenetre3;
       %if %upcase(&fin)=F %then %goto fin;
       %if %upcase(&fin)=R %then %goto f2a;
  %END;

  %IF %upcase(&SIMUL)=NON AND %upcase(&EGALPOI) NE OUI %THEN
  %DO;
    %let dataind= ;%let marind= ;%let datakish= ;%let markish= ;%let datapoi2= ;%let datapoi3= ;
	%let ident2= ;%let poidkish= ;	%let popind= ;%let popkish= ;

%f4:
     %let fin= ;
     %display fenetre4.niveau1;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f3;
	 %if %upcase(&pct) ne OUI %then %let popmen= ;
     %if %upcase(&pct)=OUI %then %display fenetre4.niveau1b;
  %END;

  %ELSE %IF %upcase(&SIMUL)=NON AND %upcase(&EGALPOI)=OUI %THEN
  %DO;
     %let datamen= ;%let marmen= ;%let datakish= ;%let markish= ;%let datapoi= ;%let datapoi3= ;
	 %let poidkish= ;%let popkish= ;

%f5:
     %let fin= ;
     %display fenetre5.niveau2;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f3;
     %let fin= ;
     %display fenetre5.niveau2b ;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f3;
	  %if %upcase(&pct) ne OUI %then %let popind= ;
     %let fin= ;
     %if %upcase(&pct)=OUI %then %display fenetre5.niveau2c;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f3;
     %let fin= ;
     %display fenetre5.niveau2d ;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f3;
  %END;

  %IF %upcase(&SIMUL)=OUI  %THEN
  %DO;
%f2b:
    %let fin= ;
	%let egalpoi= ;
    %display fenetre2.g2;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f2a;

	%if (%upcase(&sim1) ne OUI and %upcase(&sim1) ne NON and &sim1 ne %str( )) 
        or (%upcase(&sim2) ne OUI and %upcase(&sim2) ne NON and &sim2 ne %str( )) 
	    or (%upcase(&sim3) ne OUI and %upcase(&sim3) ne NON and &sim3 ne %str( )) %then
	%do;
	  %display erreur2;
	  %goto f2b;
	%end;
    
	%let nni=0 ;
	%do ni=1 %to 3;
	  %if %upcase(&&sim&ni)=OUI %then %let nni=%eval(&nni+1);
	%end;
	%if &nni<2 %then
	%do;
	  %display erreur3;
	  %goto f2b;
	%end;

    %if %upcase(&sim2) ne OUI %then 
    %do;
	   %let dataind= ;%let marind= ;%let datapoi2= ;%let popind= ;
	%end;
    %if %upcase(&sim3) ne OUI %then 
    %do;
		%let datakish= ;%let markish= ;%let poidkish= ;%let popkish= ;%let datapoi3= ;
		%let poidskishfin= ; %let labelpoikish= ;
    %end;
    %if %upcase(&sim2) ne OUI and %upcase(&sim3) ne OUI %then %let ident2= ;
%f4a:
    %let fin= ;
    %display fenetre4.niveau1;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f2b;
	 %if %upcase(&pct) ne OUI %then
	 %do;
	    %let popmen= ; %let popind= ;%let popkish= ;
	 %end;
%f4ab:
    %if %upcase(&pct)=OUI %then 
    %do;
     %display fenetre4.niveau1b;
      %if %upcase(&fin)=F %then %goto fin;
      %if %upcase(&fin)=R %then %goto f4a;
    %end;
 
    %if %upcase(&SIM2)=OUI %then
    %do;
%f5a:
      %let fin= ;
      %display fenetre5.niveau2;
       %if %upcase(&fin)=F %then %goto fin;
       %if %upcase(&fin)=R and %upcase(&sim1)=OUI %then %goto f4a;
       %if %upcase(&fin)=R and %upcase(&egalpoi)=OUI %then %goto f4;
      %if %upcase(&pct)=OUI %then 
      %do;
%f5c:
        %let fin= ;
        %display fenetre5.niveau2c;
         %if %upcase(&fin)=F %then %goto fin;
         %if %upcase(&fin)=R %then %goto f5a;
      %end;
    %end;

    %if %upcase(&SIM3)=OUI  %then
    %do;
%f6a:
        %let fin= ;
        %display fenetre6.niveau3;
         %if %upcase(&fin)=F %then %goto fin;
         %if %upcase(&fin)=R %then 
         %do;
           %if %upcase(&sim2)=OUI %then %goto f5a;
		   %else %goto f4a;
		 %end;

        %if %upcase(&sim2) ne OUI %then 
        %do;
%f6b:
          %let fin= ;
          %display fenetre6.niveau3b;
           %if %upcase(&fin)=F %then %goto fin;
           %if %upcase(&fin)=R %then %goto f6a;
        %end;

        %if %upcase(&pct)=OUI %then 
        %do;
%f6c:
            %let fin= ;
            %display fenetre6.niveau3c;
              %if %upcase(&fin)=F %then %goto fin;
              %if %upcase(&fin)=R %then 
              %do;
                 %if %upcase(&sim2) ne OUI %then %goto f6b;
				 %else %goto f6a;
			  %end;
		%end;
    %end;

  %END;

%f7a:
  %let fin= ;
  %display fenetre7.met1;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then 
   %do;
	 %if %upcase(&sim3)=OUI %then %goto f6a;
	 %else %if %upcase(&egalpoi)=OUI %then %goto f5;
     %else %if %upcase(&sim2)=OUI %then %goto f5a;
     %else %if %upcase(&simul)=NON and %upcase(&egalpoi) ne OUI %then %goto f4;
   %end;
   %if &m ne 3 and &m ne 4 %then 
   %do;
      %let lo= ;%let up= ;
   %end;
   %if &m ne 5 %then %let alpha= ;

  %if &m=3 or &m=4 %then 
  %do;
%f7b:
    %let fin= ;
    %display fenetre7.met2;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f7a;
  %end;

  %if &m=5 %then 
  %do;
%f7c:
    %let fin= ;
    %display fenetre7.met3;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f7a;
  %end;

  %let fin= ;
%f7d:
  %display fenetre7.met4;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then 
   %do;
     %if &m=3 or &m=4 %then %goto f7b;
	 %else %if &m=5 %then %goto f7c;
	 %else %goto f7a;
   %end;
  %if &echelle=0 and &popmen=%str( ) %then 
  %do;
    %let fin= ;
    %display fenetre7.met4b;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f7d;
  %end;
%f8:
  %let fin= ;
  %display fenetre8;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then %goto f7a;
%f9a:
  %if &datamen ne %str( ) %then 
  %do;
    %let fin= ;
    %display fenetre9.poids1;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f8;
  %end;
  %if %upcase(&egalpoi)=OUI or %upcase(&sim2)=OUI %then 
  %do;
%f9b:
    %let fin= ;
    %display fenetre9.poids2;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then
     %do;
       %if %upcase(&sim1)=OUI %then %goto f9a;
	   %else %goto f8;
	 %end;
  %end;
  %if %upcase(&sim3)=OUI %then
  %do;
%f9c:
    %let fin= ;
    %display fenetre9.poids3;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then
     %do;
       %if %upcase(&sim2)=OUI %then %goto f9b;
	   %else %if %upcase(&sim1)=OUI %then %goto f9a;
	 %end;
  %end;

  %if &datapoi=%str( ) and &datapoi2=%str( ) and &datapoi3=%str( ) %then 
  %do;
     %let poidsfin= ; %let labelpoi= ; %let contpoi=non; %let misajour= ;
  %end;

  %if &datapoi ne %str( ) or &datapoi2 ne %str( ) or &datapoi3 ne %str( ) %then 
  %do;
%f9d:
    %let fin= ;
    %display fenetre9.poids4;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then
     %do;
       %if %upcase(&sim3)=OUI %then %goto f9c;
       %else %if %upcase(&sim3) ne OUI and %upcase(&sim2)=OUI %then %goto f9b;
	   %else %if %upcase(&simul)=NON %then %goto f9a;
	 %end;
  %end;

  %if &datapoi3 ne %str( ) %then 
  %do;
%f9e:
    %let fin= ;
    %display fenetre9b;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f9d;
  %end;

%f10:
  %let fin= ;
  %display fenetre10.edit1;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R and (&datapoi ne %str( ) or &datapoi2 ne %str( ) or &datapoi3 ne %str( ))
       %then %goto f9d;
   %else %if %upcase(&fin)=R and &datapoi=%str( ) and &datapoi2=%str( ) and &datapoi3=%str( ) 
       %then %goto f9a;

  %if &datapoi ne %str( ) or &datapoi2 ne %str( )  or &datapoi3 ne %str( ) %then 
  %do;
    %let fin= ;
    %display fenetre10.edit2;
     %if %upcase(&fin)=F %then %goto fin;
     %if %upcase(&fin)=R %then %goto f10;
  %end;

  %let fin= ;
  %display fenetre11;
   %if %upcase(&fin)=F %then %goto fin;
   %if %upcase(&fin)=R %then %goto f10;


         /***  FIN DE LA SAISIE DES PARAMÈTRES  ***/

     
%IF %UPCASE(&NOTES) = OUI %THEN
%DO;
  OPTIONS NOTES;
%END;


    /********************************************
     ***  EDITION DES PARAMÈTRES DE LA MACRO  ***
     ********************************************/

%IF &EDITION>=1 %THEN
%DO;

DATA _NULL_;
  FILE PRINT;
  PUT //@28 "**********************************";
  PUT   @28 "***   PARAMÈTRES DE LA MACRO   ***";
  PUT   @28 "**********************************";
  PUT //@2 "TABLE(S) EN ENTRÉE :";
  PUT   @2 " TABLE DE DONNÉES DE NIVEAU 1              DATAMEN   =  %UPCASE(&DATAMEN)";
  PUT   @2 "    IDENTIFIANT DU NIVEAU 1                IDENT     =  %UPCASE(&IDENT)";
  PUT   @2 " TABLE DE DONNÉES DE NIVEAU 2              DATAIND   =  %UPCASE(&DATAIND)";
  PUT   @2 "    IDENTIFIANT DU NIVEAU 2                IDENT2    =  %UPCASE(&IDENT2)";
  PUT   @2 " TABLE DES INDIVIDUS KISH                  DATAKISH  =  %UPCASE(&DATAKISH)";
  PUT   @2 " PONDÉRATION INITIALE                      POIDS     =  %UPCASE(&POIDS)";
  PUT   @2 " FACTEUR D'ÉCHELLE                         ECHELLE   =  &ECHELLE";
  PUT   @2 " PONDÉRATION QK                            PONDQK    =  %UPCASE(&PONDQK)";
  PUT   @2 " PONDÉRATION KISH                          POIDKISH  =  %UPCASE(&POIDKISH)";
%IF %UPCASE(&SIMUL)=NON %THEN %DO;
  PUT   @2 " ÉGALITÉ DES POIDS DANS UN MÉNAGE          EGALPOI   ="
        %IF %UPCASE(&EGALPOI)=OUI %THEN @58 "OUI" ;
		%ELSE                           @58 "NON" ; ;
%END;
  PUT  /@2 "TABLE(S) DES MARGES :";
  PUT   @2 " DE NIVEAU 1                               MARMEN    =  %UPCASE(&MARMEN)";
  PUT   @2 " DE NIVEAU 2                               MARIND    =  %UPCASE(&MARIND)";
  PUT   @2 " DE NIVEAU KISH                            MARKISH   =  %UPCASE(&MARKISH)";
  PUT   @2 " MARGES EN POURCENTAGES                    PCT       =  %UPCASE(&PCT)";
  PUT   @2 " EFFECTIF DANS LA POPULATION :";
  PUT   @2 "  DES ÉLÉMENTS DE NIVEAU 1                 POPMEN    =  &POPMEN";
  PUT   @2 "  DES ÉLÉMENTS DE NIVEAU 2                 POPIND    =  &POPIND";
  PUT   @2 "  DES ÉLÉMENTS KISH                        POPKISH   =  &POPKISH";
%IF %UPCASE(&NONREP)=OUI %THEN
%DO;
  PUT  /@2 "REDRESSEMENT DE LA NON-RÉPONSE DEMANDÉ :   NONREP    =  &NONREP";
%END;
  PUT  /@2 "MÉTHODE UTILISÉE                           M         =  &M";
  PUT   @2 " BORNE INFÉRIEURE                          LO        =  &LO";
  PUT   @2 " BORNE SUPÉRIEURE                          UP        =  &UP";
  PUT   @2 " COEFFICIENT DU SINUS HYPERBOLIQUE         ALPHA     =  &ALPHA";
  PUT   @2 " SEUIL D'ARRÊT                             SEUIL     =  &SEUIL";
  PUT   @2 " NOMBRE MAXIMUM D'ITÉRATIONS               MAXITER   =  &MAXITER";
  PUT   @2 " TRAITEMENT DES COLINÉARITÉS               COLIN     =  &COLIN";
  PUT  /@2 "TABLE(S) CONTENANT LA POND. FINALE";
  PUT   @2 " DE NIVEAU 1                               DATAPOI       =  %UPCASE(&DATAPOI)";
  PUT   @2 " DE NIVEAU 2                               DATAPOI2      =  %UPCASE(&DATAPOI2)";
  PUT   @2 " DE NIVEAU KISH                            DATAPOI3      =  %UPCASE(&DATAPOI3)";
  PUT   @2 " MISE À JOUR DE(S) TABLE(S) DATAPOI(2)(3)  MISAJOUR      =  %UPCASE(&MISAJOUR)";
  PUT   @2 " PONDÉRATION FINALE DES UNITES 1 ET 2      POIDSFIN      =  %UPCASE(&POIDSFIN)";
  PUT   @2 " LABEL DE LA PONDÉRATION FINALE            LABELPOI      =  %UPCASE(&LABELPOI)";
  PUT   @2 " PONDÉRATION FINALE DES UNITES KISH        POIDSKISHFIN  =  %UPCASE(&POIDSKISHFIN)";
  PUT   @2 " LABEL DE LA PONDÉRATION KISH              LABELPOIKISH  =  %UPCASE(&LABELPOIKISH)";
  PUT   @2 " CONTENU DE(S) TABLE(S) DATAPOI(2)(3)      CONTPOI       =  %UPCASE(&CONTPOI)";
  PUT  /@2 "ÉDITION DES RÉSULTATS                      EDITION       =  &EDITION";
  PUT   @2 " ÉDITION DES POIDS                         EDITPOI       =  %UPCASE(&EDITPOI)";
  PUT   @2 " STATISTIQUES SUR LES POIDS                STAT          =  %UPCASE(&STAT)";
  PUT  /@2 "CONTRÔLES                                  CONT          =  %UPCASE(&CONT)";
  PUT   @2 "TABLE CONTENANT LES OBS. ÉLIMINÉES         OBSELI        =  %UPCASE(&OBSELI)";
  PUT   @2 "NOTES SAS                                  NOTES         =  %UPCASE(&NOTES)";

%END;


**************************************************************************;
********       DÉTERMINATION DU TYPE DE CALAGE DEMANDÉ          **********;
**************************************************************************;


      %IF &DATAMEN NE %STR() AND &DATAIND=   %STR() AND &DATAKISH=%STR() %THEN %LET TYP=1;
%ELSE %IF &DATAMEN=   %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR()
                                            AND %UPCASE(&EGALPOI) NE OUI %THEN %LET TYP=2;
%ELSE %IF &DATAMEN=   %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR()
                                            AND %UPCASE(&EGALPOI)=OUI    %THEN %LET TYP=2B;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND NE %STR() AND &DATAKISH=%STR() %THEN %LET TYP=3;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND=   %STR() AND &DATAKISH NE %STR()
                                                                         %THEN %LET TYP=4;
%ELSE %IF &DATAMEN NE %STR() AND &DATAIND NE %STR() AND &DATAKISH NE %STR()
                                                                         %THEN %LET TYP=5;


 /**************************************************************************
  ***      CONTROLES SUR LES PARAMETRES RENTRES PAR L'UTILISATEUR        ***
  **************************************************************************/

  /***** PRÉSENCE DES PARAMÈTRES LIÉS À UNE TABLE DE DONNÉES *******/

%IF &DATAMEN=%STR() AND &DATAIND=%STR() AND &DATAKISH=%STR() %THEN %DO;
DATA _NULL_ ;
     FILE PRINT;
     PUT @8 68*"*";
     PUT @8 "***** ERREUR : AUCUN NOM DE TABLE DE DONNÉES N'EST RENSEIGNÉ ! *****";
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
	   PUT "** ERREUR : le paramètre DATAIND contenant le nom de la table de données "     
           "de niveau 2" @92 "**";
       PUT "**          n'est pas renseigné alors que le paramètre EGALPOI vaut OUI." 
           @92 "**";
	   PUT "**"  @92 "**";
	   PUT "** EGALPOI=OUI signifie que vous avez un sondage en grappes et que vous "
	       "souhaitez conserver *";
       PUT "** des poids égaux dans une meme unité primaire malgré l'absence de données "
           "au niveau de" @92 "**";
       PUT "** l'unité primaire. Ce sont les paramètres de niveau 2 qui doivent etre renseignés" 
           @92 "**";
	   PUT 93*"*";
   %END;
  %IF &MARIND= %THEN 
  %DO;
     %LET EREGAL=1;
     DATA _NULL_;
	   FILE PRINT;
	   PUT 93*"*";
	   PUT "** ERREUR : le paramètre MARIND contenant le nom de la table de marges " 
           "de niveau 2" @92 "**";
       PUT "**          n'est pas renseigné alors que le paramètre EGALPOI vaut OUI." 
           @92 "**";
	   PUT "**"  @92 "**";
	   PUT "** EGALPOI=OUI signifie que vous avez un sondage en grappes et que vous "
	       "souhaitez conserver *";
       PUT "** des poids égaux dans une meme unité primaire malgré l'absence de données "
           "au niveau de" @92 "**";
       PUT "** l'unité primaire. Ce sont les paramètres de niveau 2 qui doivent etre renseignés" 
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
 PUT @2 "*** ERREUR : L'IDENTIFIANT IDENT DES DONNÉES DE NIVEAU 1 N'EST PAS RENSEIGNÉ ***";
 PUT @2 "***          ALORS QUE VOUS DEMANDEZ UN CALAGE SIMULTANE                     ***";
 PUT @2 80*"*";
%GOTO FIN;
%END;

%IF &IDENT2=%STR() AND &DATAIND NE %STR()  %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 79*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 DES DONNÉES DE NIVEAU 2 N'EST PAS RENSEIGNÉ **";
 PUT @2 "**          ALORS QUE LE PARAMÈTRE DATAIND EST RENSEIGNÉ                     **";
 PUT @2 79*"*";
%GOTO FIN;
%END;

%IF &IDENT2=%STR() AND &DATAKISH NE %STR() %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 85*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 DES DONNÉES DE NIVEAU KISH N'EST PAS RENSEIGNÉ"
     @85 "**";
 PUT @2 "**          ALORS QUE LE PARAMÈTRE DATAKISH EST RENSEIGNÉ"  @85 "**";
 PUT @2 85*"*";
%GOTO FIN;
%END;

%IF &IDENT NE %STR() AND &IDENT2 NE %STR() AND &IDENT=&IDENT2 %THEN
%DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 71*"*";
 PUT @2 "** ERREUR : L'IDENTIFIANT IDENT2 (=&IDENT2) DES DONNÉES DE NIVEAU 2 EST LE MÊME **";
 PUT @2 "**          QUE L'IDENTIFIANT IDENT (=&IDENT) DES DONNÉES DE NIVEAU 1           **";
 PUT @2 71*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &DATAMEN=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 68*"*";
 PUT @2 "***** ERREUR : UN NOM DE TABLE DE DONNÉES KISH EST RENSEIGNÉ   *****";
 PUT @2 "*****          MAIS PAS LE NOM DE LA TABLE DE DONNÉES DATAMEN  *****";
 PUT @2 68*"*";
%GOTO FIN;
%END;

%IF &DATAMEN NE %STR() AND &MARMEN=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 69*"*";
 PUT @2 "***                        ERREUR :"                         @68 "***";
 PUT @2 "*** LE NOM DE LA TABLE DES MARGES MARMEN N'EST PAS RENSEIGNÉ      ***";
 PUT @2 "*** ALORS QU'UNE TABLE DE DONNÉES DATAMEN : &DATAMEN EST INDIQUÉE ***";
 PUT @2 69*"*";
%GOTO FIN;
%END;

%IF &DATAIND NE %STR() AND &MARIND=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @2 69*"*";
 PUT @2 "***                        ERREUR :"                         @68 "***";
 PUT @2 "*** LE NOM DE LA TABLE DES MARGES MARIND N'EST PAS RENSEIGNÉ      ***";
 PUT @2 "*** ALORS QU'UNE TABLE DE DONNÉES DATAIND : &DATAIND EST INDIQUÉE ***";
 PUT @2 69*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &MARKISH=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @8 66*"*";
 PUT @8 "***                        ERREUR :"                            @71 "***";
 PUT @8 "*** LE NOM DE LA TABLE DES MARGES DES INDIVIDUS-KISH (MARKISH)" @71 "***";
 PUT @8 "*** N'EST PAS RENSEIGNÉ"                                        @71 "***";
 PUT @8 "*** ALORS QU'UNE TABLE DE DONNÉES INDIVIDUS-KISH EST INDIQUÉE"  @71 "***";
 PUT @8 66*"*";
%GOTO FIN;
%END;

%IF &DATAKISH NE %STR() AND &POIDKISH=%STR() %THEN %DO;
DATA _NULL_ ;
 FILE PRINT;
 PUT @8 74*"*";
 PUT @8 "*** ERREUR : LA VARIABLE DE PONDÉRATION POIDKISH N'EST PAS RENSEIGNÉE  ***";
 PUT @8 "***          ALORS QU'UNE TABLE DE DONNÉES INDIVIDUS-KISH EST INDIQUÉE ***";
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
 PUT @8 "*** ERREUR : LA VARIABLE DE PONDÉRATION INITIALE POIDS N'EST PAS RENSEIGNÉE ***";
 PUT @8 "***          LA PRÉSENCE DE LA PONDÉRATION INITIALE DANS LA TABLE DATAIND   ***";
 PUT @8 "***          EST OBLIGATOIRE QUAND EGALPOI=OUI                              ***";
 PUT @8 79*"*";
%GOTO FIN;
%END;



   /*************************************************************************
    ***  CONTROLES LORSQUE L'ON VEUT CONSERVER LES PONDÉRATIONS FINALES   ***
    *************************************************************************/

%IF &DATAMEN NE %STR( ) AND &POIDSFIN NE %STR( )
                         AND &DATAPOI=%STR( ) %THEN
%DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 "*************************************************************"
                 "**************";
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI N'EST PAS RENSEIGNE ALORS QUE"
                      @74 "***";
        PUT @2 "***   LE CALAGE DEMANDÉ IMPLIQUE UN NIVEAU 1 ET QUE LE STOCKAGE "
                      @74 "***";
        PUT @2 "***   DES POIDS EST DEMANDÉ (POIDSFIN=%UPCASE(&POIDSFIN))"
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
      PUT @2 "***   ERREUR : LE PARAMÈTRE POIDSFIN N'EST PAS RENSEIGNÉ"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAMÈTRE DATAPOI"
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
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI VAUT %UPCASE(&DATAPOI),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOUÉE AU DDNAME"
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
        %PUT %STR( ***   ERREUR : PAS D%'ACCÈS EN ÉCRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOUÉE AU DDNAME %UPCASE(&BASE1) )      ;
        %PUT %STR( ***            SPÉCIFIÉ DANS LE PARAMÈTRE DATAPOI ) ;
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
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI2 N'EST PAS RENSEIGNE ALORS QUE"
                      @74 "***";
        PUT @2 "***   LE CALAGE DEMANDÉ IMPLIQUE UN NIVEAU 2 ET QUE LE STOCKAGE "
                      @74 "***";
        PUT @2 "***   DES POIDS EST DEMANDÉ (POIDSFIN=%UPCASE(&POIDSFIN))"
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
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI3 N'EST PAS RENSEIGNE ALORS QUE"
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
      PUT @2 "***   ERREUR : LE PARAMÈTRE POIDSFIN N'EST PAS RENSEIGNÉ"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAMÈTRE DATAPOI2"
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
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI2 VAUT %UPCASE(&DATAPOI2),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOUÉE AU DDNAME"
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
        %PUT %STR( ***   ERREUR : PAS D%'ACCÈS EN ÉCRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOUÉE AU DDNAME %UPCASE(&BASE2) )      ;
        %PUT %STR( ***            SPÉCIFIÉ DANS LE PARAMÈTRE DATAPOI2 ) ;
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

  %IF &POIDSFIN = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 66*"*";
      PUT @2 "***   ERREUR : LE PARAMÈTRE POIDSFIN N'EST PAS RENSEIGNÉ"
          @65"***";
      PUT @2 "***            ALORS QUE LE PARAMÈTRE DATAPOI3"
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
        PUT @2 "***   ERREUR : LE PARAMÈTRE DATAPOI3 VAUT %UPCASE(&DATAPOI3),"
               " MAIS"  @67 "***";
        PUT @2 "***            AUCUNE BASE N'EST ALLOUÉE AU DDNAME"
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
        %PUT %STR( ***   ERREUR : PAS D%'ACCÈS EN ÉCRITURE SUR LA BASE ) ;
        %PUT %STR( ***            ALLOUÉE AU DDNAME %UPCASE(&BASE3) )      ;
        %PUT %STR( ***            SPÉCIFIÉ DANS LE PARAMÈTRE DATAPOI3 ) ;
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
   *** CONTRÔLE DU PARAMÈTRE ECHELLE ***
   *************************************/

%IF %DATATYP(&ECHELLE) NE NUMERIC AND &ECHELLE NE %STR( ) %THEN
%DO;
 DATA _NULL_;
   FILE PRINT;
   PUT @2 71*"*";
   PUT @2 "*** ERREUR : LE COEFFICIENT MULTIPLICATIF DES POIDS INITIAUX RENTRÉ ***";
   PUT @2 "***          DANS LE PARAMÈTRE ECHELLE N'EST PAS NUMÉRIQUE" @70 "***";
   PUT @2 "***          ECHELLE VAUT &ECHELLE" @70 "***";
   PUT @2 71*"*";
 %GOTO FIN;
%END;


 /**************************************************************************
  **** VÉRIFICATION DE LA COHÉRENCE DE LA DEMANDE EN CAS DE NON-RÉPONSE ****
  **************************************************************************/

%IF %UPCASE(&NONREP)=OUI AND &ECHELLE NE 1 AND &ECHELLE NE %STR( ) %THEN
%DO;
   DATA _NULL_;
     FILE PRINT;
      PUT // @2 69*"*";
      PUT    @2 "* ERREUR : VOUS DEMANDEZ UN REDRESSEMENT UNIFORME DE LA NON-RÉPONSE *";
      PUT    @2 "*          (LE PARAMÈTRE ECHELLE VAUT &ECHELLE)" @70 "*";
      PUT    @2 "*          ET UN REDRESSEMENT DE NON-RÉPONSE PAR CALAGE GÉNÉRALISÉ  *";
      PUT    @2 "*          (LE PARAMÈTRE NONREP VAUT &NONREP)"   @70 "*";
      PUT    @2 "*          LES DEUX OPTIONS SONT INCOMPATIBLES"  @70 "*";
      PUT    @2 69*"*";
 %GOTO FIN;
%END;


                        /*************************
                         * CONTRÔLES FACULTATIFS *
                         *************************/

 /**************************************************************************
  **** VÉRIFICATION DE L'EXISTENCE DES TABLES DE DONNÉES ET DE MARGES ******
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
  **** VÉRIFICATION DE L'EXISTENCE DES VARIABLES ******
  ****  DANS LES TABLES DE DONNÉES ET DE MARGES  ******
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
                * CONTROLES SUR LE PARAMÈTRE M  *
                *********************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

  %IF &M NE 1 AND &M NE 2 AND &M NE 3 AND &M NE 4 AND &M NE 5 %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "******************************************************";
      PUT   @2 "***   ERREUR : LA VALEUR DU PARAMÈTRE M (&M)       ***";
      PUT   @2 "***            EST DIFFÉRENTE DE 1, 2, 3, 4 ET 5   ***";
      PUT   @2 "******************************************************";
    %GOTO FIN;
  %END;

  %IF (&M=3 OR &M=4) AND %SCAN(&LO,1) = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "***********************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE M VAUT (&M)                 ***";
      PUT   @2 "***            ET LE PARAMÈTRE LO N'EST PAS RENSEIGNÉ   ***";
      PUT   @2 "***********************************************************";
    %GOTO FIN;
  %END;

  %IF (&M=3 OR &M=4) AND %SCAN(&UP,1) = %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "***********************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE M VAUT (&M)                 ***";
      PUT   @2 "***            ET LE PARAMÈTRE UP N'EST PAS RENSEIGNÉ   ***";
      PUT   @2 "***********************************************************";
    %GOTO FIN;
  %END;

  %IF &M=5 AND &ALPHA= %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "**************************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE M VAUT 5                       ***";
      PUT   @2 "***            ET LE PARAMÈTRE ALPHA N'EST PAS RENSEIGNÉ   ***";
      PUT   @2 "**************************************************************";
    %GOTO FIN;
  %END;

  %IF &M=5 AND %DATATYP(&ALPHA) NE NUMERIC %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "**************************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE M VAUT 5                       ***";
      PUT   @2 "***            ET LE PARAMÈTRE ALPHA N'EST PAS NUMÉRIQUE   ***";
      PUT   @2 "***            (ALPHA=&ALPHA)"                        @61 "***";
      PUT   @2 "**************************************************************";
    %GOTO FIN;
  %END;

%END;


               /*****************************************
                *  CONTROLE SUR LE PARAMÈTRE D'ÉDITION  *
                *****************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

%IF &EDITION NE 0 AND &EDITION NE 1 AND &EDITION NE 2 AND &EDITION NE 3 %THEN
%DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*********************************************************";
      PUT   @2 "***   ERREUR : LA VALEUR DU PARAMÈTRE &EDITION (&M)   ***";
      PUT   @2 "***            EST DIFFÉRENTE DE 0, 1, 2, 3           ***";
      PUT   @2 "*********************************************************";
    %GOTO FIN;
%END;

%END;


               /*********************************************************
                *  CONTROLE SUR LES PARAMÈTRES POPMEN, POPIND, POPKISH  *
                *********************************************************/

%IF %UPCASE(&CONT)=OUI %THEN
%DO;

  %IF &POPMEN= AND %UPCASE(&PCT)=OUI AND &MARMEN NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE POPMEN N'EST PAS RENSEIGNÉ    ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONNÉES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAMÈTRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

  %IF &POPIND= AND %UPCASE(&PCT)=OUI AND &MARIND NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE POPIND N'EST PAS RENSEIGNÉ    ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONNÉES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAMÈTRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

  %IF &POPKISH= AND %UPCASE(&PCT)=OUI AND &MARKISH NE  %THEN
  %DO;
    DATA _NULL_;
      FILE PRINT;
      PUT //@2 "*************************************************************";
      PUT   @2 "***   ERREUR : LE PARAMÈTRE POPKISH N'EST PAS RENSEIGNÉ   ***";
      PUT   @2 "***            ALORS QUE LES MARGES SONT DONNÉES EN       ***";
      PUT   @2 "***            POURCENTAGES (LE PARAMÈTRE PCT VAUT OUI)   ***";
      PUT   @2 "*************************************************************";
    %GOTO FIN;
  %END;

%END;

               /*****************************************
                *   CONTROLE SUR LE FACTEUR D'ÉCHELLE   *
                *****************************************/

  %IF %UPCASE(&CONT)=OUI %THEN
  %DO;
      %IF &ECHELLE NE  AND &ECHELLE NE 1 AND &ECHELLE NE 0 AND &POIDS=  %THEN
      %DO;
          DATA _NULL_;
           FILE PRINT;
           PUT @2 "*************************************************************";
           PUT @2 "*** ERREUR : LA VALEUR DU PARAMÈTRE ECHELLE (&ECHELLE)    ***";
           PUT @2 "***          EST DIFFÉRENTE DE 1 ET DE 0                  ***";
           PUT @2 "***          ALORS QUE LE POIDS INITIAL (PARAMÈTRE POIDS) ***";
           PUT @2 "***          N'EST PAS RENSEIGNÉ                          ***";
           PUT @2 "*************************************************************";
      %END;
  %END;


   /*****************************************************
    **** CRÉATION DES MACRO-VARIABLES CONTENANT     *****
    **** LE NBRE D'OBSERV. DANS LA TABLE DE DONNÉES *****
    **** ET LE NBRE MAXIMUM DE MODALITÉS            *****
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
      PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAMEN A 0 OBSERVATION" @73 "***";
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
     PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAIND A 0 OBSERVATION" @73 "***";
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
     PUT @2 "***            SPÉCIFIÉE DANS LE PARAMÈTRE DATAKISH A 0 OBSERVATION" @73 "***";
     PUT @2 74*"*";
   RUN;
   %GOTO FFIN;
 %END;
%END;


 /****************************************************************************************
  **** VÉRIFICATION DE LA COHÉRENCE ENTRE NOMBRE DE MÉNAGES ET NOMBRE D'INDIVIDUS-KISH ***
  **** DANS LE CAS OÙ NKISH N'EST PAS RENSEIGNÉ (DONC ÉGAL À 1)                        ***
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
     * CONTRÔLES EN CAS DE REDRESSEMENT DE LA NON-RÉPONSE *
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
        PUT @2 "***            TABLE DE MARGES SPÉCIFIÉE DANS LES PARAMÈTRES" @63 "***";
        PUT @2 "***            &MARMEN &MARIND &MARKISH"                      @63 "***";
        PUT @2 65*"*";
     RUN;
     %GOTO FIN;
 %END;

 %ELSE
 %DO;                                                    /* LA VARIABLE R EST PRÉSENTE */
   %IF &NZ=0 %THEN                                       /*   DANS LA TABLE DE MARGES  */
    %DO;
        DATA _NULL_;
         FILE PRINT;
     PUT @2 74*"*";
     PUT @2  "ERREUR : IL N'Y A AUCUNE VARIABLE DE NON-RÉPONSE DANS LES TABLES DE MARGES";
     PUT @2  "         POUR UNE VAR. DE NON-RÉPONSE, ON DOIT AVOIR R=1 DANS LA TABLE";
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
          PUT @2  "ERREUR : LE NOMBRE DE MODALITES DE NON-RÉPONSE N'EST PAS ÉGAL À CELUI";
          PUT @2  "         DES MODALITES DE CALAGE";
          PUT @2  "         IL Y A %LEFT(&DIMZ) MODALITÉS DE NON-RÉPONSE"
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

**** CONTRÔLE DE LA TABLE DES MARGES MÉNAGES ****;

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

**** CONTRÔLE DE LA TABLE DES MARGES INDIVIDUS ****;

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

**** CONTRÔLE DE LA TABLE DES MARGES INDIVIDUS-KISH ****;

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
    *  CONTROLES SUR LES VARIABLES DE PONDÉRATION DE LA TABLE DATA  *
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
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&POIDS) SPÉCIFIÉE DANS LE"
               " PARAMÈTRE POIDS" @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAMEN)"                @73 "***";
        PUT @2 "***            N'EST PAS NUMÉRIQUE"                 @73 "***";
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
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&POIDS) SPÉCIFIÉE DANS LE"
               " PARAMÈTRE POIDS" @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAIND)"             @73 "***";
        PUT @2 "***            N'EST PAS NUMÉRIQUE"                 @73 "***";
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
          PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&PONDQK) SPÉCIFIÉE DANS LE"
              @73 "***";
          PUT @2 "***            PARAMÈTRE PONDQK NE FIGURE PAS DANS" @73 "***";
          PUT @2 "***            LA TABLE %UPCASE(&DATAMEN)" @73 "***";
          PUT @2 74*"*";
      %GOTO FIN;
    %END;

    %ELSE %IF &PONDQCAR=2 %THEN
    %DO;
      DATA _NULL_;
        FILE PRINT;
        PUT //@2 74*"*";
        PUT @2 "***   ERREUR : LA VARIABLE %UPCASE(&PONDQK) SPÉCIFIÉE DANS"
               " LE PARAMÈTRE PONDQK"  @73 "***";
        PUT @2 "***            ET FIGURANT DANS LA"                 @73 "***";
        PUT @2 "***            TABLE %UPCASE(&DATAMEN)"                @73 "***";
        PUT @2 "***            N'EST PAS NUMÉRIQUE"                 @73 "***";
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
       PUT @2 "*** ERREUR : LA VARIABLE &POIDKISH INDIQUÉE DANS LE PARAMÈTRE POIDKISH"
           @74 "***";
       PUT @2 "***          ET FIGURANT DANS LA TABLE &DATAKISH" @74 "***";
       PUT @2 "***          N'EST PAS NUMÉRIQUE"                 @74 "***";
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
   CALAGE SÉPARÉ SUR LES INDIVIDUS AVEC ÉGALITÉ DES POIDS DANS UN MÉNAGE
   **************************************************************************/


%IF &TYP=2B %THEN
%DO;

                            /* VÉRIFICATION DE LA PRÉSENCE D'UN IDENTIFIANT DU MÉNAGE */

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
    PUT @2 "* ERREUR : L'IDENTIFIANT &IDENT RENSEIGNÉ DANS LE PARAMÈTRE IDENT       *";
    PUT @2 "*          N'EST PAS UN IDENTIFIANT DU MÉNAGE.                          *";
    PUT @2 "*          IL Y A &NID IDENTIFIANTS DIFFÉRENTS ET &NOBSIND OBSERVATIONS *";
    PUT @2 "*          DANS LA TABLE &DATAIND INDIQUÉE DANS LE PARAMÈTRE DATAIND    *";
    PUT @2 74*"*";
    %GOTO FIN;
  %END;
                            /* VÉRIFICATION DE L'UNICITÉ DES POIDS INDIVIDUS PAR MÉNAGE */

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
  PUT @2 "* ERREUR : DANS &ERRPOID MÉNAGES, DEUX INDIVIDUS ONT DES POIDS DIFFÉRENTS" @81 "*";
  PUT @2 "*          LE CALAGE NE PEUT FOURNIR DES POIDS ÉGAUX POUR LES INDIVIDUS"   @81 "*";
  PUT @2 "*          D'UN MÊME MÉNAGE QUE SI CETTE ÉGALITÉ EST VÉRIFIÉE ENTRE LES"   @81 "*";
  PUT @2 "*          POIDS INITIAUX DANS VOTRE TABLE &DATAIND INDIQUÉE DANS LE"      @81 "*";
  PUT @2 "*          PARAMÈTRE DATAIND."                                             @81 "*";
  PUT @2 "* SOIT IL Y A UNE ERREUR DANS VOTRE TABLE &DATAIND, SOIT VOUS FAITES UN"   @81 "*";
  PUT @2 "* CALAGE SANS DEMANDER UNE ÉGALITÉ DES POIDS ENTRE INDIVIDUS D'UN MÊME MÉNAGE" 
                                                                                     @81 "*";
  PUT @2 "* (EGALPOI À BLANC)"                                                       @81 "*";
  PUT @2 80*"*";

  PROC PRINT DATA=__ERR LABEL SPLIT='!';
        TITLE 'LISTE DES MÉNAGES EN ERREUR';
        VAR &IDENT COUNT;
        LABEL COUNT='NOMBRE DE POIDS!DIFFÉRENTS!PAR MÉNAGE';
   %GOTO FIN;
  %END;

 %END;

                            /* CRÉATION D'UNE TABLE MÉNAGES */

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

                            /* CRÉATION D'UNE TABLE DE MARGES MÉNAGES */

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
*********  STOCKAGE DES NOMS ET DU NOMBRE DE MODALITÉS DES VARIABLES DE CALAGE ***********;
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

%IF &TYP=1 OR &TYP=2B OR &TYP=3 OR &TYP=4 OR &TYP=5 %THEN            /* NIVEAU MÉNAGES */
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
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CATÉGORIELLES DE CALAGE N'EST PAS ÉGAL";
          PUT @2  "         À CELUI DES VARIABLES CATÉGORIELLES DE NON-RÉPONSE";
          PUT @2  "         DANS LA TABLE &MARMEN INDIQUÉE DANS LE PARAMÈTRE MARMEN";
          PUT @2  "         IL Y A &CAT1 VARIABLES CATÉGORIELLES DE CALAGE"
                  " ET &CATZ1 VAR.CAT.DE NON-RÉPONSE";
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
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CATÉGORIELLES DE CALAGE N'EST PAS ÉGAL";
          PUT @2  "         À CELUI DES VARIABLES CATÉGORIELLES DE NON-RÉPONSE";
          PUT @2  "         DANS LA TABLE &MARIND INDIQUÉE DANS LE PARAMÈTRE MARIND";
          PUT @2  "         IL Y A &CAT2 VARIABLES CATÉGORIELLES DE CALAGE"
                  " ET &CATZ2 VAR.CAT.DE NON-RÉPONSE";
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
          PUT @2  "ERREUR : LE NOMBRE DE VARIABLES CATÉGORIELLES DE CALAGE N'EST PAS ÉGAL";
          PUT @2  "         À CELUI DES VARIABLES CATÉGORIELLES DE NON-RÉPONSE";
          PUT @2  "         DANS LA TABLE &MARKISH INDIQUÉE DANS LE PARAMÈTRE MARKISH";
          PUT @2  "         IL Y A &CAT3 VARIABLES CATÉGORIELLES DE CALAGE"
                  " ET &CATZ3 VAR.CAT.DE NON-RÉPONSE";
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

%IF &TYP=1 %THEN %DO;                             /* UN SEUL FICHIER DE NIVEAU MÉNAGE */

DATA __MARMEN;
     LENGTH NIVEAU $1;
     SET __MARMEN;
         NIVEAU='1';
                           /* LA TABLE MÉNAGE CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */

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
                         /* LA TABLE MÉNAGE NE CONTIENT PAS DE VARIABLES CATÉGORIELLES */

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

                          /* LA TABLE INDIVIDU CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */
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
                       /* LA TABLE INDIVIDU NE CONTIENT PAS DE VARIABLES CATÉGORIELLES */
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

%ELSE %IF &TYP=2B OR &TYP=3 %THEN %DO;           /* CALAGE SIMULTANE MÉNAGES + INDIVIDUS */

                             /* LA TABLE MÉNAGES CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */

 %IF (&CAT1>0 OR &CATZ1>0) AND &TYP NE 2B %THEN
  %DO;
    %CODIF(TABIN=&DATAMEN,
           TABOUT=&TABMEN ,
           XV=V,
           XM=MM)
    RUN;
    %IF &ERMOD=1 %THEN %GOTO E3 ;
  %END;
                           /* LA TABLE INDIVIDUS CONTIENT AU MOINS UNE VAR. CATÉGORIELLE */
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

title;title2;title3;title4;title5;title6;title7;title8;title9;
PROC DATASETS DDNAME=WORK NOLIST;
     DELETE _NOMVAR1 _NOMVAR2 _NOMVAR3 __ZMEN __ZIND __ZKISH __MARG __ZM __XM __NXM __NZM
            __ERREUR __POIDS __MARM __CODMEN __CODIND __CODKIS __MENPOI __NBPOI __ERR __NIDENT;
    QUIT;

OPTIONS NOTES;

%MEND CALMAR2_GUIDE;
