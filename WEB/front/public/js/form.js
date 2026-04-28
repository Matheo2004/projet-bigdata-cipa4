import { addTree } from "./api.js";
import { showSuccess, showError, clearFormErrors, handleApiError } from "./errorHandler.js";

const form = document.getElementById("treeForm");

form.addEventListener("submit", async (e) => {
  e.preventDefault();

  clearFormErrors(form);

  if (!form.checkValidity()) {
    e.stopPropagation();
    form.classList.add("was-validated");
    return;
  }

  try {
    const data = Object.fromEntries(new FormData(form));

    const treeData = {
      espece: data.espece?.trim(),
      hauteur: parseFloat(data.hauteur),
      diametre: parseFloat(data.diametre),
      latitude: parseFloat(data.latitude),
      longitude: parseFloat(data.longitude)
    };

    const response = await addTree(treeData);

    console.log("API RESPONSE:", response);

    // ✔️ succès si id_tree existe
    if (response && response.id_tree) {
      showSuccess("✅ Arbre ajouté avec succès !");

      form.reset();
      form.classList.remove("was-validated");

      setTimeout(() => {
        window.location.href = "../index.html";
      }, 1500);

    } else {
      throw new Error(response?.error || response?.message || "Erreur inconnue");
    }

  } catch (error) {
    const errorInfo = await handleApiError(error, "Ajout d'arbre");
    showError(errorInfo.message, errorInfo.type);
  }
});