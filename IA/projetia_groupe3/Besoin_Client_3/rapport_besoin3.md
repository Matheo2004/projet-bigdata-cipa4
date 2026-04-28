# Besoin Client 3 – Système d'alerte pour les tempêtes

## Objectif

L'objectif est de prédire si un arbre est susceptible d'être déraciné lors d'une tempête, à partir de ses caractéristiques physiques et environnementales.

## Définition de la cible

La colonne `fk_arb_etat` contient six états distincts. Après analyse, seuls *Essouché* et *Non essouché* correspondent à un déracinement avéré par tempête. En croisant avec la colonne `dte_abattage`, j'ai constaté que 108 arbres classés *ABATTU* n'ont aucune date d'abattage enregistrée. L'absence de date suggère un abattage d'urgence potentiellement consécutif à une tempête, ces arbres ont donc été intégrés aux cas positifs, portant le total à 376 positifs sur 11 248 arbres (~4%).

## Sélection et analyse des features

J'ai retenu uniquement les colonnes décrivant des caractéristiques physiques influençant la résistance au vent : hauteur totale, hauteur du tronc, diamètre du tronc, âge estimé, stade de développement, port, type de pied, situation, revêtement et feuillage. Les valeurs manquantes ont été supprimées pour ne pas introduire de données artificielles.

L'analyse des corrélations a confirmé que toutes les features sont pertinentes : les corrélations entre elles restent modérées (max 0.76 entre `tronc_diam` et `age_estim`), et les corrélations avec la cible sont toutes très faibles (max 0.10). Ce résultat confirme que le déracinement est un phénomène non linéaire dépendant d'interactions complexes entre variables, ce qui justifie l'usage d'un modèle à base d'arbres.

## Choix du modèle et rééquilibrage

Le recall a été retenu comme métrique principale : rater un arbre à risque est bien plus grave que déclencher une fausse alerte. Sans rééquilibrage, la Logistic Regression obtenait 68% de recall tandis que les modèles complexes ne dépassaient pas 3%, le fort déséquilibre les poussait à toujours prédire la classe majoritaire.

Pour corriger cela, j'ai appliqué une stratégie mixte sur le train uniquement : génération d'exemples synthétiques par SMOTE et réduction de la classe majoritaire par undersampling (ratio cible 60/40). Sur ce dataset rééquilibré, j'ai comparé quatre algorithmes en cross-validation puis optimisé les hyperparamètres du meilleur via GridSearchCV.


## Résultats et modèle final

Le **Random Forest** avec un poids 20 fois plus fort sur la classe minoritaire a été retenu comme modèle final, ce poids pénalise davantage les erreurs sur les arbres déracinés pendant l'entraînement, forçant le modèle à mieux les détecter. Sur le test set réel, il détecte **91% des arbres déracinés** avec une meilleure précision que le Decision Tree (8% vs 3%), ce qui limite davantage les fausses alertes tout en maintenant un recall élevé.

L'accuracy globale (~54%) est volontairement basse : un modèle prédisant systématiquement "non déraciné" aurait 96% d'accuracy mais serait inutile. Le recall sur la classe positive est la seule métrique pertinente pour un système d'alerte. Le seuil de décision est fixé à 50% et peut être ajusté selon les besoins opérationnels.


## Limites

Les performances sont contraintes par le faible nombre de cas positifs réels et l'absence de données météorologiques. L'intégration de données comme la vitesse et la direction du vent améliorerait significativement les résultats.
