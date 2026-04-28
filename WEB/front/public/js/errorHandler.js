// Fichier pour gérer les erreurs de toute l'application

// Classe personnalisée pour les erreurs
class AppError extends Error {
  constructor(message, type = "error", details = null) {
    super(message);
    this.name = "AppError";
    this.type = type; // "error", "warning", "info"
    this.details = details;
    this.timestamp = new Date();
  }
}

// Fonction principale pour afficher les erreurs
function showError(message, type = "error", container = null) {
  // Créer un élément pour afficher l'erreur
  const alertDiv = document.createElement("div");
  
  // Déterminer les classes Bootstrap selon le type d'erreur
  let alertClass = "alert alert-danger";
  let icon = "❌";
  
  if (type === "warning") {
    alertClass = "alert alert-warning";
    icon = "⚠️";
  } else if (type === "info") {
    alertClass = "alert alert-info";
    icon = "ℹ️";
  } else if (type === "success") {
    alertClass = "alert alert-success";
    icon = "✅";
  }
  
  // Ajouter les classes et le contenu
  alertDiv.className = alertClass + " alert-dismissible fade show";
  alertDiv.role = "alert";
  alertDiv.innerHTML = `
    <strong>${icon} ${type.toUpperCase()}</strong>
    <div>${message}</div>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;
  
  // Trouver le conteneur pour afficher l'erreur
  let target = container;
  
  // Si pas de conteneur spécifié, chercher un élément par défaut
  if (!target) {
    target = document.getElementById("errorContainer") || 
             document.querySelector("main") || 
             document.body;
  }
  
  // Ajouter l'alerte au début du conteneur
  if (target.firstChild) {
    target.insertBefore(alertDiv, target.firstChild);
  } else {
    target.appendChild(alertDiv);
  }
  
  // Faire défiler vers l'erreur
  alertDiv.scrollIntoView({ behavior: "smooth", block: "center" });
  
  // Supprimer automatiquement après 8 secondes
  setTimeout(() => {
    alertDiv.remove();
  }, 8000);
  
  return alertDiv;
}

// Fonction pour afficher les erreurs dans un formulaire
function showFormError(formElement, fieldName, message) {
  // Récupérer le champ du formulaire
  const field = formElement.querySelector(`[name="${fieldName}"]`);
  
  if (!field) return;
  
  // Ajouter la classe d'erreur Bootstrap
  field.classList.add("is-invalid");
  
  // Chercher ou créer un élément de feedback
  let feedback = field.parentElement.querySelector(".invalid-feedback");
  
  if (!feedback) {
    feedback = document.createElement("div");
    feedback.className = "invalid-feedback d-block";
    field.parentElement.appendChild(feedback);
  }
  
  // Afficher le message d'erreur
  feedback.textContent = message;
}

// Fonction pour effacer les erreurs d'un formulaire
function clearFormErrors(formElement) {
  // Supprimer la classe d'erreur de tous les champs
  const fields = formElement.querySelectorAll(".is-invalid");
  fields.forEach(field => {
    field.classList.remove("is-invalid");
  });
  
  // Supprimer tous les messages de feedback
  const feedbacks = formElement.querySelectorAll(".invalid-feedback");
  feedbacks.forEach(feedback => {
    feedback.remove();
  });
}

// Fonction pour gérer les erreurs API
async function handleApiError(error, context = "") {
  // Créer un message d'erreur détaillé
  let message = "Une erreur s'est produite";
  let type = "error";
  let details = "";
  
  // Vérifier si c'est une erreur réseau
  if (!navigator.onLine) {
    message = "❌ Pas de connexion internet";
    type = "error";
  } 
  // Erreur personnalisée de l'API (Error lancée avec Erreur HTTP)
  else if (error.message && error.message.includes("Erreur HTTP")) {
    const statusCode = error.message.match(/\d{3}/)?.[0];
    
    if (statusCode === "500") {
      message = "❌ Erreur serveur (500) - Vérifiez les logs du serveur";
    } else if (statusCode === "404") {
      message = "❌ Ressource non trouvée";
    } else if (statusCode === "400") {
      message = "❌ Données invalides";
    } else if (statusCode === "403") {
      message = "❌ Accès refusé";
    } else {
      message = `❌ Erreur HTTP ${statusCode}`;
    }
  } 
  // Erreur de réseau
  else if (error.message === "Failed to fetch") {
    message = "❌ Impossible de se connecter à l'API";
  }
  // Autres erreurs
  else {
    message = `❌ ${error.message || "Erreur inconnue"}`;
  }
  
  // Ajouter le contexte s'il y en a un
  if (context) {
    message += ` (${context})`;
  }
  
  // Logger l'erreur
  logError(error, context);
  
  return {
    message: message,
    type: type,
    details: details,
    originalError: error
  };
}

// Fonction pour logger les erreurs
function logError(error, context = "") {
  // Créer un message de log structuré
  const logMessage = {
    timestamp: new Date().toISOString(),
    context: context,
    message: error.message || String(error),
    stack: error.stack,
    type: error.name || "UnknownError"
  };
  
  // Afficher dans la console
  console.error("🔴 ERREUR:", logMessage);
  
  // Optionnel: envoyer les erreurs vers un serveur de logging
  // sendErrorToServer(logMessage);
}

// Fonction pour afficher un message de succès
function showSuccess(message, container = null) {
  showError(message, "success", container);
}

// Fonction pour afficher un message d'avertissement
function showWarning(message, container = null) {
  showError(message, "warning", container);
}

// Fonction pour afficher un message d'info
function showInfo(message, container = null) {
  showError(message, "info", container);
}

// Gestionnaire d'erreur global
window.addEventListener("error", (event) => {
  console.error("Erreur non capturée:", event.error);
  showError("Une erreur non gérée s'est produite. Veuillez rafraîchir la page.");
});

// Gestionnaire pour les promesses rejetées
window.addEventListener("unhandledrejection", (event) => {
  console.error("Promesse rejetée non gérée:", event.reason);
  showError("Une erreur asynchrone non gérée s'est produite.");
});

// Exporter les fonctions
export {
  AppError,
  showError,
  showFormError,
  clearFormErrors,
  handleApiError,
  logError,
  showSuccess,
  showWarning,
  showInfo
};
