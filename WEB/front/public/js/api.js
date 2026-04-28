const API_URL = `${window.location.origin}/WEB/api`;

// ── Helper ────────────────────────────────────────────────────────────────────

// Wrapper fetch qui gère les erreurs HTTP et parse automatiquement le JSON
// Toutes les fonctions API passent par ici pour éviter la répétition
async function request(endpoint, options = {}) {
  const res = await fetch(`${API_URL}${endpoint}`, {
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  if (!res.ok) {
    // On tente de lire le message d'erreur retourné par le serveur PHP
    try {
      const err = await res.json();
      throw new Error(err.details || err.error || `Erreur HTTP ${res.status}`);
    } catch {
      throw new Error(`Erreur HTTP ${res.status}`);
    }
  }

  return res.json();
}

// ── Endpoints ─────────────────────────────────────────────────────────────────

// Récupère tous les arbres de la BDD
export async function getTrees() {
  const data = await request("/trees");
  return data.data || [];
}

// Ajoute un arbre et retourne la réponse complète (avec id_tree si succès)
export async function addTree(treeData) {
  return request("/add_tree", {
    method: "POST",
    body: JSON.stringify(treeData),
  });
}

// Récupère un arbre par son id
export async function getTree(id) {
  const data = await request(`/tree/${id}`);
  return data.data || data;
}