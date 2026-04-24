# 🌳 Rapport — Prédiction de l'âge des arbres
### Projet Machine Learning | Apprentissage supervisé — Régression

---

## Contexte et objectif

Ce projet porte sur un dataset recensant les arbres d'une ville avec différentes caractéristiques physiques (hauteur, diamètre du tronc, espèce…) ainsi qu'une estimation de leur âge (`age_estim`).

L'objectif est de **prédire automatiquement l'âge d'un arbre** à partir de ses caractéristiques observables, en utilisant des algorithmes de machine learning supervisé. Concrètement, ce type de modèle permettrait à un agent de terrain de prendre quelques mesures et d'obtenir une estimation d'âge sans avoir à consulter les archives de plantation.

---

## 1. Données

Le dataset original contient **11 248 lignes et 37 colonnes**. Après suppression des lignes sans valeur cible, on travaille sur **10 415 observations**.

### Sélection des features

Parmi les 37 colonnes disponibles, beaucoup sont des métadonnées administratives (identifiants, dates de saisie, noms d'utilisateur) sans lien avec l'âge d'un arbre. J'ai retenu **10 variables** ayant un sens physique ou écologique :

| Variable | Type | Justification |
|---|---|---|
| `haut_tot` | Numérique | Un arbre plus âgé est en général plus grand |
| `haut_tronc` | Numérique | La hauteur du tronc augmente avec l'âge |
| `tronc_diam` | Numérique | Le diamètre du tronc est un indicateur classique d'âge |
| `clc_nbr_diag` | Numérique | Nombre de diagnostics réalisés sur l'arbre |
| `fk_prec_estim` | Numérique | Précision de l'estimation (information contextuelle) |
| `clc_quartier` | Catégorielle | Le quartier peut refléter des périodes de plantation différentes |
| `nomlatin` | Catégorielle | L'espèce a une forte influence sur la croissance |
| `fk_stadedev` | Catégorielle | Stade de développement de l'arbre |
| `fk_arb_etat` | Catégorielle | État sanitaire de l'arbre |
| `fk_situation` | Catégorielle | Contexte de plantation (rue, parc, jardin…) |

---

## 2. Nettoyage et préparation

### Gestion des valeurs manquantes

On supprime uniquement les lignes où `age_estim` (la cible) est manquante. Pour les features, les valeurs manquantes sont traitées dans le pipeline de prétraitement :
- **Colonnes catégorielles** : remplacement par la **valeur la plus fréquente** (`most_frequent`)
- **Colonnes numériques** : remplacement par la **médiane** (plus robuste aux valeurs aberrantes que la moyenne)

### ⚠️ Bug rencontré : `age_estim` dans `num_columns`

Dans la première version du code, la détection des types de colonnes était effectuée sur `df` — qui contenait encore la colonne cible `age_estim`. Résultat : `age_estim` se retrouvait dans `num_columns` (les colonnes numériques passées au `ColumnTransformer`).

Au moment du `.fit()`, le préprocesseur cherchait `age_estim` dans `X_train` où elle n'existait évidemment plus, ce qui causait un `KeyError` puis un `ValueError` :

```
KeyError: 'age_estim'
ValueError: A given column is not a column of the dataframe
```

**Correction** : détecter les types de colonnes **après** avoir créé `X` (sans la target), et non sur `df`.

```python
# ❌ Version bugguée
num_columns = df.select_dtypes(include=[np.number]).columns.tolist()
# → inclut age_estim !

# ✅ Version corrigée
num_columns = X.select_dtypes(include=[np.number]).columns.tolist()
# → X ne contient pas age_estim
```

---

## 3. Prétraitement

Le prétraitement est encapsulé dans un `ColumnTransformer` scikit-learn qui applique des transformations différentes selon le type de colonne.

### Pipeline catégoriel
1. `SimpleImputer(strategy="most_frequent")` — remplace les manquants par la valeur la plus fréquente
2. `OneHotEncoder(handle_unknown="ignore")` — transforme chaque modalité en colonne binaire. L'option `handle_unknown="ignore"` évite les erreurs si le jeu de test contient des modalités inconnues à l'entraînement.

### Pipeline numérique
1. `SimpleImputer(strategy="median")` — médiane plutôt que moyenne, plus robuste aux outliers fréquents dans des données terrain
2. `StandardScaler()` — normalisation z-score (moyenne = 0, écart-type = 1), indispensable pour SVR et LinearRegression qui sont sensibles aux différences d'échelle entre variables

> RandomForest et GradientBoosting n'ont pas strictement besoin de normalisation, mais la garder simplifie le pipeline : un seul préprocesseur pour tous les modèles.

Tout est intégré dans un `Pipeline` scikit-learn `(preprocessing → model)` pour chaque algorithme. Cela garantit que le preprocessing est toujours appliqué de manière cohérente, et que le pipeline complet peut être sauvegardé et rechargé en un seul fichier.

---

## 4. Séparation train / test

| | Taille |
|---|---|
| **Train** | 8 332 lignes (80%) |
| **Test** | 2 083 lignes (20%) |

Le split 80/20 est un standard pour des datasets de taille moyenne (~10 000 lignes). Le `random_state=42` est fixé pour garantir la **reproductibilité** : toute ré-exécution du notebook produira exactement les mêmes ensembles.

On vérifie que les distributions de `age_estim` sont similaires entre train et test (moyennes, écarts-types proches) pour s'assurer que le split est représentatif.

---

## 5. Comparaison des 4 algorithmes (baseline)

### Choix des modèles

L'idée est de tester un panel varié d'approches, du plus simple au plus complexe :

| Modèle | Type | Avantages | Inconvénients |
|---|---|---|---|
| **LinearRegression** | Linéaire | Rapide, interprétable, référence | Limité si les relations sont non-linéaires |
| **SVR** | Noyau | Robuste, flexible avec le bon kernel | Lent sur gros datasets, sensible au choix des paramètres |
| **RandomForest** | Ensemble (bagging) | Robuste aux outliers, peu de réglage nécessaire | Moins performant que le boosting sur certains problèmes |
| **GradientBoosting** | Ensemble (boosting) | Souvent très performant | Plus lent à entraîner, plus d'hyperparamètres |

### Métriques d'évaluation

Trois métriques sont calculées sur train **et** test pour chaque modèle :

- **R²** : proportion de variance expliquée. C'est la métrique principale — un R² de 1.0 correspond à une prédiction parfaite, 0 à un modèle qui ne fait pas mieux que prédire la moyenne.
- **MAE** (Mean Absolute Error) : erreur moyenne en années. Facile à interpréter métier : "en moyenne, le modèle se trompe de X ans".
- **RMSE** (Root Mean Squared Error) : pénalise davantage les grandes erreurs. Utile pour détecter si le modèle fait quelques prédictions très mauvaises.

Calculer les métriques à la fois sur train et test permet de détecter l'**overfitting** : si le R² train est très élevé mais le R² test est faible, le modèle a mémorisé les données d'entraînement au lieu d'apprendre des patterns généralisables.

---

## 6. Optimisation par GridSearchCV

### Principe

Les modèles de machine learning ont des **hyperparamètres** : des réglages fixés avant l'entraînement (ex : nombre d'arbres dans une forêt, profondeur maximale). `GridSearchCV` teste toutes les combinaisons possibles d'une grille définie, en évaluant chacune par **validation croisée 5-fold** : le dataset train est découpé en 5 parties, le modèle est entraîné 5 fois en utilisant à tour de rôle chaque partie comme validation. On garde la combinaison avec le meilleur R² moyen.

