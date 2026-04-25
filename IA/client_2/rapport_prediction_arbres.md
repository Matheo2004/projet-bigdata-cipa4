# Prédiction de l'âge des arbres
**Mathéo Bertin** — Projet Machine Learning

---

## Contexte

L'idée de ce projet est simple : on a un dataset d'arbres urbains avec des infos comme la hauteur, le diamètre du tronc ou l'espèce, et on veut prédire leur âge automatiquement. Concrètement, ça permettrait à un agent sur le terrain de prendre quelques mesures et d'obtenir une estimation sans avoir à fouiller les archives de plantation.

C'est un problème de régression supervisée, puisque la variable cible (`age_estim`) est continue.

---

## Données

Le dataset contient **11 248 arbres** et **37 colonnes**. La plupart des colonnes sont des métadonnées (identifiants, dates de saisie, infos administratives) qui ne servent à rien pour prédire l'âge. J'en ai gardé 10 qui ont un sens réel :

| Variable | Type | Pourquoi |
|---|---|---|
| `haut_tot` | Numérique | Plus un arbre est vieux, plus il est grand |
| `haut_tronc` | Numérique | Idem pour la hauteur du tronc |
| `tronc_diam` | Numérique | Indicateur classique d'âge |
| `clc_nbr_diag` | Numérique | Nombre de diagnostics |
| `fk_prec_estim` | Numérique | Précision de l'estimation |
| `clc_quartier` | Catégorielle | Peut refléter des périodes de plantation |
| `nomlatin` | Catégorielle | L'espèce influence beaucoup la croissance |
| `fk_stadedev` | Catégorielle | Stade de développement |
| `fk_arb_etat` | Catégorielle | État sanitaire |
| `fk_situation` | Catégorielle | Contexte (rue, parc…) |

Après suppression des lignes sans `age_estim`, il reste **10 415 observations**. Les valeurs manquantes dans les features sont gérées plus tard dans le pipeline.

> **Bug rencontré :** dans une première version, j'avais inclus `age_estim` dans les colonnes numériques du préprocesseur. Ça causait un `KeyError` au `fit()` parce que la colonne n'existe plus dans `X_train`. Corrigé en détectant les types de colonnes sur `X` uniquement, après avoir séparé features et cible.

---

## Prétraitement

J'ai utilisé un `ColumnTransformer` avec deux pipelines selon le type de colonne :

- **Numériques :** imputation par la médiane (plus robuste que la moyenne face aux outliers) + `StandardScaler`. La normalisation est obligatoire pour SVR et LinearRegression qui sont sensibles aux échelles.
- **Catégorielles :** imputation par la valeur la plus fréquente + `OneHotEncoder` avec `handle_unknown="ignore"` pour éviter les erreurs si le test contient des modalités inconnues.

Tout est encapsulé dans des `Pipeline` scikit-learn, ce qui garantit qu'il n'y a pas de data leakage : le préprocesseur est fitté uniquement sur le train set.

Split : **80% train** (8 332 lignes) / **20% test** (2 083 lignes), `random_state=42`.

---

## Modèles testés

J'ai comparé 4 algorithmes pour couvrir différentes approches :

- **LinearRegression** — le modèle de référence le plus simple
- **SVR** — approche par noyau, flexible mais sensible aux hyperparamètres
- **RandomForest** — ensemble par bagging, robuste et peu sensible au réglage
- **GradientBoosting** — ensemble par boosting, souvent très performant mais plus long à entraîner

Les métriques utilisées sont le **R²** (métrique principale), le **MAE** (erreur en années, facile à interpréter) et le **RMSE** (pénalise plus les grosses erreurs).

---

## Résultats

### Baseline

| Modèle | R² Test | MAE | RMSE |
|---|---|---|---|
| RandomForest | **0.9505** | **1.99** | 4.53 |
| GradientBoosting | 0.9110 | 4.20 | 6.07 |
| LinearRegression | 0.8477 | 5.58 | 7.93 |
| SVR | 0.8259 | 4.37 | 8.48 |

Le RandomForest domine déjà largement avec un R² de 0,95 et un MAE de moins de 2 ans. La LinearRegression confirme que la relation n'est pas linéaire.

### Après GridSearchCV (cv=5, scoring=R²)

| Modèle | R² Optimisé | MAE | RMSE | ΔR² |
|---|---|---|---|---|
| RandomForest | **0.9506** | **1.99** | **4.52** | +0.0002 |
| GradientBoosting | 0.9434 | 2.49 | 4.84 | +0.0324 |
| SVR | 0.9061 | 3.05 | 6.23 | +0.0802 |
| LinearRegression | 0.8477 | 5.58 | 7.93 | +0.0000 |

Le GridSearch apporte surtout pour SVR (+0,08) et GradientBoosting (+0,03). Pour le RandomForest, c'était déjà quasiment optimal avec les paramètres par défaut.

Meilleurs hyperparamètres trouvés :
- RandomForest : `n_estimators=300`, `max_depth=None`, `min_samples_split=2`
- GradientBoosting : `learning_rate=0.2`, `max_depth=7`, `n_estimators=200`
- SVR : `C=10`, `epsilon=1.0`, `kernel=rbf`

---

## Meilleur modèle — RandomForest

| | Train | Test |
|---|---|---|
| R² | 0.9932 | 0.9506 |
| MAE | 0.77 ans | 1.99 ans |
| RMSE | 1.68 ans | 4.52 ans |

L'écart de généralisation (R² train − test = 0,04) est modéré. Il y a un léger overfitting, ce qui est normal pour un RandomForest sans contrainte de profondeur, mais ça reste très acceptable. Le MAE de 1,99 an est très bon vu que les âges vont de 0 à 200 ans.

---

## Conclusion

Le RandomForest optimisé est clairement le meilleur modèle sur ce problème, avec **R²=0,95 et MAE=1,99 an** sur le test set. L'approche par ensemble capture bien les relations non-linéaires entre les features et l'âge, ce que la régression linéaire ne peut pas faire.

Ce projet m'a surtout permis de travailler sur la structuration d'un pipeline ML complet : sélection de features, prétraitement propre, comparaison de modèles et optimisation. Le modèle est sauvegardé dans `modele_arbre.pkl` et directement utilisable.

Ce que j'aurais pu améliorer : contraindre `max_depth` du RandomForest pour réduire l'overfitting, et potentiellement explorer des features supplémentaires comme les coordonnées géographiques.
