import { logError } from "./errorHandler.js";

const API_BASE_URL = window.location.origin;
const API_URL = `${API_BASE_URL}/WEB/api`;

// Fonction pour afficher la carte avec les arbres
export function renderMap(trees) {
  const mapContainer = document.getElementById("map");
  const mapLoading = document.getElementById("mapLoading");

  if (!trees || trees.length === 0) {
    if (mapContainer) mapContainer.innerHTML = '<div class="text-center text-muted p-5">Aucune donnée de localisation disponible</div>';
    if (mapLoading) mapLoading.style.display = "none";
    return;
  }

  const validTrees = trees.filter(t =>
    t.latitude && t.longitude && !isNaN(t.latitude) && !isNaN(t.longitude)
  );

  if (validTrees.length === 0) {
    if (mapContainer) mapContainer.innerHTML = '<div class="text-center text-muted p-5">Aucune localisation disponible</div>';
    if (mapLoading) mapLoading.style.display = "none";
    return;
  }

  const avgLat = validTrees.reduce((sum, t) => sum + parseFloat(t.latitude), 0) / validTrees.length;
  const avgLon = validTrees.reduce((sum, t) => sum + parseFloat(t.longitude), 0) / validTrees.length;

  const data = [{
    type: "scattermap",
    lat: validTrees.map(t => parseFloat(t.latitude)),
    lon: validTrees.map(t => parseFloat(t.longitude)),
    mode: "markers",
    marker: { size: 8, color: "#40916c", opacity: 0.8 },
    text: validTrees.map(t => `<b>${escapeHtml(t.espece || "Arbre")}</b><br>Hauteur: ${parseFloat(t.hauteur || 0).toFixed(1)}m`),
    hovertemplate: "%{text}<br>Lat: %{lat:.4f}<br>Lon: %{lon:.4f}<extra></extra>",
    name: "Arbres"
  }];

  const layout = {
    map: {
      style: "open-street-map",
      center: { lat: avgLat, lon: avgLon },
      zoom: 12
    },
    height: 500,
    margin: { l: 0, r: 0, t: 30, b: 0 },
    title: `Carte des arbres (${validTrees.length} arbres)`
  };

  const config = { responsive: true, displayModeBar: true, displaylogo: false };

  try {
    if (mapContainer) Plotly.newPlot("map", data, layout, config);
    if (mapLoading) mapLoading.style.display = "none";
  } catch (error) {
    logError(error, "Rendu de la carte");
    if (mapContainer) mapContainer.innerHTML = '<div class="text-center text-danger p-5">Erreur: ' + error.message + '</div>';
  }
}

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

export async function renderClusteredMap(n_clusters = 2) {
  const mapContainer = document.getElementById("map");
  const mapLoading = document.getElementById("mapLoading");

  if (!mapContainer) return;

  try {
    if (mapLoading) mapLoading.style.display = "block";

    const response = await fetch(`${API_URL}/clusters?n=${n_clusters}`);
    if (!response.ok) throw new Error(`Erreur HTTP ${response.status}`);

    const result = await response.json();

    if (!result.success || !result.data || result.data.length === 0) {
      mapContainer.innerHTML = '<div class="text-center text-muted p-5">Aucun arbre à afficher</div>';
      if (mapLoading) mapLoading.style.display = "none";
      return;
    }

    // Grouper par cluster
    const clusters = {};
    result.data.forEach(tree => {
      if (!clusters[tree.cluster]) clusters[tree.cluster] = [];
      clusters[tree.cluster].push(tree);
    });

    // Couleurs par cluster
    const clusterColors = { 1: "#40916c", 2: "#e63946", 3: "#f4a261" };
    const clusterLabels = { 1: "Petit", 2: "Grand", 3: "Moyen" };

    const traces = Object.keys(clusters).map(clusterId => {
      const clusterTrees = clusters[clusterId];
      return {
        type: "scattermap",
        lat: clusterTrees.map(t => t.latitude),
        lon: clusterTrees.map(t => t.longitude),
        mode: "markers",
        marker: {
          size: 8,
          color: clusterColors[clusterId] || "#40916c",
          opacity: 0.8
        },
        text: clusterTrees.map(t => `<b>${t.espece}</b><br>Hauteur: ${t.hauteur}m`),
        hovertemplate: "%{text}<extra></extra>",
        name: clusterLabels[clusterId] || `Cluster ${clusterId}`
      };
    });

    const allLats = result.data.map(t => t.latitude);
    const allLons = result.data.map(t => t.longitude);
    const avgLat = allLats.reduce((a, b) => a + b) / allLats.length;
    const avgLon = allLons.reduce((a, b) => a + b) / allLons.length;

    const layout = {
      map: {
        style: "open-street-map",
        center: { lat: avgLat, lon: avgLon },
        zoom: 12
      },
      height: 500,
      margin: { l: 0, r: 0, t: 50, b: 0 },
      title: `Clustering des arbres (${n_clusters} clusters)`,
      showlegend: true,
      legend: { x: 0.01, y: 0.99, bgcolor: "rgba(255,255,255,0.8)" }
    };

    const config = { responsive: true, displayModeBar: true, displaylogo: false };

    Plotly.newPlot("map", traces, layout, config);
    if (mapLoading) mapLoading.style.display = "none";

  } catch (error) {
    logError(error, "Rendu de la carte avec clustering");
    mapContainer.innerHTML = '<div class="text-center text-danger p-5">Erreur lors du chargement des clusters</div>';
    if (mapLoading) mapLoading.style.display = "none";
  }
}