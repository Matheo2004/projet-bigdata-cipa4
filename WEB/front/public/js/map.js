import { logError } from "./errorHandler.js";

const API_URL = `${window.location.origin}/WEB/api`;

// ── Leaflet ──────────────────────────────────────────────────────────────────
// On charge Leaflet dynamiquement pour ne pas alourdir la page si la carte
// n'est pas utilisée
function loadLeaflet() {
  return new Promise((resolve) => {
    if (window.L) return resolve(); // déjà chargé, on ne recharge pas

    // Feuille de style Leaflet
    const css = document.createElement("link");
    css.rel = "stylesheet";
    css.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css";
    document.head.appendChild(css);

    // Script Leaflet
    const script = document.createElement("script");
    script.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js";
    script.onload = resolve;
    document.head.appendChild(script);
  });
}

// On garde une référence à la carte pour pouvoir la détruire avant d'en créer
// une nouvelle (sinon Leaflet lève une erreur)
let mapInstance = null;

function destroyMap() {
  if (mapInstance) {
    mapInstance.remove();
    mapInstance = null;
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

// Initialise une carte Leaflet centrée sur OpenStreetMap
function createMap(containerId) {
  const map = L.map(containerId);
  L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
    attribution: '© <a href="https://www.openstreetmap.org/">OpenStreetMap</a>',
    maxZoom: 19,
  }).addTo(map);
  return map;
}

// Filtre les arbres qui ont des coordonnées GPS valides
function filterValid(trees) {
  return trees.filter(
    (t) =>
      t.latitude && t.longitude &&
      !isNaN(parseFloat(t.latitude)) &&
      !isNaN(parseFloat(t.longitude))
  );
}

// Prépare le conteneur HTML de la carte (vide + hauteur fixe)
function prepareContainer(container) {
  container.innerHTML = "";
  container.style.height = "500px";
}

// ── renderMap ─────────────────────────────────────────────────────────────────
// Affiche tous les arbres de la BDD sous forme de marqueurs 🌳
// Les coordonnées viennent directement du tableau `trees` passé en paramètre
export async function renderMap(trees) {
  const container = document.getElementById("map");
  const loader    = document.getElementById("mapLoading");

  // Aucun arbre → message d'information
  const valid = filterValid(trees);
  if (!valid.length) {
    if (container) container.innerHTML = '<div class="text-center text-muted p-5">Aucune localisation disponible</div>';
    if (loader) loader.style.display = "none";
    return;
  }

  // Chargement de Leaflet puis création de la carte
  await loadLeaflet();
  destroyMap();
  prepareContainer(container);
  mapInstance = createMap("map");

  // Icône emoji arbre pour chaque marqueur
  const treeIcon = L.divIcon({
    html: "🌳",
    className: "",
    iconSize: [20, 20],
    iconAnchor: [10, 10],
  });

  // On place chaque arbre sur la carte et on collecte ses coordonnées
  // pour que fitBounds puisse zoomer automatiquement sur l'ensemble des arbres
  const bounds = [];
  valid.forEach((t) => {
    const lat = parseFloat(t.latitude);
    const lon = parseFloat(t.longitude);
    bounds.push([lat, lon]);

    L.marker([lat, lon], { icon: treeIcon })
      .bindPopup(`
        <b>${t.espece || t.nomfrancais || "Arbre"}</b><br>
        Hauteur : ${t.hauteur || 0} m<br>
        État : ${t.arb_etat || "—"}<br>
        Stade : ${t.stadedev || "—"}
      `)
      .addTo(mapInstance);
  });

  // Zoom automatique pour englober tous les marqueurs
  mapInstance.fitBounds(bounds, { padding: [30, 30] });

  if (loader) loader.style.display = "none";
}

// ── renderClusteredMap ────────────────────────────────────────────────────────
// Récupère les arbres depuis /clusters?n=X et les affiche avec une couleur
// différente par cluster (Petit / Grand / Moyen)
export async function renderClusteredMap(n_clusters = 2) {
  const container = document.getElementById("map");
  const loader    = document.getElementById("mapLoading");
  if (!container) return;

  if (loader) loader.style.display = "block";

  try {
    // Appel API
    const res = await fetch(`${API_URL}/clusters?n=${n_clusters}`);
    if (!res.ok) throw new Error(`Erreur HTTP ${res.status}`);
    const { success, data } = await res.json();

    if (!success || !data?.length) {
      container.innerHTML = '<div class="text-center text-muted p-5">Aucun arbre à afficher</div>';
      if (loader) loader.style.display = "none";
      return;
    }

    // Création de la carte
    await loadLeaflet();
    destroyMap();
    prepareContainer(container);
    mapInstance = createMap("map");

    // Correspondance cluster → couleur et libellé
    const COLORS = { 1: "#40916c", 2: "#e63946", 3: "#f4a261" };
    const LABELS = { 1: "Petit",   2: "Grand",   3: "Moyen"   };

    // Légende affichée en bas à droite
    const legend = L.control({ position: "bottomright" });
    legend.onAdd = () => {
      const div = L.DomUtil.create("div");
      div.style.cssText = "background:white;padding:10px;border-radius:8px;box-shadow:0 2px 8px rgba(0,0,0,.2);font-size:13px;";
      const keys = n_clusters === 2 ? [1, 2] : [1, 2, 3];
      div.innerHTML = "<b>Clusters</b><br>" + keys.map((k) =>
        `<span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:${COLORS[k]};margin-right:6px;"></span>${LABELS[k]}`
      ).join("<br>");
      return div;
    };
    legend.addTo(mapInstance);

    // Placement des marqueurs + fitBounds
    const bounds = [];
    data.forEach((t) => {
      const lat   = parseFloat(t.latitude);
      const lon   = parseFloat(t.longitude);
      const color = COLORS[t.cluster] || "#40916c";
      const label = LABELS[t.cluster] || `Cluster ${t.cluster}`;
      bounds.push([lat, lon]);

      // Cercle coloré selon le cluster
      const icon = L.divIcon({
        html: `<div style="width:12px;height:12px;border-radius:50%;background:${color};border:2px solid white;box-shadow:0 1px 4px rgba(0,0,0,.4);"></div>`,
        className: "",
        iconSize: [12, 12],
        iconAnchor: [6, 6],
      });

      L.marker([lat, lon], { icon })
        .bindPopup(`
          <b>${t.espece || "Arbre"}</b><br>
          Hauteur : ${t.hauteur || 0} m<br>
          Taille : <b>${label}</b>
        `)
        .addTo(mapInstance);
    });

    mapInstance.fitBounds(bounds, { padding: [30, 30] });

  } catch (error) {
    logError(error, "Rendu de la carte avec clustering");
    container.innerHTML = '<div class="text-center text-danger p-5">Erreur lors du chargement des clusters</div>';
  } finally {
    if (loader) loader.style.display = "none";
  }
}