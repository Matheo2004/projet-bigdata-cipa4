<!DOCTYPE html>
<html lang="fr">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Clusters - Gestion du Patrimoine Arboré</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="../css/style.css">
  <script src="https://cdn.plot.ly/plotly-2.26.0.min.js"></script>
</head>
<body>

<header class="navbar navbar-expand-lg navbar-dark bg-gradient">
  <div class="container-fluid">
    <h1 class="navbar-brand mb-0"><i class="bi bi-tree-fill"></i> 🌳 Gestion du Patrimoine Arboré</h1>
    <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav">
      <span class="navbar-toggler-icon"></span>
    </button>
    <nav class="collapse navbar-collapse" id="navbarNav">
      <ul class="navbar-nav ms-auto">
        <li class="nav-item"><a class="nav-link" href="../index.html">Accueil</a></li>
        <li class="nav-item"><a class="nav-link" href="add.html">Ajouter un arbre</a></li>
        <li class="nav-item"><a class="nav-link" href="visualisation.html">Visualisation</a></li>
        <li class="nav-item"><a class="nav-link active" href="cluster.php">Clusters</a></li>
      </ul>
    </nav>
  </div>
</header>

<main class="main-content">
  <div class="container-fluid my-5">
    <h2 class="mb-4">📊 Visualisation des Clusters</h2>

    <?php 
      try {
        $db = new PDO('mysql:host=localhost;dbname=arbres_db;charset=utf8', 'root');
      } catch (Exception $e) {
        die('Erreur : ' . $e->getMessage());
      }

      $query = $db->query("SELECT c.latitude,c.longitude,a.haut_tot FROM arbre a JOIN coordonnees c ON a.id_coordonnees=c.id"); // Adapte le nom de ta table
      $trees = $query->fetchAll(PDO::FETCH_ASSOC);
      $json_data = json_encode($trees);
      // Encode to Base64 so the shell doesn't mess with the quotes
      $data = base64_encode($json_data);
      
      $command = "C:\Users\CMoi\AppData\Local\Programs\Python\Python39\python.exe ../../../script.py " . escapeshellarg($data) . " 2>&1";
      exec($command, $output, $resultCode);
      if ($resultCode !== 0) {
          echo "<div style='background: #fee; border: 1px solid red; padding: 10px;'>";
          echo "<strong>Erreur Python (Code $resultCode) :</strong><pre>";
          echo implode("\n", $output); // Affiche tout le Traceback Python
          echo "</pre></div>";
      } else {
          echo '<iframe src="ma_carte.html?v=' . time() . '" width="100%" height="600px" style="border:none;"></iframe>';
      }
    ?>

    <div class="mt-4">
      <a href="../index.html" class="btn btn-outline-secondary">Retour à l'accueil</a>
    </div>
  </div>
</main>

<footer class="bg-light border-top mt-5">
  <div class="container py-4">
    <div class="row">
      <div class="col-md-6">
        <h6>À propos</h6>
        <p class="text-muted small">Projet de gestion du patrimoine arboré développé par le trinôme 3 de l'ISEN.</p>
      </div>
      <div class="col-md-6 text-md-end">
        <p class="text-muted small">© 2026 - Tous droits réservés</p>
      </div>
    </div>
  </div>
</footer>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
<script type="module" src="../js/main.js"></script>

</body>
</html>