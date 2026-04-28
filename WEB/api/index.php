<?php
ini_set('display_errors', 0);
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Récupérer la route (ex: /clusters)
$requestUri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
$route = str_replace('/WEB/api', '', $requestUri);

$csv_path = __DIR__ . '/cluster/arbres_complet_avec_clusters.csv';

// Connexion MySQL
function getDb() {
    $pdo = new PDO(
        'mysql:host=localhost;dbname=arbres_db;charset=utf8',
        'root',
        '',
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    return $pdo;
}

// Fonction utilitaire pour lire le CSV
function readCsv($csv_path) {
    if (!file_exists($csv_path)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'CSV introuvable : ' . $csv_path]);
        exit;
    }
    $handle = fopen($csv_path, 'r');
    $headers = fgetcsv($handle);
    $rows = [];
    while (($row = fgetcsv($handle)) !== false) {
        $rows[] = array_combine($headers, $row);
    }
    fclose($handle);
    return $rows;
}

// Route : GET /clusters?n=2
if ($route === '/clusters' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    $n = isset($_GET['n']) ? (int)$_GET['n'] : 2;
    $csv_path_abs = __DIR__ . '/cluster/arbres_complet_avec_clusters.csv';
    $script_path  = __DIR__ . '/cluster/convert.py';

    $python = 'C:\\Users\\mathe\\PycharmProjects\\pythonProject\\venv\\Scripts\\python.exe';
    $command = "\"$python\" \"$script_path\" \"$csv_path_abs\" $n 2>&1";
    exec($command, $output, $resultCode);

    if ($resultCode !== 0) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => implode("\n", $output)]);
        exit;
    }

    $data = json_decode($output[0], true);
    if ($data === null) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Erreur de conversion Python']);
        exit;
    }

    echo json_encode(['success' => true, 'data' => $data]);
    exit;
}

// Route : GET /trees
if ($route === '/trees' && $_SERVER['REQUEST_METHOD'] === 'GET') {
    try {
        $pdo = getDb();

        $stmt = $pdo->query("
            SELECT 
                a.id,
                a.haut_tot      AS hauteur,
                a.haut_tronc,
                a.tronc_diam,
                a.remarquable,
                a.nomlatin      AS espece,
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

        $data = $stmt->fetchAll(PDO::FETCH_ASSOC);

        echo json_encode(['success' => true, 'data' => $data]);

    } catch (PDOException $e) {
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
    exit;
}

// Route inconnue
http_response_code(404);
echo json_encode(['success' => false, 'error' => "Route '$route' introuvable"]);