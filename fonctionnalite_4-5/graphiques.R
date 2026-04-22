library(ggplot2)
library(dplyr)
library(Factoshiny)
library(ggpubr)
library(questionr)

# définir le répertoire de travail
setwd("C:\\Users\\CMoi\\Documents\\Projet_Big_Data")

# importer le jeu de données
arbres = read.csv2("Data_Arbre_Clean.csv", fileEncoding = "utf-8", stringsAsFactors = T, sep = ',')

names(arbres)

summary(arbres)

arbres=arbres%>%filter(age_estim<2000)

arbres$haut_tot<-as.numeric(arbres$haut_tot)
arbres$haut_tronc<-as.numeric(arbres$haut_tronc)

num<-arbres[,c("haut_tot","haut_tronc","tronc_diam","age_estim")]
round(cor(num, use="complete.obs"),2)
modele_inter <- lm(age_estim ~ tronc_diam*haut_tronc, data = arbres)
summary(modele_inter)

ggplot(arbres, aes(x = tronc_diam, y = age_estim, color = clc_quartier)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Relation Diamètre/Âge par Quartier",
       x = "Diamètre du tronc", y = "Âge estimé")
modele_inter <- lm(age_estim ~ tronc_diam*haut_tronc*clc_quartier, data = arbres)
modele_simple <- lm(age_estim ~ tronc_diam*haut_tronc+clc_quartier, data = arbres)
anova(modele_simple,modele_inter)
summary(modele_inter)

arbres <- arbres %>%
  mutate(fk_pied = tolower(fk_pied))
ggplot(arbres, aes(x = tronc_diam, y = age_estim, color = fk_pied)) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Relation Diamètre/Âge par type de sol",
       x = "Diamètre du tronc", y = "Âge estimé")
modele_inter <- lm(age_estim ~ tronc_diam*haut_tronc*fk_pied, data = arbres)
modele_simple <- lm(age_estim ~ tronc_diam*haut_tronc+fk_pied, data = arbres)
anova(modele_simple,modele_inter)
summary(modele_inter)

ggplot(arbres, aes(x = tronc_diam, y = age_estim, color = nomlatin )) +
  geom_point(alpha = 0.3) +
  geom_smooth(method = "lm", se = FALSE) +
  labs(title = "Relation Diamètre/Âge par type de sol",
       x = "Diamètre du tronc", y = "Âge estimé")
modele_inter <- lm(age_estim ~ tronc_diam*haut_tronc*nomlatin , data = arbres)
modele_simple <- lm(age_estim ~ tronc_diam*haut_tronc+nomlatin , data = arbres)
anova(modele_simple,modele_inter)
summary(modele_inter)

# Garder seulement les espèces présentes plus de 50 fois
arbres <- arbres %>%
  group_by(nomlatin) %>%
  filter(n() > 50)

arbres <- arbres %>%
  filter(!is.na(age_estim), 
         !is.na(tronc_diam), 
         !is.na(haut_tronc), 
         !is.na(nomlatin), 
         !is.na(clc_quartier))
modele1<- lm(age_estim ~ tronc_diam*haut_tronc , data = arbres)
modele2<- lm(age_estim ~ tronc_diam*haut_tronc*nomlatin , data = arbres)
modele3<- lm(age_estim ~ tronc_diam*haut_tronc*clc_quartier , data = arbres)
modele4<- lm(age_estim ~ tronc_diam*haut_tronc*nomlatin+clc_quartier , data = arbres)
modele5<- lm(age_estim ~ tronc_diam*haut_tronc*clc_quartier+nomlatin , data = arbres)
summary(modele4)
anova(modele1,modele2,modele3,modele4,modele5)
tab<-table(arbres$clc_quartier,arbres$fk_stadedev)
lprop(tab)
chisq.test(tab)
mosaicplot(tab, las = 2, shade = TRUE)+labs(title = "Lien entre Quartier et Stade de Développement")

# ==========================================================
# ANALYSE PRÉDICTIVE DES ABATTAGES (RÉGRESSION LOGISTIQUE)
# ==========================================================

# 1. Chargement des bibliothèques nécessaires
library(dplyr)

# 2. Nettoyage et préparation du jeu de données
# On crée une variable binaire : 1 si l'arbre est abattu, 0 sinon.
# On s'assure que les variables qualitatives sont propres.
arbres_etude <- arbres %>%
  mutate(
    # Variable cible (Y)
    target_abattu = ifelse(fk_arb_etat == "ABATTU", 1, 0),
    # Nettoyage des textes (minuscules et suppression d'espaces)
    fk_pied = trimws(tolower(fk_pied))
  ) %>%
  # Conservation uniquement des lignes sans valeurs manquantes pour les variables du modèle
  # Cela évite l'erreur de différence de longueur lors de la prédiction
  filter(
    !is.na(target_abattu),
    !is.na(age_estim),
    !is.na(tronc_diam),
    !is.na(haut_tot),
    !is.na(haut_tronc),
    !is.na(fk_situation),
    !is.na(fk_stadedev)
  )

# 3. Construction du modèle de Régression Logistique
# On cherche à expliquer 'target_abattu' par les caractéristiques de l'arbre
modele_logit <- glm(
  target_abattu ~ age_estim + tronc_diam + haut_tot + haut_tronc + fk_situation + fk_stadedev+fk_pied+fk_revetement+fk_port+clc_quartier+clc_secteur, 
  data = arbres_etude, 
  family = binomial(link = "logit")
)

# 1. Calcul des probabilités
# R génère un vecteur qui n'a pas forcément la même taille que le tableau 'arbres_etude'
predictions <- predict(modele_logit, type = "response")

# 2. Création d'une colonne vide dans le tableau d'origine
arbres_etude$proba_abattage <- NA

# 3. Alignement précis des données
# On utilise les noms des lignes (les index) pour mettre la bonne proba au bon endroit
arbres_etude[names(predictions), "proba_abattage"] <- predictions

# 4. Maintenant tu peux filtrer et voir tes alertes
liste_alertes <- arbres_etude %>%
  filter(target_abattu == 0, !is.na(proba_abattage)) %>%
  select(id_arbre, nomfrancais, clc_quartier, proba_abattage) %>%
  arrange(desc(proba_abattage))

head(liste_alertes, 10)
#Seul 8973 arbres ont pu être analysés car manque de valeurs dans certaines catégories