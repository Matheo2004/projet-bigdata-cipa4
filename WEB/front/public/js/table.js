// ── Helpers ──────────────────────────────────────────────────────────────────

// Formate un nombre avec 2 décimales, retourne "N/A" si la valeur est invalide
function formatNumber(value) {
  const num = parseFloat(value);
  return isNaN(num) ? "N/A" : num.toFixed(2);
}

// Échappe le HTML pour éviter les injections XSS
function escapeHtml(text) {
  const div = document.createElement("div");
  div.textContent = text;
  return div.innerHTML;
}

// ── renderTable ───────────────────────────────────────────────────────────────
// Affiche la liste des arbres dans le tableau #treeTable
export function renderTable(trees) {
  const tbody = document.querySelector("#treeTable");

  // La fonction peut être appelée sur des pages sans tableau, on sort discrètement
  if (!tbody) return;

  // Cas où il n'y a aucun arbre à afficher
  if (!trees?.length) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Aucun arbre trouvé</td></tr>';
    return;
  }

  // On construit tout le HTML d'un coup avec join() pour éviter
  // les manipulations DOM répétées (plus performant que appendChild en boucle)
  tbody.innerHTML = trees.map((tree) => `
    <tr>
      <td><strong>${escapeHtml(tree.espece || "N/A")}</strong></td>
      <td>${formatNumber(tree.hauteur)} m</td>
      <td>${formatNumber(tree.tronc_diam)} cm</td>
      <td>${formatNumber(tree.latitude)}</td>
      <td>${formatNumber(tree.longitude)}</td>
    </tr>
  `).join("");
}