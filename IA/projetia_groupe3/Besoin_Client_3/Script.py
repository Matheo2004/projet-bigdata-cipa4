"""
script_besoin3.py - Système d'alerte pour les tempêtes
Prédit si un arbre est susceptible d'être déraciné lors d'une tempête.
"""

import joblib
import numpy as np

# ---------------------------------------------------------------
# SEUIL DE DÉCISION
# Modifier cette valeur pour ajuster la sensibilité du système :
# - Valeur basse (ex: 0.3) → plus d'alertes, moins de risques ratés
# - Valeur haute (ex: 0.7) → moins d'alertes, plus de risques ratés
# ---------------------------------------------------------------
SEUIL = 0.5

# ---------------------------------------------------------------
# Chargement des modèles pré-entraînés
# ---------------------------------------------------------------
model    = joblib.load('besoin3_model.pkl')
scaler   = joblib.load('besoin3_scaler.pkl')
encoders = joblib.load('besoin3_encoders.pkl')

FEATURES_NUM = ['haut_tot', 'haut_tronc', 'tronc_diam', 'age_estim']
FEATURES_CAT = ['fk_stadedev', 'fk_port', 'fk_pied', 'fk_situation',
                'fk_revetement', 'feuillage']

# ---------------------------------------------------------------
# Saisie interactive
# ---------------------------------------------------------------
print("\n========================================")
print("  SYSTÈME D'ALERTE TEMPÊTE")
print("  Entrez les caractéristiques de l'arbre")
print("========================================\n")

try:
    haut_tot   = float(input("Hauteur totale (m)        : "))
    haut_tronc = float(input("Hauteur du tronc (m)      : "))
    tronc_diam = float(input("Diamètre du tronc (cm)    : "))
    age_estim  = float(input("Âge estimé (années)       : "))
except ValueError:
    print("\n[ERREUR] Les valeurs numériques sont invalides.")
    exit(1)

print()
fk_stadedev   = input("Stade de développement    (jeune / adulte / vieux / senescent) : ")
fk_port       = input("Port de l'arbre           (ex: semi libre, libre, ...) : ")
fk_pied       = input("Type de pied              (ex: gazon, Terre, ...) : ")
fk_situation  = input("Situation                 (Alignement / Groupe / Isolé) : ")
fk_revetement = input("Revêtement autour du pied (Oui / Non) : ")
feuillage     = input("Type de feuillage         (Feuillu / Conifère) : ")

# ---------------------------------------------------------------
# Préparation de l'entrée
# ---------------------------------------------------------------
valeurs_num = [haut_tot, haut_tronc, tronc_diam, age_estim]

valeurs_cat_str = {
    'fk_stadedev':   fk_stadedev,
    'fk_port':       fk_port,
    'fk_pied':       fk_pied,
    'fk_situation':  fk_situation,
    'fk_revetement': fk_revetement,
    'feuillage':     feuillage,
}

valeurs_cat = []
for col in FEATURES_CAT:
    val = valeurs_cat_str[col]
    le  = encoders[col]
    if val not in le.classes_:
        print(f"\n[ERREUR] Valeur inconnue pour '{col}' : '{val}'")
        print(f"  Valeurs acceptées : {list(le.classes_)}")
        exit(1)
    valeurs_cat.append(le.transform([val])[0])

X        = np.array(valeurs_num + valeurs_cat, dtype=float).reshape(1, -1)
X_scaled = scaler.transform(X)

# ---------------------------------------------------------------
# Prédiction
# ---------------------------------------------------------------
proba      = model.predict_proba(X_scaled)[0]
prediction = int(proba[1] >= SEUIL)

print("\n========================================")
print("  RÉSULTAT")
print("========================================")
if prediction == 1:
    print("  ⚠️  ARBRE À RISQUE DE DÉRACINEMENT")
else:
    print("  ✅  Arbre non à risque")
print(f"  Probabilité de déracinement : {proba[1]:.1%}")
print(f"  Seuil de décision           : {SEUIL:.0%}")
print("========================================\n")