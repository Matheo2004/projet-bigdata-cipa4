// Fonction pour afficher les arbres dans le tableau
export function renderTable(trees) {
  // Récupérer le corps du tableau
  // Note: L'ID treeTable est directement sur le tbody
  const tbody = document.querySelector("#treeTable");

  // Vérifier si l'élément existe (pour éviter les erreurs sur d'autres pages)
  if (!tbody) {
    console.warn("⚠️ Tableau #treeTable non trouvé sur cette page");
    return;
  }

  // Vider le tableau
  tbody.innerHTML = "";

  // Vérifier s'il y a des arbres à afficher
  if (!trees || trees.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">Aucun arbre trouvé</td></tr>';
    return;
  }

  // Parcourir chaque arbre et créer une ligne du tableau
  trees.forEach(tree => {
    // Créer une nouvelle ligne
    const tr = document.createElement("tr");

    // Ajouter le contenu HTML de la ligne
    tr.innerHTML = `
      <td><strong>${escapeHtml(tree.espece || "N/A")}</strong></td>
      <td>${formatNumber(tree.hauteur)} m</td>
      <td>${formatNumber(tree.diametre)} cm</td>
      <td>${formatNumber(tree.latitude)}</td>
      <td>${formatNumber(tree.longitude)}</td>
    `;

    // Ajouter la ligne au tableau
    tbody.appendChild(tr);
  });
}

// Fonction pour formater un nombre avec 2 décimales
function formatNumber(value) {
  // Si la valeur est vide, retourner N/A
  if (value === null || value === undefined || value === "") {
    return "N/A";
  }
  
  // Convertir la valeur en nombre
  const num = parseFloat(value);
  
  // Si ce n'est pas un nombre, retourner N/A
  if (isNaN(num)) return "N/A";
  
  // Retourner le nombre arrondi à 2 décimales
  return num.toFixed(2);
}

// Fonction pour sécuriser le texte (éviter les injections XSS)
function escapeHtml(text) {
  // Créer un élément div pour échapper le texte
  const div = document.createElement("div");
  // Assigner le texte en tant que contenu texte (pas HTML)
  div.textContent = text;
  // Retourner le contenu HTML (qui sera maintenant sécurisé)
  return div.innerHTML;
}