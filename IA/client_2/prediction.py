import pandas as pd
import joblib

# Chargement des données
df = pd.read_csv(r"C:\Users\mathe\Documents\projetbigdata_trinome3\IA\client_2\Data_Arbre_Clean.csv")

# Importation du modèle entrainé
model = joblib.load("modele_arbre.pkl")

# enlever les lignes sans age
df = df.dropna(subset=["age_estim"])

# prendre une ligne
row = df.iloc[9]

# vrai age
true_age = row["age_estim"]

# valeurs test
X_test = row.drop("age_estim")

# transformer les valeurs test en DataFrame
X_test = pd.DataFrame([X_test])

# prédiction
pred = model.predict(X_test)[0]

print("Age réel :", true_age)
print("Age prédit :", pred)
print("Erreur :", abs(true_age - pred))