# Besoin Client 3 – Système d'alerte pour les tempêtes

## Objectif

L'objectif est de mettre en place un modèle capable de prédire si un arbre est susceptible d'être déraciné lors d'une tempête, à partir de ses caractéristiques physiques et environnementales.

## Définition de la cible

La colonne `fk_arb_etat` contient six états distincts. La première question à résoudre était de déterminer lesquels correspondent réellement à un déracinement par tempête. Après analyse, les états *Essouché* et *Non essouché* sont les seuls qui décrivent un arbre soulevé par ses racines — phénomène directement causé par le vent. Les états *ABATTU*, *SUPPRIMÉ* et *REMPLACÉ* relèvent en principe d'interventions humaines planifiées.

Cependant, en croisant `fk_arb_etat` avec la colonne `dte_abattage`, j'ai constaté que 108 arbres classés *ABATTU* n'ont aucune date d'abattage enregistrée. L'absence de date suggère un abattage d'urgence, potentiellement consécutif à une tempête. Ces arbres ont donc été intégrés aux cas positifs.

La cible finale est binaire : `1` pour les arbres *Essouché*, *Non essouché*, et *ABATTU* sans date d'abattage (376 cas), `0` pour tous les autres (10 872 cas).

## Sélection des features

J'ai retenu uniquement les colonnes décrivant des caractéristiques physiques susceptibles d'influencer la résistance d'un arbre au vent : hauteur totale, hauteur du tronc, diamètre du tronc, âge estimé, stade de développement, port, type de pied, situation, revêtement autour du pied et feuillage. Les colonnes administratives (identifiants, dates, noms) ont été écartées. Les lignes contenant des valeurs manquantes ont été supprimées plutôt qu'imputées, pour ne pas introduire de données artificielles. Le dataset final compte 9 398 arbres.

## Choix du modèle

Le dataset est fortement déséquilibré — environ 4% de positifs contre 96% de négatifs. Pour un système d'alerte, la métrique pertinente est le **recall** : rater un arbre qui va tomber est bien plus grave que déclencher une fausse alerte. J'ai comparé quatre algorithmes en cross-validation (Logistic Regression, Random Forest, Gradient Boosting, Decision Tree).

Sans rééquilibrage, la Logistic Regression obtenait le meilleur recall (68%) alors que Random Forest ne dépassait pas 3%. Ce résultat contre-intuitif s'explique par le déséquilibre : les modèles complexes apprennent à tout prédire comme la classe majoritaire, ce qui est correct 96% du temps mais inutile pour une alerte.

## Rééquilibrage des données

Pour tirer parti des modèles non linéaires, mieux adaptés à un phénomène aussi complexe que le déracinement par tempête, j'ai appliqué une stratégie mixte sur le train uniquement : génération d'exemples synthétiques via SMOTE et réduction de la classe majoritaire par undersampling, avec un ratio cible de 60/40. Cette approche a permis à Random Forest de monter à 85% de recall en cross-validation, mais seulement 26% sur le test réel — les modèles apprenaient sur les données synthétiques sans généraliser aux vrais arbres.

En ajoutant un poids fort sur la classe minoritaire (`class_weight` jusqu'à 20x), Random Forest a atteint **91% de recall sur le test réel**, ce qui constitue le meilleur résultat obtenu.

## Résultats et choix final

Le modèle retenu est un **Random Forest** avec `class_weight={0:1, 1:20}`, optimisé par GridSearchCV (`max_depth=10`, `min_samples_split=2`, `n_estimators=100`), entraîné sur un dataset rééquilibré par SMOTE + undersampling (ratio 60/40).

Sur le test set réel (non rééquilibré), il détecte 91% des arbres à risque de déracinement, au prix d'un nombre important de fausses alertes (precision de 5%). Ce compromis est volontaire : pour une mairie, le coût d'une inspection inutile reste bien inférieur à celui d'un arbre non détecté qui tombe lors d'une tempête.

Le seuil de décision est fixé à 50% et peut être ajusté selon les besoins opérationnels — abaissé avant une tempête annoncée pour être plus prudent, relevé en période normale pour limiter les inspections.

## Limites

Les performances sont contraintes par la nature même des données : 376 cas positifs sur 11 248 arbres, sans information sur les causes exactes des abattages ni données météorologiques associées. L'intégration de données comme la vitesse et la direction du vent, ou l'état sanitaire des arbres, améliorerait significativement les résultats.
