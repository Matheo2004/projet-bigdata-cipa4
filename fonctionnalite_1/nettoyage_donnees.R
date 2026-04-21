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


# -----------------------------
# CONVERSION EN NUMÉRIQUE
# -----------------------------
for (v in num_vars) {
  if (v %in% names(data)) {
    data[[v]] <- to_numeric(data[[v]])
  }
}


# -----------------------------
# HARMONISATION DES VARIABLES
# -----------------------------

# Remplace les valeurs de "remarquable"
if ("remarquable" %in% names(data)) {
  data$remarquable <- ifelse(data$remarquable == "OUI", "Oui",
                             ifelse(data$remarquable == "NON", "Non",
                                    data$remarquable))
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