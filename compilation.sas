********************************************************************************************;
**** Permet de compiler la macro Calmar2 dans le répertoire Z:\Calmar2 à partir des ********;
**** codes sources disponibles dans le répertoire "Z:\Calmar2\src" *************************;
********************************************************************************************;

libname calmar2 "Z:\Calmar2";
filename sources "Z:\Calmar2\src";

options sasmstore=calmar2 mstored;
options nodate;

%inc sources(calmar1);
%inc sources(calmar2);
%inc sources(calmar2_guide);
%inc sources(codif);
%inc sources(contenu);
%inc sources(existenc);
%inc sources(exisvar);
%inc sources(marges);
%inc sources(nmod);
%inc sources(nobs);
%inc sources(nobss);
%inc sources(remontee);
%inc sources(remontki);
%inc sources(verif2);
%inc sources(verif3);
%inc sources(verif4);
%inc sources(verif5);
run;
