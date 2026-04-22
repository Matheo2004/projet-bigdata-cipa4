library(ggplot2)
library(dplyr)
library(Factoshiny)
library(ggpubr)
library(questionr)

# définir le répertoire de travail
setwd("C:\\Users\\CMoi\\Documents\\Projet_Big_Data")

# importer le jeu de données
arbres = read.csv2("Data_Arbre_Clean.csv", fileEncoding = "utf-8", stringsAsFactors = T, sep = ',')

arbres=arbres%>%filter(age_estim<2000)

# Répartition des arbres par quartier
ggplot(arbres, aes(x = clc_quartier)) +
  geom_bar(fill = "forestgreen") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  labs(title = "Répartition du nombre d'arbres par quartier",
    x = "Quartier", y = "Nombre d'arbres")

# Répartition des arbres par stade
ggplot(arbres)+aes(x=fk_stadedev)+geom_bar(fill="palegreen4") +
  labs(title = "Répartition du stade de développement des arbres",
       x = "Stade de développement", y = "Nombre d'arbres")

# Répartition des arbres par age
ggplot(arbres)+aes(x=age_estim)+geom_bar(fill="springgreen4") +
  labs(title = "Répartition des arbres par âge",
       x = "Age de l'arbre", y = "Nombre d'arbres")

# Répartition des arbres par état
ggplot(arbres)+aes(x=fk_arb_etat)+geom_bar(fill="seagreen4") +
  labs(title = "Répartition des arbres par état",
       x = "Etat de l'arbre", y = "Nombre d'arbres")+
  theme(axis.text.x = element_text(angle = 45, hjust = 1))
