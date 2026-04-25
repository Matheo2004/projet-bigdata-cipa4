"""
script_besoin3_gui.py - Interface graphique PySide6
Système d'alerte pour les tempêtes
"""

import sys
import numpy as np
import joblib
from PySide6.QtWidgets import (
    QApplication, QWidget, QLabel, QLineEdit,
    QComboBox, QPushButton, QVBoxLayout, QFormLayout,
    QFrame, QMessageBox
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont

# ---------------------------------------------------------------
# SEUIL DE DÉCISION (modifiable)
# ---------------------------------------------------------------
SEUIL = 0.5

# ---------------------------------------------------------------
# Chargement des modèles
# ---------------------------------------------------------------
try:
    model    = joblib.load('besoin3_model.pkl')
    scaler   = joblib.load('besoin3_scaler.pkl')
    encoders = joblib.load('besoin3_encoders.pkl')
except FileNotFoundError as e:
    print(f"[ERREUR] Fichier introuvable : {e}")
    sys.exit(1)

FEATURES_CAT = ['fk_stadedev', 'fk_port', 'fk_pied', 'fk_situation',
                'fk_revetement', 'feuillage']


class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Système d'alerte tempête")
        self.setMinimumWidth(450)
        self._build_ui()

    def _build_ui(self):
        main_layout = QVBoxLayout(self)
        main_layout.setSpacing(12)
        main_layout.setContentsMargins(20, 20, 20, 20)

        # Titre
        title = QLabel("Système d'alerte pour les tempêtes")
        title.setFont(QFont("Arial", 13, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        main_layout.addWidget(title)

        # Séparateur
        sep = QFrame()
        sep.setFrameShape(QFrame.HLine)
        main_layout.addWidget(sep)

        # Formulaire
        form = QFormLayout()
        form.setSpacing(8)

        # Champs numériques
        self.haut_tot   = QLineEdit()
        self.haut_tronc = QLineEdit()
        self.tronc_diam = QLineEdit()
        self.age_estim  = QLineEdit()

        self.haut_tot.setPlaceholderText("ex: 12")
        self.haut_tronc.setPlaceholderText("ex: 3")
        self.tronc_diam.setPlaceholderText("ex: 80")
        self.age_estim.setPlaceholderText("ex: 40")

        form.addRow("Hauteur totale (m) :",        self.haut_tot)
        form.addRow("Hauteur du tronc (m) :",      self.haut_tronc)
        form.addRow("Diamètre du tronc (cm) :",    self.tronc_diam)
        form.addRow("Âge estimé (années) :",       self.age_estim)

        # Champs catégoriels avec ComboBox
        self.combos = {}
        labels = {
            'fk_stadedev':   "Stade de développement :",
            'fk_port':       "Port de l'arbre :",
            'fk_pied':       "Type de pied :",
            'fk_situation':  "Situation :",
            'fk_revetement': "Revêtement :",
            'feuillage':     "Feuillage :",
        }

        for col in FEATURES_CAT:
            cb = QComboBox()
            cb.addItems(sorted(encoders[col].classes_))
            self.combos[col] = cb
            form.addRow(labels[col], cb)

        main_layout.addLayout(form)

        # Bouton
        btn = QPushButton("Analyser l'arbre")
        btn.setFixedHeight(40)
        btn.setFont(QFont("Arial", 11, QFont.Bold))
        btn.clicked.connect(self._predict)
        main_layout.addWidget(btn)

        # Zone résultat
        self.result_label = QLabel("")
        self.result_label.setAlignment(Qt.AlignCenter)
        self.result_label.setFont(QFont("Arial", 12))
        self.result_label.setWordWrap(True)
        main_layout.addWidget(self.result_label)

    def _predict(self):
        # Lecture des valeurs numériques
        try:
            valeurs_num = [
                float(self.haut_tot.text()),
                float(self.haut_tronc.text()),
                float(self.tronc_diam.text()),
                float(self.age_estim.text()),
            ]
        except ValueError:
            QMessageBox.warning(self, "Erreur", "Les valeurs numériques sont invalides.")
            return

        # Encodage des catégorielles
        valeurs_cat = []
        for col in FEATURES_CAT:
            val = self.combos[col].currentText()
            valeurs_cat.append(encoders[col].transform([val])[0])

        # Prédiction
        X        = np.array(valeurs_num + valeurs_cat, dtype=float).reshape(1, -1)
        X_scaled = scaler.transform(X)
        proba    = model.predict_proba(X_scaled)[0]
        risque   = proba[1] >= SEUIL

        # Affichage
        if risque:
            self.result_label.setText(
                f"⚠️  ARBRE À RISQUE DE DÉRACINEMENT\n"
                f"Probabilité : {proba[1]:.1%}"
            )
            self.result_label.setStyleSheet("color: red;")
        else:
            self.result_label.setText(
                f"✅  Arbre non à risque\n"
                f"Probabilité de déracinement : {proba[1]:.1%}"
            )
            self.result_label.setStyleSheet("color: green;")


if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())