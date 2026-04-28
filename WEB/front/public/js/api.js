// URL de base de l'API - s'adapte au domaine actuel
const API_BASE_URL = window.location.origin;
const API_URL = `${API_BASE_URL}/WEB/api`;

/**
 * Fonction pour récupérer la liste des arbres
 */
export async function getTrees() {
  try {
    const res = await fetch(`${API_URL}/trees`);
    
    if (!res.ok) {
      throw new Error(`Erreur HTTP ${res.status}`);
    }
    
    const data = await res.json();
    
    // Retourner le tableau de données
    return data.data || [];
  } catch (error) {
    console.error('Erreur lors de la récupération des arbres:', error);
    throw error;
  }
}

/**
 * Fonction pour ajouter un nouvel arbre
 */
export async function addTree(data) {
  try {
    const res = await fetch(`${API_URL}/add_tree`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json"
      },
      body: JSON.stringify(data)
    });

    if (!res.ok) {
      // Essayer de parser la réponse d'erreur du serveur
      try {
        const errorData = await res.json();
        const errorMessage = errorData.details || errorData.error || `Erreur HTTP ${res.status}`;
        const hint = errorData.hint ? ` - ${errorData.hint}` : "";
        throw new Error(`${errorMessage}${hint}`);
      } catch (parseError) {
        throw new Error(`Erreur HTTP ${res.status}`);
      }
    }

    const response = await res.json();
    return response;
  } catch (error) {
    console.error('Erreur lors de l\'ajout d\'arbre:', error);
    throw error;
  }
}

/**
 * Fonction pour récupérer un arbre spécifique
 */
export async function getTree(id) {
  try {
    const res = await fetch(`${API_URL}/tree/${id}`);
    
    if (!res.ok) {
      throw new Error(`Erreur HTTP ${res.status}`);
    }

    const data = await res.json();
    return data.data || data;
  } catch (error) {
    console.error(`Erreur lors de la récupération de l'arbre ${id}:`, error);
    throw error;
  }
}