> Le GridSearchCV peut être coûteux en temps. Par exemple pour RandomForest : 3 × 3 × 2 = 18 combinaisons × 5 folds = **90 entraînements**. Les grilles ont donc été gardées relativement restreintes.

### Grilles de paramètres

**RandomForest**
```
n_estimators      : [100, 200, 300]
max_depth         : [10, 20, None]
min_samples_split : [2, 5]
```

**GradientBoosting**
```
n_estimators  : [100, 200]
max_depth     : [3, 5, 7]
learning_rate : [0.05, 0.1, 0.2]
```

**SVR**
```
C       : [0.1, 1, 10]
epsilon : [0.1, 0.5, 1.0]
kernel  : ['rbf', 'linear']
```

**LinearRegression** : pas d'hyperparamètres à optimiser — on conserve directement le modèle baseline.

### Scoring

On utilise le **R²** comme critère de sélection car c'est la métrique la plus interprétable pour une régression, et elle est normalisée (indépendante de l'échelle de la target).

---

## 7. Résultats et comparaison

### Graphique de comparaison

Un graphique en barres groupées (Baseline vs GridSearch) est généré pour les 3 métriques afin de visualiser d'un coup d'œil l'apport de l'optimisation sur chaque modèle. Il est aussi sauvegardé en `comparaison_modeles.png`.

