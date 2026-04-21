# Charger les données (chemin simple)
getwd()
data <- read.csv("C:/Users/mathe/Documents/projet-bigdata-cipa4/data/Data_Arbre_Input.csv", stringsAsFactors = FALSE)

# Variables
num_vars <- c("haut_tot", "haut_tronc", "tronc_diam", "age_estim", "clc_nbr_diag")
cat_vars <- c("fk_arb_etat", "fk_situation", "feuillage", "remarquable", "clc_quartier")

# Fonction simple pour convertir en numérique
to_numeric <- function(x) {
  x <- gsub(",", ".", x)
  as.numeric(x)
}

### -----------------------------
### STATISTIQUES UNIVARIEES
### -----------------------------

cat("=== VARIABLES QUANTITATIVES ===\n")

for (v in num_vars) {
  x <- to_numeric(data[[v]])
  x <- x[!is.na(x)]
  
  cat("\nVariable :", v, "\n")
  cat("Effectif :", length(x), "\n")
  cat("Min :", min(x), "\n")
  cat("Q1 :", quantile(x, 0.25), "\n")
  cat("Mediane :", median(x), "\n")
  cat("Q3 :", quantile(x, 0.75), "\n")
  cat("Max :", max(x), "\n")
  cat("Moyenne :", mean(x), "\n")
}

cat("\n=== VARIABLES QUALITATIVES ===\n")

for (v in cat_vars) {
  cat("\nVariable :", v, "\n")
  
  x <- data[[v]]
  x[x == ""] <- NA
  
  tab <- sort(table(x), decreasing = TRUE)
  print(tab)
}

### -----------------------------
### STATISTIQUES BIVARIEES
### -----------------------------

cat("\n=== TABLEAU CROISE ETAT x SITUATION ===\n")
print(table(data$fk_arb_etat, data$fk_situation))

cat("\n=== TABLEAU CROISE REMARQUABLE x FEUILLAGE ===\n")
print(table(data$remarquable, data$feuillage))

cat("\n=== CORRELATION haut_tot x tronc_diam ===\n")
x <- to_numeric(data$haut_tot)
y <- to_numeric(data$tronc_diam)
print(cor(x, y, use = "complete.obs"))

cat("\n=== HAUTEUR MOYENNE PAR SITUATION ===\n")
x <- to_numeric(data$haut_tot)
res <- aggregate(x, by = list(data$fk_situation), mean, na.rm = TRUE)
names(res) <- c("situation", "hauteur_moyenne")
print(res)