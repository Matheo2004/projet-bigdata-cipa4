<?php
$lignes = [
    ["id_arbre" => 5,  "autre_info" => "test"],
    ["id_arbre" => 20, "autre_info" => "test2"]
];

$cluster = 2;
$json_data = json_encode($lignes);
$json_param = str_replace('"', '\"', $json_data);

// ✅ Chemin vers le CSV dans le même dossier que script.py
$command = "C:\\Users\\CMoi\\AppData\\Local\\Programs\\Python\\Python39\\python.exe script.py \"$json_param\" $cluster 2>&1";
exec($command, $output, $resultCode);

if ($resultCode !== 0) {
    echo "<pre>Erreur Python :\n" . implode("\n", $output) . "</pre>";
} elseif (file_exists("ma_carte.html")) {
    echo "<h2>Résultats de la prédiction :</h2>";
    echo "<pre>" . print_r(json_decode($output[0], true), true) . "</pre>";

    echo "<h2>Carte des clusters :</h2>";
    echo '<iframe src="ma_carte.html" width="100%" height="600px" style="border:none;"></iframe>';
} else {
    echo "<p>La carte n'a pas été générée. Sortie Python :</p>";
    echo "<pre>" . implode("\n", $output) . "</pre>";
}
?>