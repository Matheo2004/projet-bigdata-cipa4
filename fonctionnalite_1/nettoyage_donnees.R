# -----------------------------
# CHARGEMENT DES DONNÉES
# -----------------------------
data <- read.csv(
  "C:/Users/mathe/Documents/projet-bigdata-cipa4/data/Data_Arbre_Input.csv",
  stringsAsFactors = FALSE
)

# Fichier de sortie
output_path <- "C:/Users/mathe/Documents/projet-bigdata-cipa4/data/Data_Arbre_Clean.csv"

cat("=== DEBUT DU NETTOYAGE ===\n")
cat("Nb lignes avant :", nrow(data), "\n")


# -----------------------------
# VARIABLES NUMÉRIQUES
# -----------------------------
num_vars <- c("haut_tot", "haut_tronc", "tronc_diam",
              "age_estim", "clc_nbr_diag", "X", "Y")

# Fonction simple pour convertir en numérique
to_numeric <- function(x) {
  x <- gsub(",", ".", x)
  as.numeric(x)
}


# -----------------------------
# NETTOYAGE DU TEXTE
# -----------------------------
for (col in names(data)) {
  if (is.character(data[[col]])) {
    data[[col]] <- trimws(data[[col]])
    data[[col]][data[[col]] == ""] <- NA
  }
}


# -----------------------------
# HARMONISATION DE QUELQUES VALEURS
# -----------------------------

# Quartiers
if ("clc_quartier" %in% names(data)) {
  data$clc_quartier[data$clc_quartier == "HARLY"] <- "Quartier Harly"
  data$clc_quartier[data$clc_quartier == "OMISSY"] <- "Quartier Omissy"
  data$clc_quartier[data$clc_quartier == "ROUVROY"] <- "Quartier Rouvroy"
}

# Utilisateurs
if ("created_user" %in% names(data)) {
  data$created_user[data$created_user == "Edouard Cauchon"] <- "edouard.cauchon"
  data$created_user[data$created_user == "Thibaut DELAIRE"] <- "thibaut.delaire"
}

# Stade de développement
if ("fk_stadedev" %in% names(data)) {
  data$fk_stadedev[data$fk_stadedev == "Adulte"] <- "adulte"
  data$fk_stadedev[data$fk_stadedev == "Jeune"] <- "jeune"
}

# Source géographique
if ("src_geo" %in% names(data)) {
  data$src_geo[data$src_geo %in% c("Orthophoto plan", "Plan ortho")] <- "Orthophoto"
  data$src_geo[data$src_geo == "à renseigner"] <- NA
}


# -----------------------------
# CONVERSION EN NUMÉRIQUE
# -----------------------------
for (v in num_vars) {
  if (v %in% names(data)) {
    data[[v]] <- to_numeric(data[[v]])
  }
}


# -----------------------------
# SUPPRESSION VALEURS ABERRANTES
# -----------------------------
# Exemple : âge impossible
if ("age_estim" %in% names(data)) {
  data <- data[data$age_estim <= 500 | is.na(data$age_estim), ]
}


# -----------------------------
# SUPPRESSION DES DOUBLONS EXACTS
# -----------------------------
dup_idx <- duplicated(data)
nb_doublons <- sum(dup_idx)
data <- data[!dup_idx, ]


# -----------------------------
# SUPPRESSION DES DOUBLONS DE COORDONNÉES
# -----------------------------
dup_coord <- duplicated(data[c("X", "Y")])
nb_doublons_coord <- sum(dup_coord)
data <- data[!dup_coord, ]


# -----------------------------
# SUPPRESSION DES LIGNES SANS COORDONNÉES
# -----------------------------
coord_na <- is.na(data$X) | is.na(data$Y)
nb_sans_coord <- sum(coord_na)
data <- data[!coord_na, ]


# -----------------------------
# SAUVEGARDE
# -----------------------------
write.csv(data, output_path, row.names = FALSE)


# -----------------------------
# RÉSUMÉ FINAL
# -----------------------------
cat("\n=== RESUME ===\n")
cat("Doublons exacts supprimés :", nb_doublons, "\n")
cat("Doublons de coordonnées supprimés :", nb_doublons_coord, "\n")
cat("Lignes sans coordonnées :", nb_sans_coord, "\n")
cat("Nb lignes après nettoyage :", nrow(data), "\n")


# -----------------------------
# VALEURS MANQUANTES
# -----------------------------
cat("\n=== VALEURS MANQUANTES ===\n")

for (col in names(data)) {
  cat(col, ":", sum(is.na(data[[col]])), "\n")
}