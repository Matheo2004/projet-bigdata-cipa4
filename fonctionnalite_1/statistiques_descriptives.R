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

num_vars <- c("haut_tot", "haut_tronc", "tronc_diam", "age_estim", "clc_nbr_diag")
cat_vars <- c("fk_arb_etat", "fk_situation", "feuillage", "remarquable", "clc_quartier")

make_numeric <- function(x) {
  x <- gsub(",", ".", x)
  suppressWarnings(as.numeric(x))
}

univarie_quanti <- function(df, vars) {
  res <- lapply(vars, function(v) {
    x <- make_numeric(df[[v]])
    x <- x[!is.na(x)]
    data.frame(
      variable = v,
      effectif = length(x),
      minimum = min(x),
      q1 = unname(quantile(x, 0.25, na.rm = TRUE)),
      mediane = median(x, na.rm = TRUE),
      q3 = unname(quantile(x, 0.75, na.rm = TRUE)),
      maximum = max(x),
      moyenne = mean(x, na.rm = TRUE)
    )
  })
  do.call(rbind, res)
}

univarie_quali <- function(df, var, top_n = 10) {
  x <- df[[var]]
  x[x == ""] <- NA
  tab <- sort(table(x, useNA = "ifany"), decreasing = TRUE)
  tab <- head(tab, top_n)
  data.frame(
    variable = var,
    modalite = names(tab),
    effectif = as.integer(tab),
    pourcentage = round(100 * as.integer(tab) / nrow(df), 2),
    row.names = NULL
  )
}

bivarie_table <- function(df, var1, var2) {
  x <- df[[var1]]
  y <- df[[var2]]
  x[x == ""] <- NA
  y[y == ""] <- NA
  addmargins(table(x, y, useNA = "no"))
}

bivarie_corr <- function(df, xvar, yvar) {
  x <- make_numeric(df[[xvar]])
  y <- make_numeric(df[[yvar]])
  cor(x, y, use = "complete.obs")
}

bivarie_moyenne <- function(df, group_var, num_var) {
  x <- make_numeric(df[[num_var]])
  g <- df[[group_var]]
  aggregate(x, by = list(g), FUN = function(z) round(mean(z, na.rm = TRUE), 2))
}

cat("STATISTIQUES UNIVARIEES - VARIABLES QUANTITATIVES\n")
print(univarie_quanti(data, num_vars))

cat("\nSTATISTIQUES UNIVARIEES - VARIABLES QUALITATIVES\n")
for (v in cat_vars) {
  cat("\nVariable :", v, "\n")
  print(univarie_quali(data, v))
}

cat("\nSTATISTIQUES BIVARIEES - ETAT x SITUATION\n")
print(bivarie_table(data, "fk_arb_etat", "fk_situation"))

cat("\nSTATISTIQUES BIVARIEES - REMARQUABLE x FEUILLAGE\n")
print(bivarie_table(data, "remarquable", "feuillage"))

cat("\nSTATISTIQUES BIVARIEES - CORRELATION haut_tot x tronc_diam\n")
print(round(bivarie_corr(data, "haut_tot", "tronc_diam"), 4))

cat("\nSTATISTIQUES BIVARIEES - HAUTEUR MOYENNE PAR SITUATION\n")
res_moy <- bivarie_moyenne(data, "fk_situation", "haut_tot")
names(res_moy) <- c("situation", "hauteur_moyenne")
print(res_moy)
