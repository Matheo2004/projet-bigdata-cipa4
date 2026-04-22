library(ggplot2)
library(dplyr)
library(Factoshiny)
library(ggpubr)
library(questionr)

# Configuration de l'environnement de travail
setwd("C:\\Users\\CMoi\\Documents\\Projet_Big_Data")

# Importation du dataset (gestion de l'encodage UTF-8 et conversion automatique en facteurs)
arbres = read.csv2("Data_Arbre_Clean.csv", fileEncoding = "utf-8", stringsAsFactors = T, sep = ',')

# Data Cleaning : Suppression des valeurs aberrantes sur l'âge estimé
arbres = arbres %>% filter(age_estim < 2000)

# --- PARTIE 1 : MODÉLISATION PRÉDICTIVE DE L'ÂGE (Régression Linéaire) ---

# Préparation des variables quantitatives
arbres$haut_tot <- as.numeric(arbres$haut_tot)
arbres$haut_tronc <- as.numeric(arbres$haut_tronc)

# Analyse de corrélation : Identification des colinéarités entre variables dendrométriques
num <- arbres[,c("haut_tot", "haut_tronc", "tronc_diam", "age_estim")]
round(cor(num, use="complete.obs"), 2)

# Modèle initial avec interaction (effet synergique diamètre * hauteur)
modele_inter <- lm(age_estim ~ tronc_diam * haut_tronc, data = arbres)
summary(modele_inter)

# Nettoyage des données manquantes pour la comparaison de modèles
arbres <- arbres %>%
  filter(!is.na(age_estim), !is.na(tronc_diam), !is.na(haut_tronc), 
         !is.na(nomlatin), !is.na(clc_quartier))

# Sélection de modèles : Test de l'apport des variables catégorielles (espèce et quartier)
modele1 <- lm(age_estim ~ tronc_diam * haut_tronc, data = arbres)
modele2 <- lm(age_estim ~ tronc_diam * haut_tronc * nomlatin, data = arbres)
modele3 <- lm(age_estim ~ tronc_diam * haut_tronc * clc_quartier, data = arbres)
modele4 <- lm(age_estim ~ tronc_diam * haut_tronc * nomlatin + clc_quartier, data = arbres)
modele5 <- lm(age_estim ~ tronc_diam * haut_tronc * clc_quartier + nomlatin, data = arbres)

# Analyse de la variance (ANOVA) pour comparer la performance et la parcimonie des modèles
anova(modele1, modele2, modele3, modele4, modele5)


# --- PARTIE 2 : ANALYSE SPATIALE ET STRUCTURELLE ---

# Analyse de la dépendance entre localisation et maturité du parc (Chi-deux)
tab <- table(arbres$clc_quartier, arbres$fk_stadedev)
lprop(tab) # Profils colonnes
chisq.test(tab)

# Visualisation des résidus du Chi-deux par graphique mosaïque
mosaicplot(tab, las = 2, shade = TRUE, main = "Lien entre Quartier et Stade de Développement")


# --- PARTIE 3 : MACHINE LEARNING PRÉDICTIF (Régression Logistique) ---

# Feature Engineering : Création de la variable cible binaire et nettoyage des modalités
arbres_etude <- arbres %>%
  mutate(
    target_abattu = ifelse(fk_arb_etat == "ABATTU", 1, 0),
    fk_pied = trimws(tolower(fk_pied))
  ) %>%
  filter(!is.na(target_abattu), !is.na(age_estim), !is.na(tronc_diam), 
         !is.na(haut_tot), !is.na(haut_tronc), !is.na(fk_situation), !is.na(fk_stadedev))

# Construction du modèle logit (Probability of removal)
modele_logit <- glm(
  target_abattu ~ age_estim + tronc_diam + haut_tot + haut_tronc + fk_situation + 
    fk_stadedev + fk_pied + fk_revetement + fk_port + clc_quartier + clc_secteur, 
  data = arbres_etude, 
  family = binomial(link = "logit")
)

# Scoring : Calcul des probabilités individuelles d'abattage
predictions <- predict(modele_logit, type = "response")
arbres_etude$proba_abattage <- NA
arbres_etude[names(predictions), "proba_abattage"] <- predictions

# Diagnostic du modèle (Déviance et coefficients)
summary(modele_logit)

# Isolation des "individus en sursis" (Seuil de probabilité >= 45%)
arbres_abattre <- arbres_etude %>% filter(proba_abattage >= 0.45)
arbres_abattre