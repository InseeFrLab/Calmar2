 /******************************************************************
  *  LA PROC CONTENTS SERA UTILISÉE DANS LES CONTRÔLES FACULTATIFS *
  *     ET AU MOMENT DE LA LECTURE DES TABLES DES MARGES           *
  ******************************************************************/

%MACRO CONTENU(TAB,U)/store;
  PROC CONTENTS NOPRINT DATA=%SCAN(&TAB,1,'(')
                OUT=_NOMVAR&U;
  DATA _NOMVAR&U(KEEP=VAR TYPE);
       SET _NOMVAR&U;
	   LENGTH VAR $ 32;
	       VAR=LEFT(UPCASE(NAME));
  PROC SORT DATA=_NOMVAR&U;
    BY VAR;
  RUN;
%MEND CONTENU;
