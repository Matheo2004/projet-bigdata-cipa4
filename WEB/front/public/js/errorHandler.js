// ── Classe d'erreur personnalisée ─────────────────────────────────────────────
// Étend Error pour ajouter un type (error/warning/info/success) et un timestamp
export class AppError extends Error {
  constructor(message, type = "error", details = null) {
    super(message);
    this.name      = "AppError";
    this.type      = type;
    this.details   = details;
    this.timestamp = new Date();
  }
}

// ── Affichage des alertes ─────────────────────────────────────────────────────

// Correspondance type → classes Bootstrap et icône
const ALERT_STYLES = {
  error:   { cls: "alert-danger",  icon: "❌" },
  warning: { cls: "alert-warning", icon: "⚠️" },
  info:    { cls: "alert-info",    icon: "ℹ️" },
  success: { cls: "alert-success", icon: "✅" },
};

// Affiche une alerte Bootstrap dans le conteneur cible
// Si aucun conteneur n'est précisé, on cherche #errorContainer, puis <main>, puis <body>
export function showError(message, type = "error", container = null) {
  const { cls, icon } = ALERT_STYLES[type] ?? ALERT_STYLES.error;

  const alert = document.createElement("div");
  alert.className = `alert ${cls} alert-dismissible fade show`;
  alert.role = "alert";
  alert.innerHTML = `
    <strong>${icon} ${type.toUpperCase()}</strong>
    <div>${message}</div>
    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
  `;

  const target = container
    ?? document.getElementById("errorContainer")
    ?? document.querySelector("main")
    ?? document.body;

  // Insère l'alerte en haut du conteneur pour qu'elle soit visible immédiatement
  target.insertBefore(alert, target.firstChild);
  alert.scrollIntoView({ behavior: "smooth", block: "center" });

  // Suppression automatique après 8 secondes
  setTimeout(() => alert.remove(), 8000);

  return alert;
}

// Raccourcis pour les types courants
export const showSuccess = (msg, el) => showError(msg, "success", el);
export const showWarning = (msg, el) => showError(msg, "warning", el);
export const showInfo    = (msg, el) => showError(msg, "info",    el);

// ── Gestion des erreurs de formulaire ────────────────────────────────────────

// Marque un champ comme invalide et affiche un message sous le champ
export function showFormError(form, fieldName, message) {
  const field = form.querySelector(`[name="${fieldName}"]`);
  if (!field) return;

  field.classList.add("is-invalid");

  // Réutilise le feedback existant ou en crée un nouveau
  const feedback = field.parentElement.querySelector(".invalid-feedback")
    ?? document.createElement("div");
  feedback.className   = "invalid-feedback d-block";
  feedback.textContent = message;
  field.parentElement.appendChild(feedback);
}

// Nettoie tous les messages d'erreur d'un formulaire
export function clearFormErrors(form) {
  form.querySelectorAll(".is-invalid").forEach(f => f.classList.remove("is-invalid"));
  form.querySelectorAll(".invalid-feedback").forEach(f => f.remove());
}

// ── Logger ────────────────────────────────────────────────────────────────────

// Logue une erreur structurée dans la console
export function logError(error, context = "") {
  console.error("🔴 ERREUR:", {
    timestamp: new Date().toISOString(),
    context,
    message: error.message || String(error),
    stack:   error.stack,
    type:    error.name || "UnknownError",
  });
}

// ── Gestion des erreurs API ───────────────────────────────────────────────────

// Codes HTTP → messages lisibles
const HTTP_MESSAGES = {
  400: "Données invalides",
  403: "Accès refusé",
  404: "Ressource non trouvée",
  500: "Erreur serveur (500) - Vérifiez les logs",
};

// Analyse une erreur et retourne un objet { message, type } prêt à afficher
export async function handleApiError(error, context = "") {
  let message;

  if (!navigator.onLine) {
    message = "Pas de connexion internet";
  } else if (error.message?.includes("Erreur HTTP")) {
    const code = error.message.match(/\d{3}/)?.[0];
    message = HTTP_MESSAGES[code] ?? `Erreur HTTP ${code}`;
  } else if (error.message === "Failed to fetch") {
    message = "Impossible de se connecter à l'API";
  } else {
    message = error.message || "Erreur inconnue";
  }

  if (context) message += ` (${context})`;

  logError(error, context);

  return { message: `❌ ${message}`, type: "error", originalError: error };
}

// ── Gestionnaires globaux ─────────────────────────────────────────────────────
// Filet de sécurité pour les erreurs non capturées par les try/catch

window.addEventListener("error", (e) => {
  console.error("Erreur non capturée:", e.error);
  showError("Une erreur non gérée s'est produite. Veuillez rafraîchir la page.");
});

window.addEventListener("unhandledrejection", (e) => {
  console.error("Promesse rejetée non gérée:", e.reason);
  showError("Une erreur asynchrone non gérée s'est produite.");
});