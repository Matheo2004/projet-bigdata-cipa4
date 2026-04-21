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

# Fonction de conversion en numérique
to_numeric <- function(x) {
  x <- gsub(",", ".", x)
  as.numeric(x)
}


# -----------------------------
# NETTOYAGE DU TEXTE
# -----------------------------
# Supprime espaces + transforme "" en NA
for (col in names(data)) {
  if (is.character(data[[col]])) {
    data[[col]] <- trimws(data[[col]])
    data[[col]][data[[col]] == ""] <- NA
  }
}

if ("clc_quartier" %in% names(data)) {
  data$clc_quartier[data$clc_quartier == "HARLY"] <- "Quartier Harly"
  data$clc_quartier[data$clc_quartier == "OMISSY"] <- "Quartier Omissy"
  data$clc_quartier[data$clc_quartier == "ROUVROY"] <- "Quartier Rouvroy"
}

if ("created_user" %in% names(data)) {
  data$created_user[data$created_user == "Edouard Cauchon"] <- "edouard.cauchon"
  data$created_user[data$created_user == "Thibaut DELAIRE"] <- "thibaut.delaire"
}

if ("fk_stadedev" %in% names(data)) {
  data$fk_stadedev[data$fk_stadedev == "Adulte"] <- "adulte"
  data$fk_stadedev[data$fk_stadedev == "Jeune"] <- "jeune"
}

if ("src_geo" %in% names(data)) {
  data$src_geo[data$src_geo == "Orthophoto plan"] <- "Orthophoto"
  data$src_geo[data$src_geo == "Plan ortho"] <- "Orthophoto"
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

if ("age_estim" %in% names(data)) {
  data <- data[data$age_estim != 2010 | is.na(data$age_estim), ]
}


# -----------------------------
# SUPPRESSION DES DOUBLONS
# -----------------------------
dup_idx <- duplicated(data)
nb_doublons <- sum(dup_idx)
data <- data[!dup_idx, ]


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
cat("Doublons supprimés :", nb_doublons, "\n")
cat("Lignes sans coordonnées :", nb_sans_coord, "\n")
cat("Nb lignes après nettoyage :", nrow(data), "\n")


# -----------------------------
# VALEURS MANQUANTES
# -----------------------------
cat("\n=== VALEURS MANQUANTES ===\n")

for (col in names(data)) {
  cat(col, ":", sum(is.na(data[[col]])), "\n")
}
