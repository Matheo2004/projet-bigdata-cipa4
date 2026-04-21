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

  getwd()
}

data_path <- file.path(get_script_dir(), "..", "data", "Data_Arbre_Input.csv")
data <- read.csv(data_path, stringsAsFactors = FALSE)

num_vars <- c("haut_tot", "haut_tronc", "tronc_diam", "age_estim", "clc_nbr_diag", "X", "Y")

make_numeric <- function(x) {
  x <- gsub(",", ".", x)
  suppressWarnings(as.numeric(x))
}

for (v in num_vars) {
  if (v %in% names(data)) {
    data[[v]] <- make_numeric(data[[v]])
  }
}

cat("=== VALEURS MANQUANTES ===\n")
manquants <- data.frame(
  variable = names(data),
  nb_manquants = sapply(data, function(x) sum(is.na(x) | x == "")),
  pourcentage = round(sapply(data, function(x) mean(is.na(x) | x == "") * 100), 2),
  row.names = NULL
)
manquants <- manquants[order(-manquants$nb_manquants), ]
print(manquants)

cat("\n=== VALEURS ABERRANTES (methode IQR) ===\n")
detect_outliers <- function(x) {
  x <- x[!is.na(x)]
  if (length(x) == 0) {
    return(c(nb_aberrantes = 0, borne_inf = NA, borne_sup = NA))
  }
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  low <- q1 - 1.5 * iqr
  high <- q3 + 1.5 * iqr
  n_out <- sum(x < low | x > high, na.rm = TRUE)
  c(nb_aberrantes = n_out, borne_inf = low, borne_sup = high)
}

aberrantes <- data.frame(
  variable = num_vars[num_vars %in% names(data)],
  nb_aberrantes = NA,
  borne_inf = NA,
  borne_sup = NA,
  row.names = NULL
)

for (i in seq_len(nrow(aberrantes))) {
  stats <- detect_outliers(data[[aberrantes$variable[i]]])
  aberrantes$nb_aberrantes[i] <- stats["nb_aberrantes"]
  aberrantes$borne_inf[i] <- round(stats["borne_inf"], 2)
  aberrantes$borne_sup[i] <- round(stats["borne_sup"], 2)
}

print(aberrantes)

cat("\n=== DOUBLONS ===\n")

doublons_lignes <- duplicated(data)
cat("Nombre de lignes dupliquees exactes :", sum(doublons_lignes), "\n")

if ("OBJECTID" %in% names(data)) {
  doublons_objectid <- duplicated(data$OBJECTID) | duplicated(data$OBJECTID, fromLast = TRUE)
  cat("Nombre de lignes impliquees dans des doublons sur OBJECTID :", sum(doublons_objectid, na.rm = TRUE), "\n")
}

if ("id_arbre" %in% names(data)) {
  doublons_id_arbre <- duplicated(data$id_arbre) | duplicated(data$id_arbre, fromLast = TRUE)
  cat("Nombre de lignes impliquees dans des doublons sur id_arbre :", sum(doublons_id_arbre, na.rm = TRUE), "\n")
}

if (all(c("X", "Y") %in% names(data))) {
  coords <- paste(data$X, data$Y, sep = "_")
  doublons_coords <- duplicated(coords) | duplicated(coords, fromLast = TRUE)
  cat("Nombre de lignes impliquees dans des doublons de coordonnees X/Y :", sum(doublons_coords, na.rm = TRUE), "\n")
}

cat("\n=== EXTRAITS UTILES ===\n")

cat("\nTop 10 variables avec le plus de valeurs manquantes :\n")
print(head(manquants, 10))

cat("\nVariables numeriques avec valeurs aberrantes :\n")
print(aberrantes[aberrantes$nb_aberrantes > 0, ])

cat("\nExemples de lignes dupliquees exactes :\n")
if (sum(doublons_lignes) > 0) {
  print(head(data[doublons_lignes, ]))
} else {
  cat("Aucun doublon exact detecte.\n")
}
