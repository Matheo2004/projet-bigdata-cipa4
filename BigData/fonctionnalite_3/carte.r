# =============================================================================
#   install.packages(c("sf", "ggplot2", "dplyr", "maptiles", "tidyterra"))
# =============================================================================

library(sf)
library(ggplot2)
library(dplyr)
library(maptiles)
library(tidyterra)

# --- 2. Chargement des données -----------------------------------------------

df <- read.csv("Data_Arbre_Clean.csv", stringsAsFactors = FALSE)
df_valid <- df %>% filter(!is.na(X) & !is.na(Y))

cat("Lignes valides :", nrow(df_valid), "\n")

# --- 3. Création de l'objet spatial ------------------------------------------
# Les coordonnées X,Y sont en RGF93 / CC49 (EPSG:3949) - projection française

arbres_sf    <- st_as_sf(df_valid, coords = c("X", "Y"), crs = 3949)
arbres_wgs84 <- st_transform(arbres_sf, crs = 4326)

cat("Bounding box (doit être autour de Saint-Quentin, lat~49.8, lon~3.3) :\n")
print(st_bbox(arbres_wgs84))

# --- 4. Téléchargement du fond de carte OSM ----------------------------------

tuiles <- get_tiles(arbres_wgs84, provider = "OpenStreetMap", zoom = 13, crop = TRUE)

# --- 5. Carte 1 : Tous les arbres --------------------------------------------

cat("[Carte 1] Tous les arbres...\n")

p1 <- ggplot() +
  geom_spatraster_rgb(data = tuiles) +
  geom_sf(data = arbres_wgs84,
          color = "#2e7d32", fill = "#4caf50",
          shape = 21, size = 1.2, alpha = 0.7, stroke = 0.3) +
  labs(
    title   = "Répartition des arbres de Saint-Quentin",
    caption = "Source : Patrimoine Arboré Saint-Quentin | Fond : OpenStreetMap"
  ) +
  theme_void(base_size = 12) +
  theme(plot.title   = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.caption = element_text(size = 8, hjust = 1))

ggsave("carte1_tous_les_arbres.png", plot = p1,
       width = 12, height = 10, dpi = 150, bg = "white")
cat("[OK] carte1_tous_les_arbres.png\n")

# --- 6. Carte 2 : Arbres remarquables ----------------------------------------

cat("[Carte 2] Arbres remarquables...\n")

arbres_wgs84 <- arbres_wgs84 %>%
  mutate(type_arbre = ifelse(remarquable == "Oui", "Remarquable", "Ordinaire"))

p2 <- ggplot() +
  geom_spatraster_rgb(data = tuiles) +
  geom_sf(data = arbres_wgs84 %>% filter(type_arbre == "Ordinaire"),
          color = "#388e3c", size = 0.8, alpha = 0.5) +
  geom_sf(data = arbres_wgs84 %>% filter(type_arbre == "Remarquable"),
          color = "#e65100", fill = "#ff9800",
          shape = 23, size = 3, alpha = 0.95, stroke = 0.8) +
  labs(
    title    = "Localisation des arbres remarquables de Saint-Quentin",
    subtitle = "Losanges orange = remarquables  |  Points verts = ordinaires",
    caption  = "Source : Patrimoine Arboré Saint-Quentin | Fond : OpenStreetMap"
  ) +
  theme_void(base_size = 12) +
  theme(plot.title    = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.subtitle = element_text(size = 10, hjust = 0.5),
        plot.caption  = element_text(size = 8, hjust = 1))

ggsave("carte2_arbres_remarquables.png", plot = p2,
       width = 12, height = 10, dpi = 150, bg = "white")
cat("[OK] carte2_arbres_remarquables.png\n")

# --- 7. Carte 3 : Densité par quartier ---------------------------------------

cat("[Carte 3] Densité par quartier...\n")

arbres_par_quartier <- df_valid %>%
  filter(!is.na(clc_quartier) & clc_quartier != "" & clc_quartier != "NA") %>%
  group_by(clc_quartier) %>%
  summarise(
    nb_arbres = n(),
    X_centre  = mean(X, na.rm = TRUE),
    Y_centre  = mean(Y, na.rm = TRUE),
    .groups   = "drop"
  )

quartiers_sf    <- st_as_sf(arbres_par_quartier,
                            coords = c("X_centre", "Y_centre"), crs = 3949)
quartiers_wgs84 <- st_transform(quartiers_sf, crs = 4326)

p3 <- ggplot() +
  geom_spatraster_rgb(data = tuiles) +
  geom_sf(data = quartiers_wgs84,
          aes(size = nb_arbres, fill = nb_arbres),
          shape = 21, alpha = 0.75, color = "white", stroke = 0.8) +
  scale_size_continuous(range = c(4, 18), name = "Nb arbres") +
  scale_fill_viridis_c(option = "YlOrRd", direction = -1, name = "Nb arbres") +
  geom_sf_label(data = quartiers_wgs84,
                aes(label = paste0(clc_quartier, "\n(", nb_arbres, ")")),
                size = 2.5, nudge_y = 0.003,
                label.size = 0.2, fill = "white", alpha = 0.8) +
  labs(
    title   = "Nombre d'arbres par quartier à Saint-Quentin",
    caption = "Source : Patrimoine Arboré Saint-Quentin | Fond : OpenStreetMap"
  ) +
  theme_void(base_size = 12) +
  theme(plot.title      = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.caption    = element_text(size = 8, hjust = 1),
        legend.position = "right")

ggsave("carte3_densite_quartier.png", plot = p3,
       width = 14, height = 10, dpi = 150, bg = "white")
cat("[OK] carte3_densite_quartier.png\n")

# --- 8. Carte 4 : État des arbres --------------------------------------------

cat("[Carte 4] État des arbres...\n")

arbres_etat <- arbres_wgs84 %>%
  filter(!is.na(fk_arb_etat) & fk_arb_etat != "")

etats         <- unique(arbres_etat$fk_arb_etat)
palette_etats <- RColorBrewer::brewer.pal(min(length(etats), 8), "Set1")

p4 <- ggplot() +
  geom_spatraster_rgb(data = tuiles) +
  geom_sf(data = arbres_etat, aes(color = fk_arb_etat),
          size = 0.9, alpha = 0.75) +
  scale_color_manual(values = palette_etats[seq_along(etats)],
                     name = "État de l'arbre") +
  labs(
    title   = "État des arbres de Saint-Quentin",
    caption = "Source : Patrimoine Arboré Saint-Quentin | Fond : OpenStreetMap"
  ) +
  theme_void(base_size = 12) +
  theme(plot.title      = element_text(face = "bold", size = 14, hjust = 0.5),
        plot.caption    = element_text(size = 8, hjust = 1),
        legend.position = "right")

ggsave("carte4_etat_arbres.png", plot = p4,
       width = 12, height = 10, dpi = 150, bg = "white")
cat("[OK] carte4_etat_arbres.png\n")