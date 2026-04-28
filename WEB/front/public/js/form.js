import { addTree } from "./api.js";
import { showSuccess, showError, clearFormErrors, handleApiError } from "./errorHandler.js";

const form = document.getElementById("treeForm");

// ── Soumission du formulaire ──────────────────────────────────────────────────
form.addEventListener("submit", async (e) => {
  e.preventDefault();
  clearFormErrors(form);

  // Validation HTML5 native (champs required, min, max, etc.)
  if (!form.checkValidity()) {
    form.classList.add("was-validated");
    return;
  }

  try {
    // Récupère tous les champs du formulaire en un seul objet
    const raw = Object.fromEntries(new FormData(form));

    // On cast les valeurs numériques pour éviter les erreurs côté API
    const treeData = {
      espece:    raw.espece?.trim(),
      hauteur:   parseFloat(raw.hauteur),
      diametre:  parseFloat(raw.diametre),
      latitude:  parseFloat(raw.latitude),
      longitude: parseFloat(raw.longitude),
    };

    const response = await addTree(treeData);

    // L'API retourne id_tree si l'insertion a réussi
    if (!response?.id_tree) {
      throw new Error(response?.error || response?.message || "Erreur inconnue");
    }

    showSuccess("✅ Arbre ajouté avec succès !");
    form.reset();
    form.classList.remove("was-validated");

    // Redirige vers l'accueil après 1,5 s pour laisser le temps de lire le message
    setTimeout(() => { window.location.href = "../index.html"; }, 1500);

  } catch (error) {
    const { message, type } = await handleApiError(error, "Ajout d'arbre");
    showError(message, type);
  }
});