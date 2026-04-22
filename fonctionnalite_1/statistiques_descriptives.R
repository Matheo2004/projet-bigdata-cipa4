# Trouve le dossier du script pour construire des chemins robustes
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

# Recherche automatique du dossier "data" selon le contexte d'execution
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

# Convertit des valeurs texte en numerique (virgule -> point)
to_numeric <- function(x) {
  suppressWarnings(as.numeric(gsub(",", ".", x)))
}

# Cree un tableau de frequences lisible pour une variable qualitative
safe_table <- function(x) {
  x[x == ""] <- NA
  sort(table(x, useNA = "ifany"), decreasing = TRUE)
}

# Choix du fichier: on privilegie le fichier propre s'il existe
data_dir <- resolve_data_dir()
clean_path <- file.path(data_dir, "Data_Arbre_Clean.csv")
input_path <- file.path(data_dir, "Data_Arbre_Input.csv")
data_path <- if (file.exists(clean_path)) clean_path else input_path

# Arret si aucun fichier disponible
if (!file.exists(data_path)) {
  stop(paste("Aucun fichier de donnees trouve :", data_dir))
}

# Lecture des donnees
data <- read.csv(data_path, stringsAsFactors = FALSE, check.names = FALSE)
cat("Fichier charge :", data_path, "\n")
cat("Lignes :", nrow(data), "| Colonnes :", ncol(data), "\n")

# Variables analysees
num_vars <- c("haut_tot", "haut_tronc", "tronc_diam", "age_estim", "clc_nbr_diag")
cat_vars <- c("fk_arb_etat", "fk_situation", "feuillage", "remarquable", "clc_quartier")

# Statistiques univariees quantitatives
cat("\n=== STATISTIQUES UNIVARIEES: VARIABLES QUANTITATIVES ===\n")
for (v in num_vars) {
  if (!(v %in% names(data))) {
    cat("\nVariable absente :", v, "\n")
    next
  }

  x <- to_numeric(data[[v]])
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    cat("\nVariable :", v, "- aucune valeur exploitable\n")
    next
  }

  cat("\nVariable :", v, "\n")
  cat("Effectif :", length(x), "\n")
  cat("Min :", min(x), "\n")
  cat("Q1 :", unname(quantile(x, 0.25)), "\n")
  cat("Mediane :", median(x), "\n")
  cat("Q3 :", unname(quantile(x, 0.75)), "\n")
  cat("Max :", max(x), "\n")
  cat("Moyenne :", mean(x), "\n")
}

# Statistiques univariees qualitatives
cat("\n=== STATISTIQUES UNIVARIEES: VARIABLES QUALITATIVES ===\n")
for (v in cat_vars) {
  if (!(v %in% names(data))) {
    cat("\nVariable absente :", v, "\n")
    next
  }

  cat("\nVariable :", v, "\n")
  print(safe_table(data[[v]]))
}

# Tableau croise etat / situation
if (all(c("fk_arb_etat", "fk_situation") %in% names(data))) {
  cat("\n=== TABLEAU CROISE ETAT x SITUATION ===\n")
  print(table(data$fk_arb_etat, data$fk_situation, useNA = "ifany"))
}

# Tableau croise remarquable / feuillage
if (all(c("remarquable", "feuillage") %in% names(data))) {
  cat("\n=== TABLEAU CROISE REMARQUABLE x FEUILLAGE ===\n")
  print(table(data$remarquable, data$feuillage, useNA = "ifany"))
}

# Correlation entre hauteur totale et diametre du tronc
if (all(c("haut_tot", "tronc_diam") %in% names(data))) {
  cat("\n=== CORRELATION haut_tot x tronc_diam ===\n")
  x <- to_numeric(data$haut_tot)
  y <- to_numeric(data$tronc_diam)
  print(cor(x, y, use = "complete.obs"))
}

# Hauteur moyenne regroupee par situation
if (all(c("fk_situation", "haut_tot") %in% names(data))) {
  cat("\n=== HAUTEUR MOYENNE PAR SITUATION ===\n")
  x <- to_numeric(data$haut_tot)
  res <- aggregate(x, by = list(data$fk_situation), mean, na.rm = TRUE)
  names(res) <- c("situation", "hauteur_moyenne")
  print(res)
}
