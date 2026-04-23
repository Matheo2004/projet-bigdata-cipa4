# Cette fonction trouve le dossier du script en cours.
# Elle permet d'eviter les chemins absolus qui cassent selon la machine.
get_script_dir <- function() {
  file_arg <- "--file="
  args <- commandArgs(trailingOnly = FALSE)
  match <- grep(file_arg, args)

  if (length(match) > 0) {
    return(dirname(normalizePath(sub(file_arg, "", args[match[1]]))))
  }

  if (!is.null(sys.frames()[[1]]$ofile)) {
    return(dirname(normalizePath(sys.frames()[[1]]$ofile)))
  }

  return(getwd())
}

# Cette fonction cherche automatiquement le dossier "data".
# On teste plusieurs emplacements possibles selon la facon dont le script est lance.
resolve_data_dir <- function() {
  script_dir <- get_script_dir()
  candidates <- c(
    file.path(script_dir, "..", "data"),
    file.path(script_dir, "data"),
    file.path(getwd(), "data")
  )

  for (path in candidates) {
    if (dir.exists(path)) {
      return(normalizePath(path, winslash = "/", mustWork = TRUE))
    }
  }

  stop("Dossier 'data' introuvable. Verifie le dossier projet.")
}

# Convertit une colonne texte en numerique
# (utile si des virgules sont utilisees comme separateur decimal).
to_numeric <- function(x) {
  suppressWarnings(as.numeric(gsub(",", ".", x)))
}

# Nettoie toutes les colonnes texte:
# - supprime les espaces inutiles
# - remplace les chaines vides par NA
clean_text_columns <- function(df) {
  for (col in names(df)) {
    if (is.character(df[[col]])) {
      df[[col]] <- trimws(df[[col]])
      df[[col]][df[[col]] == ""] <- NA
    }
  }
  return(df)
}

# Harmonise quelques valeurs connues pour avoir des categories coherentes.
# Cela evite d'avoir plusieurs ecritures pour la meme information.
harmonize_values <- function(df) {
  if ("clc_quartier" %in% names(df)) {
    df$clc_quartier[df$clc_quartier == "HARLY"] <- "Quartier Harly"
    df$clc_quartier[df$clc_quartier == "OMISSY"] <- "Quartier Omissy"
    df$clc_quartier[df$clc_quartier == "ROUVROY"] <- "Quartier Rouvroy"
  }

  if ("created_user" %in% names(df)) {
    df$created_user[df$created_user == "Edouard Cauchon"] <- "edouard.cauchon"
    df$created_user[df$created_user == "Thibaut DELAIRE"] <- "thibaut.delaire"
  }

  if ("fk_stadedev" %in% names(df)) {
    df$fk_stadedev[df$fk_stadedev == "Adulte"] <- "adulte"
    df$fk_stadedev[df$fk_stadedev == "Jeune"] <- "jeune"
  }

  if ("src_geo" %in% names(df)) {
    df$src_geo[df$src_geo %in% c("Orthophoto plan", "Plan ortho")] <- "Orthophoto"
    src_geo_norm <- trimws(tolower(df$src_geo))
    df$src_geo[src_geo_norm %in% c("à renseigner", "a renseigner", "ã  renseigner")] <- NA
  }

  return(df)
}

# Convertit en numerique seulement les colonnes qui existent dans le jeu de donnees.
convert_numeric_columns <- function(df, cols) {
  for (col in cols) {
    if (col %in% names(df)) {
      df[[col]] <- to_numeric(df[[col]])
    }
  }
  return(df)
}

# Resolution des chemins de lecture/ecriture
data_dir <- resolve_data_dir()
input_path <- file.path(data_dir, "Data_Arbre_Input.csv")
output_path <- file.path(data_dir, "Data_Arbre_Clean.csv")

# Verification simple: on arrete si le fichier source est absent
if (!file.exists(input_path)) {
  stop(paste("Fichier introuvable :", input_path))
}

# Lecture du fichier brut
data <- read.csv(input_path, stringsAsFactors = FALSE, check.names = FALSE)

# Colonnes numeriques utilisees dans le nettoyage
num_vars <- c("haut_tot", "haut_tronc", "tronc_diam", "age_estim", "clc_nbr_diag", "X", "Y")

cat("=== DEBUT DU NETTOYAGE ===\n")
cat("Lignes initiales :", nrow(data), "\n")

# Etapes de preparation
data <- clean_text_columns(data)
data <- harmonize_values(data)
data <- convert_numeric_columns(data, num_vars)

# Suppression d'ages clairement aberrants
if ("age_estim" %in% names(data)) {
  data <- data[data$age_estim <= 500 | is.na(data$age_estim), ]
}

# Suppression des doublons exacts
dup_idx <- duplicated(data)
nb_doublons <- sum(dup_idx, na.rm = TRUE)
data <- data[!dup_idx, ]

# Suppression des doublons de coordonnees puis des lignes sans coordonnees
nb_doublons_coord <- 0
nb_sans_coord <- 0
if (all(c("X", "Y") %in% names(data))) {
  dup_coord <- duplicated(data[c("X", "Y")])
  nb_doublons_coord <- sum(dup_coord, na.rm = TRUE)
  data <- data[!dup_coord, ]

  coord_na <- is.na(data$X) | is.na(data$Y)
  nb_sans_coord <- sum(coord_na, na.rm = TRUE)
  data <- data[!coord_na, ]
}

# Export du fichier nettoye
write.csv(data, output_path, row.names = FALSE)

# Resume final pour suivre ce qui a ete retire
cat("\n=== RESUME ===\n")
cat("Doublons exacts supprimes :", nb_doublons, "\n")
cat("Doublons coordonnees supprimes :", nb_doublons_coord, "\n")
cat("Lignes sans coordonnees :", nb_sans_coord, "\n")
cat("Lignes finales :", nrow(data), "\n")
cat("Fichier exporte :", output_path, "\n")

# Affiche le nombre de NA par colonne apres nettoyage
cat("\n=== VALEURS MANQUANTES PAR COLONNE ===\n")
for (col in names(data)) {
  cat(col, ":", sum(is.na(data[[col]])), "\n")
}
