# Description du jeu de donnees

Le fichier `data/Data_Arbre_Input.csv` contient un inventaire d'arbres urbains. Chaque ligne correspond a un arbre ou a un enregistrement associe a un arbre present dans l'espace public. Le jeu de donnees comprend **11 421 observations** et **37 variables**.

## Contenu du jeu de donnees

Ce dataset decrit principalement :

- la localisation de l'arbre avec les coordonnees `X` et `Y`
- son identification avec `OBJECTID`, `id_arbre` et `GlobalID`
- sa situation geographique avec `clc_quartier` et `clc_secteur`
- ses caracteristiques physiques avec `haut_tot`, `haut_tronc` et `tronc_diam`
- son etat et ses conditions avec `fk_arb_etat`, `fk_stadedev`, `fk_port`, `fk_pied`, `fk_situation` et `fk_revetement`
- des informations de gestion et de suivi avec `dte_plantation`, `dte_abattage`, `clc_nbr_diag` et `commentaire_environnement`
- des informations botaniques avec `nomfrancais`, `nomlatin`, `feuillage` et `remarquable`

## Principaux constats

- la majorite des arbres sont en etat `EN PLACE` : **10 382** enregistrements
- les arbres sont principalement en `Alignement` (**6 557**) ou en `Groupe` (**3 812**)
- le feuillage est majoritairement `Feuillu` (**9 643**) contre **1 582** `Conifere`
- seuls **110 arbres** sont identifies comme `remarquables`
- les quartiers les plus representes sont `Quartier Saint-Martin - Oestres`, `Quartier Remicourt` et `Quartier du faubourg d'Isle`

## Qualite et limites des donnees

- les coordonnees sont presque completes : **11 419 / 11 421**
- plusieurs variables sont bien renseignees, notamment `nomfrancais`, `nomlatin`, `fk_stadedev` et `fk_port`
- la variable `dte_plantation` est peu complete : **1 583 / 11 421**
- certaines valeurs paraissent codees ou abregees, par exemple pour les essences (`PLAACE`, `TILCOR`, `PINNIGnig`), ce qui suggere l'usage de codes techniques botaniques

## Conclusion

Ce jeu de donnees constitue un referentiel de gestion du patrimoine arbore urbain. Il peut etre utilise pour realiser des analyses de repartition spatiale, de suivi de l'etat sanitaire des arbres, d'etude de la diversite des essences et d'aide a la gestion des plantations ou des abattages.
