import { getTrees } from "./api.js";
import { renderTable } from "./table.js";
import { renderMap } from "./map.js";
import { showError, handleApiError } from "./errorHandler.js";

// Fonction principale qui initialise l'application
async function init() {
  try {
    // Récupérer les données des arbres depuis l'API
    const trees = await getTrees();

    // Récupérer l'élément du tableau des arbres récents (sur la page d'accueil)
    const recentTreesBody = document.getElementById("recentTreesBody");
    
    // Si nous sommes sur la page d'accueil et qu'il y a des arbres
    if (recentTreesBody && trees && trees.length > 0) {
      // Afficher les 5 derniers arbres ajoutés
      const recentTrees = trees.slice(-5);
      renderRecentTrees(recentTrees);
      
      // Mettre à jour les statistiques de la page d'accueil
      updateStats(trees);
    }

    // Récupérer l'élément du tableau principal (sur la page de visualisation)
    const treeTable = document.getElementById("treeTable");
    
    // Si nous sommes sur la page de visualisation
    if (treeTable) {
      // Afficher tous les arbres dans le tableau
      renderTable(trees);
      
      // Mettre à jour les statistiques de la page de visualisation
      updateVisualizationStats(trees);
    }

    // Récupérer l'élément de la carte (sur la page de visualisation)
    const map = document.getElementById("map");
    
    // Si nous avons une carte à afficher
    if (map) {
      renderMap(trees);
    }

  } catch (error) {
    // En cas d'erreur lors du chargement des données
    const errorInfo = await handleApiError(error, "Chargement des données");
    
    // Afficher le message d'erreur
    showError(errorInfo.message, errorInfo.type);
    
    // Afficher un message d'erreur sur la page d'accueil
    const recentTreesBody = document.getElementById("recentTreesBody");
    if (recentTreesBody) {
      recentTreesBody.innerHTML = '<tr><td colspan="4" class="text-center text-danger">Erreur de connexion à l\'API</td></tr>';
    }

    // Afficher un message d'erreur sur la page de visualisation
    const treeTable = document.getElementById("treeTable");
    if (treeTable) {
      treeTable.innerHTML = '<tr><td colspan="5" class="text-center text-danger">Erreur de connexion à l\'API</td></tr>';
    }
  }
}

// Fonction pour afficher les arbres récents sur la page d'accueil
function renderRecentTrees(trees) {
  // Récupérer le corps du tableau
  const tbody = document.getElementById("recentTreesBody");
  
  // Vérifier si l'élément existe (pour éviter les erreurs sur d'autres pages)
  if (!tbody) {
    console.warn("⚠️ Élément 'recentTreesBody' non trouvé sur cette page");
    return;
  }

  // Vider le tableau
  tbody.innerHTML = "";

  // Vérifier s'il y a des arbres à afficher
  if (!trees || trees.length === 0) {
    tbody.innerHTML = '<tr><td colspan="4" class="text-center text-muted">Aucun arbre enregistré</td></tr>';
    return;
  }

  // Parcourir chaque arbre et créer une ligne du tableau
  trees.forEach(tree => {
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td><strong>${escapeHtml(tree.espece || "N/A")}</strong></td>
      <td>${formatNumber(tree.hauteur)} m</td>
      <td>${formatNumber(tree.diametre)} cm</td>
      <td>${tree.latitude && tree.longitude ? "✅" : "❌"}</td>
    `;
    tbody.appendChild(tr);
  });
}

// Fonction pour mettre à jour les statistiques de la page d'accueil
function updateStats(trees) {
  // Vérifier s'il y a des arbres
  if (!trees || trees.length === 0) return;

  // Récupérer les éléments HTML pour afficher les stats
  const statsCount = document.getElementById("statsCount");
  const statsLocations = document.getElementById("statsLocations");
  const statsSpecies = document.getElementById("statsSpecies");

  // Afficher le nombre total d'arbres
  if (statsCount) statsCount.textContent = trees.length;

  // Compter les arbres avec localisation
  const locatedTrees = trees.filter(t => t.latitude && t.longitude).length;
  if (statsLocations) statsLocations.textContent = locatedTrees;

  // Compter le nombre d'espèces uniques
  const uniqueSpecies = new Set(trees.map(t => t.espece).filter(Boolean)).size;
  if (statsSpecies) statsSpecies.textContent = uniqueSpecies;
}

// Fonction pour mettre à jour les statistiques de la page de visualisation
function updateVisualizationStats(trees) {
  // Vérifier s'il y a des arbres
  if (!trees || trees.length === 0) return;

  // Récupérer les éléments HTML pour afficher les stats
  const totalTrees = document.getElementById("totalTrees");
  const avgHeight = document.getElementById("avgHeight");
  const avgDiameter = document.getElementById("avgDiameter");
  const uniqueSpecies = document.getElementById("uniqueSpecies");

  // Afficher le nombre total d'arbres
  if (totalTrees) totalTrees.textContent = trees.length;

  // Calculer la hauteur moyenne
  const heights = trees
    .map(t => parseFloat(t.hauteur))
    .filter(h => !isNaN(h) && h > 0);
  if (avgHeight && heights.length > 0) {
    const avg = (heights.reduce((a, b) => a + b, 0) / heights.length).toFixed(2);
    avgHeight.textContent = avg + " m";
  }

  // Calculer le diamètre moyen
  const diameters = trees
    .map(t => parseFloat(t.diametre))
    .filter(d => !isNaN(d) && d > 0);
  if (avgDiameter && diameters.length > 0) {
    const avg = (diameters.reduce((a, b) => a + b, 0) / diameters.length).toFixed(2);
    avgDiameter.textContent = avg + " cm";
  }

  // Compter le nombre d'espèces uniques
  const species = new Set(trees.map(t => t.espece).filter(Boolean)).size;
  if (uniqueSpecies) uniqueSpecies.textContent = species;
}

// Fonction pour formater un nombre avec 1 décimale
function formatNumber(value) {
  // Si la valeur est vide, retourner N/A
  if (value === null || value === undefined || value === "") {
    return "N/A";
  }
  
  // Convertir en nombre
  const num = parseFloat(value);
  
  // Si ce n'est pas un nombre valide, retourner N/A
  if (isNaN(num)) return "N/A";
  
  // Retourner le nombre arrondi à 1 décimale
  return num.toFixed(1);
}

// Fonction pour sécuriser le texte (éviter les injections XSS)
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// Lancer l'initialisation au chargement de la page
// S'assurer que le DOM est complètement chargé avant d'exécuter
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', init);
} else {
  init();
}