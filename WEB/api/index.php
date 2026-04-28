<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// ── Config ────────────────────────────────────────────────────────────────────

$PYTHON  = 'C:\\Users\\mathe\\PycharmProjects\\pythonProject\\venv\\Scripts\\python.exe';
$CSV     = __DIR__ . '/cluster/arbres_complet_avec_clusters.csv';
$CONVERT = __DIR__ . '/cluster/convert.py';

// Extrait la route courante (ex: "/trees", "/clusters")
$route = str_replace('/WEB/api', '', parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH));

// ── Helpers ───────────────────────────────────────────────────────────────────

// Retourne une connexion PDO MySQL (appelée uniquement si nécessaire)
function getDb(): PDO {
    return new PDO(
        'mysql:host=localhost;dbname=arbres_db;charset=utf8',
        'root', '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
}

// Envoie une réponse JSON et stoppe le script
function respond(array $payload, int $code = 200): void {
    http_response_code($code);
    echo json_encode($payload);
    exit;
}

// ── Route : GET /trees ────────────────────────────────────────────────────────
// Retourne tous les arbres de la BDD avec leurs coordonnées GPS et leur espèce
if ($route === '/trees' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $stmt = getDb()->query("
            SELECT
                a.id,
                a.haut_tot   AS hauteur,
                a.haut_tronc,
                a.tronc_diam,
                a.remarquable,
                a.nomlatin   AS espece,
                e.nomfrancais,
                a.arb_etat,
                a.stadedev,
                a.type_port,
                a.type_pied,
                c.latitude,
                c.longitude
            FROM arbre a
            JOIN coordonnees c ON a.id_coordonnees = c.id
            JOIN espece e      ON a.nomlatin = e.nomlatin
        ");

        respond(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);

    } catch (PDOException $e) {
        respond(['success' => false, 'error' => $e->getMessage()], 500);
    }
}

// ── Route : POST /add_tree ────────────────────────────────────────────────────
// Insère un nouvel arbre + ses coordonnées dans la BDD
if ($route === '/add_tree' && $_SERVER['REQUEST_METHOD'] === 'POST') {
    try {
        $body = json_decode(file_get_contents('php://input'), true);

        // Validation — tous les champs sont obligatoires
        foreach (['espece', 'hauteur', 'diametre', 'latitude', 'longitude'] as $field) {
            if (empty($body[$field]) && $body[$field] !== 0) {
                respond(['success' => false, 'error' => "Champ manquant : $field"], 400);
            }
        }

        $pdo = getDb();

        // 1. Coordonnées GPS
        $stmt = $pdo->prepare("INSERT INTO coordonnees (latitude, longitude) VALUES (:lat, :lon)");
        $stmt->execute([':lat' => (float)$body['latitude'], ':lon' => (float)$body['longitude']]);
        $id_coord = $pdo->lastInsertId();

        // 2. Espèce — on l'insère si elle n'existe pas encore (évite l'erreur FK)
        $pdo->prepare("INSERT INTO espece (nomlatin, nomfrancais) VALUES (:n, :n) ON DUPLICATE KEY UPDATE nomlatin = nomlatin")
            ->execute([':n' => trim($body['espece'])]);

        // 3. Arbre — les champs non saisis dans le formulaire prennent la valeur "Inconnu"
        $stmt = $pdo->prepare("
            INSERT INTO arbre (haut_tot, haut_tronc, tronc_diam, remarquable, type_pied, nomlatin, arb_etat, stadedev, type_port, id_coordonnees)
            VALUES (:hauteur, 0, :diam, 0, 'Inconnu', :espece, 'Inconnu', 'Inconnu', 'Inconnu', :id_coord)
        ");
        $stmt->execute([
            ':hauteur'   => (float)$body['hauteur'],
            ':diam'      => (float)$body['diametre'],
            ':espece'    => trim($body['espece']),
            ':id_coord'  => $id_coord,
        ]);

        respond(['success' => true, 'id_tree' => $pdo->lastInsertId()]);

    } catch (PDOException $e) {
        respond(['success' => false, 'error' => $e->getMessage()], 500);
    }
}

// ── Route : GET /clusters?n=2 ─────────────────────────────────────────────────
// Appelle le script Python qui lit le CSV, convertit les coordonnées X/Y → GPS
// et retourne les arbres groupés par cluster
if ($route === '/clusters' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    $n = isset($_GET['n']) ? (int)$_GET['n'] : 2;

    exec("\"$PYTHON\" \"$CONVERT\" \"$CSV\" $n 2>&1", $output, $code);

    if ($code !== 0) {
        respond(['success' => false, 'error' => implode("\n", $output)], 500);
    }

    $data = json_decode($output[0], true);
    if ($data === null) {
        respond(['success' => false, 'error' => 'Réponse Python invalide'], 500);
    }

    respond(['success' => true, 'data' => $data]);
}

// ── Route inconnue ────────────────────────────────────────────────────────────
respond(['success' => false, 'error' => "Route '$route' introuvable"], 404);