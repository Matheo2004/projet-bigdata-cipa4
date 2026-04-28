import { getTrees }       from "./api.js";
import { renderTable }    from "./table.js";
import { renderMap }      from "./map.js";
import { showError, handleApiError } from "./errorHandler.js";

// ── Helpers ──────────────────────────────────────────────────────────────────

function formatNumber(value) {
  const num = parseFloat(value);
  return isNaN(num) ? "N/A" : num.toFixed(1);
}

function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// ── Fonctions d'affichage ─────────────────────────────────────────────────────

// Affiche les 5 derniers arbres dans le tableau de la page d'accueil
function renderRecentTrees(trees) {
  const tbody = document.getElementById("recentTreesBody");
  if (!tbody) return;

  if (!trees?.length) {
    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Aucun arbre enregistré</td></tr>';
    return;
  }

  tbody.innerHTML = trees.map((t) => `
    <tr>
      <td><strong>${escapeHtml(t.espece || "N/A")}</strong></td>
      <td>${formatNumber(t.hauteur)} m</td>
      <td>${formatNumber(t.tronc_diam)} cm</td>
      <td>${t.latitude && t.longitude ? "✅" : "❌"}</td>
    </tr>
  `).join("");
}

// Met à jour les compteurs de la page d'accueil
function updateStats(trees) {
  const el = (id) => document.getElementById(id);

  if (el("statsCount"))
    el("statsCount").textContent = trees.length;

  if (el("statsLocations"))
    el("statsLocations").textContent = trees.filter(t => t.latitude && t.longitude).length;

  if (el("statsSpecies"))
    el("statsSpecies").textContent = new Set(trees.map(t => t.espece).filter(Boolean)).size;
}

// Met à jour les statistiques de la page de visualisation
function updateVisualizationStats(trees) {
  const el = (id) => document.getElementById(id);

  if (el("totalTrees"))
    el("totalTrees").textContent = trees.length;

  // Hauteur moyenne (on ignore les valeurs nulles ou à 0)
  const heights = trees.map(t => parseFloat(t.hauteur)).filter(h => h > 0);
  if (el("avgHeight") && heights.length)
    el("avgHeight").textContent = (heights.reduce((a, b) => a + b) / heights.length).toFixed(2) + " m";

  // Diamètre moyen
  const diameters = trees.map(t => parseFloat(t.tronc_diam)).filter(d => d > 0);
  if (el("avgDiameter") && diameters.length)
    el("avgDiameter").textContent = (diameters.reduce((a, b) => a + b) / diameters.length).toFixed(2) + " cm";

  // Nombre d'espèces uniques
  if (el("uniqueSpecies"))
    el("uniqueSpecies").textContent = new Set(trees.map(t => t.espece).filter(Boolean)).size;
}

// ── Init ──────────────────────────────────────────────────────────────────────
// Point d'entrée unique : on récupère les arbres une seule fois
// puis on dispatche vers les bonnes fonctions selon la page courante
async function init() {
  try {
    const trees = await getTrees();

    // Page d'accueil — tableau des arbres récents + stats globales
    if (document.getElementById("recentTreesBody")) {
      renderRecentTrees(trees.slice(-5));
      updateStats(trees);
    }

    // Page de visualisation — tableau complet + stats + carte
    if (document.getElementById("treeTable")) {
      renderTable(trees);
      updateVisualizationStats(trees);
    }

    // Carte (peut exister sur plusieurs pages)
    if (document.getElementById("map")) {
      renderMap(trees);
    }

  } catch (error) {
    const { message, type } = await handleApiError(error, "Chargement des données");
    showError(message, type);

    // Messages d'erreur dans les tableaux si présents
    const recentTreesBody = document.getElementById("recentTreesBody");
    if (recentTreesBody)
      recentTreesBody.innerHTML = '<tr><td colspan="4" class="text-center text-danger">Erreur de connexion à l\'API</td></tr>';

    const treeTable = document.getElementById("treeTable");
    if (treeTable)
      treeTable.innerHTML = '<tr><td colspan="5" class="text-center text-danger">Erreur de connexion à l\'API</td></tr>';
  }
}

// Lance init() dès que le DOM est prêt
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}