# Calmar2

La macro SAS CALMAR2 est une nouvelle version de la macro CALMAR (CALage sur MARges) en usage à l’INSEE depuis 1993. Comme la précédente, elle permet de redresser un échantillon, par repondération des individus, en utilisant une information auxiliaire disponible sur un certain nombre de variables, appelées variables de calage. Les pondérations produites par la macro sont telles que :
- pour une variable de calage catégorielle (ou "qualitative"), les effectifs des modalités de la variable estimés dans l'échantillon, après redressement, seront égaux aux effectifs connus sur la population ;
- pour une variable numérique (ou "quantitative"), le total de la variable estimé dans l'échantillon, après redressement, sera égal au total connu sur la population.

Le redressement consiste à remplacer les pondérations initiales, qui sont en général les "poids de sondage" des individus (égaux aux inverses des probabilités d'inclusion), par des "poids de calage" (appelés aussi pondérations finales par la suite) aussi proches que possible des pondérations initiales au sens d'une certaine distance, et satisfaisant les égalités indiquées plus haut.

Cette méthode de redressement permet de réduire la variance d'échantillonnage, et, dans certains cas, de réduire le biais dû à la non réponse totale. 

La macro CALMAR2 apporte à l’utilisateur les options supplémentaires suivantes par rapport à la version antérieure :
- une nouvelle fonction de distance : le sinus hyperbolique ;
- le traitement des colinéarités entre variables de calage ;
- la codification automatique des variables de calage catégorielles, l’utilisateur pouvant désormais spécifier des paramètres à valeurs discontinues ou de type libellé ;
- le calage simultané entre différents niveaux d’observation d’une même enquête ;
- le redressement de la non-réponse à l’aide d’une information auxiliaire connue sur les seuls répondants, par la méthode de calage généralisé mise au point par J.C. Deville.

Les principaux contributeurs à l'élaboration de cette macro sont Jean-Claude Deville et Carl-Erik Särndal pour la théorie du calage sur marges, et Olivier Sautory et Josiane Le Guennec pour le développement de la macro CALMAR2 permettant sa mise en œuvre.

Le programme « compilation.sas » permet de compiler la macro à partir des codes sources disponibles dans le dossier « src ».

Note : la macro CALMAR2 utilise les modules SAS/STAT et SAS/IML du logiciel SAS.
