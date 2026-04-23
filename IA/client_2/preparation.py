import pandas as pd
import joblib
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.impute import SimpleImputer
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score

# Chargement des données
df = pd.read_csv(r"C:\Users\mathe\Documents\projetbigdata_trinome3\IA\client_2\Data_Arbre_Clean.csv")

# Suppression des lignes sans valeur
df = df.dropna(subset=["age_estim"])

# Variable cible
y = df["age_estim"]

# Suppression des colonne inutiles
cols_drop = [
    "OBJECTID","id_arbre","GlobalID",
    "CreationDate","created_date","created_user",
    "last_edited_user","last_edited_date",
    "Creator","Editor","EditDate",
    "commentaire_environnement",
    "dte_plantation","dte_abattage"
]

# Variables explicatives
X = df.drop(columns=cols_drop + ["age_estim"], errors="ignore")

# Séparation des types de variables
cat_columns = X.select_dtypes(include=["object"]).columns
num_columns = X.select_dtypes(exclude=["object"]).columns

# Prétraitement des variables
cat_transformer = Pipeline(steps=[
    ("imputer", SimpleImputer(strategy="most_frequent")),  # valeurs manquantes
    ("encoder", OneHotEncoder(handle_unknown="ignore"))   # encodage
])

# Prétraitement des variables
num_transformer = Pipeline(steps=[
    ("imputer", SimpleImputer(strategy="median")),  # valeurs manquantes
    ("scaler", StandardScaler())                    # normalisation
])

# Assemblage des transformations
preprocessor = ColumnTransformer([
    ("cat", cat_transformer, cat_columns),
    ("num", num_transformer, num_columns)
])

# Modèle
model = RandomForestRegressor(random_state=42)

# Pipeline
pipeline = Pipeline([
    ("preprocessing", preprocessor),
    ("model", model)
])

# Séparation entre train et test
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42
)

# Recherche des meilleurs paramètre
param_grid = {
    "model__n_estimators": [50, 100],
    "model__max_depth": [None, 10, 20]
}

grid = GridSearchCV(
    pipeline,
    param_grid,
    cv=3,
    scoring="r2",
    n_jobs=-1
)

# Entraînement avec optimisation
grid.fit(X_train, y_train)

# Meilleur modèle
best_model = grid.best_estimator_

# Prédictions
y_pred = best_model.predict(X_test)

# Évaluation du modèle
print("MAE :", mean_absolute_error(y_test, y_pred)) # Mean absolute error
print("R² :", r2_score(y_test, y_pred)) # Coefficient de détermination

# Sauvegarde du modèle entrainé
joblib.dump(best_model, "modele_arbre.pkl")