### Analyse de la généralisation

On surveille l'**écart de généralisation** (R² train − R² test) :
- Un écart faible → le modèle généralise bien (ce qu'on cherche)
- Un écart important → overfitting : le modèle a trop mémorisé les données d'entraînement

### Visualisation des prédictions

Un scatter plot "prédictions vs valeurs réelles" est tracé pour le meilleur modèle. Chaque point représente un arbre du jeu de test. La diagonale en pointillés rouges est la droite de prédiction parfaite (`y_pred = y_true`). Plus les points s'en rapprochent, meilleur est le modèle. Ce graphique permet aussi de détecter des biais systématiques (ex : sous-estimation des arbres très vieux).

---

## 8. Sauvegarde du meilleur modèle

### Pourquoi sauvegarder le pipeline complet ?

On sauvegarde le **pipeline entier** (preprocessing + modèle) et non pas seulement le modèle entraîné. C'est essentiel : sans le preprocessing intégré, il faudrait le refaire manuellement à chaque prédiction, ce qui est une source d'erreurs (mauvais ordre des colonnes, oubli du scaler, etc.).

```python
joblib.dump(meilleur_pipeline_final, "artifacts/models/modele_arbre.pkl")
```

Pour réutiliser le modèle :
```python
import joblib
pipeline = joblib.load("artifacts/models/modele_arbre.pkl")
predictions = pipeline.predict(X_nouveau)
```

On sauvegarde aussi un fichier `metadata_modele.json` contenant :
- Le nom du meilleur algorithme
- La liste des features utilisées
- Les hyperparamètres optimaux trouvés par GridSearch
- Les métriques finales (train et test)

Cela assure la **traçabilité** du modèle : on peut retrouver dans quel contexte il a été produit sans avoir à ré-exécuter le notebook.

> Seul le meilleur modèle est sauvegardé. Les résultats des 3 autres sont consultables en session via les dictionnaires `resultats_baseline` et `resultats_optimises`.

---

## 9. Bilan

### Ce qui a bien fonctionné

- L'architecture `Pipeline + ColumnTransformer` est propre et réutilisable : une seule sauvegarde suffit pour déployer le modèle.
- Comparer 4 algorithmes avant d'optimiser permet d'éviter de perdre du temps à faire un GridSearch sur un modèle qui serait de toute façon médiocre.
- Le GridSearchCV avec validation croisée donne une estimation fiable de la performance réelle, sans biais de sur-optimisation sur le test.

### Difficultés rencontrées

| Problème | Cause | Solution |
|---|---|---|
| `KeyError: age_estim` au `.fit()` | `num_columns` calculé sur `df` incluait la target | Calculer `num_columns` depuis `X` uniquement |
| Temps de calcul long | GridSearch × 5-fold sur 4 modèles | Grilles restreintes + `n_jobs=-1` pour paralléliser |
| Overfitting potentiel sur RF | Forêts profondes mémorisant les données | `max_depth` limité dans la grille |

### Pistes d'amélioration

- Tester **XGBoost** ou **LightGBM**, souvent plus performants que GradientBoosting sklearn sur des données tabulaires
- Faire une analyse d'importance des features pour éventuellement retirer des variables peu informatives
- Utiliser une **validation croisée imbriquée** (nested cross-validation) pour une estimation encore plus robuste de la performance
- Explorer des techniques de **réduction des outliers** sur `age_estim` (arbres avec des âges très élevés qui peuvent perturber l'entraînement)

---

*Rapport généré à partir du notebook `preparation_v3.ipynb`*
