<?php
/**
 * Script d'initialisation de la base de données
 * Accessible via: http://localhost/WEB/init_db.php
 */

header('Content-Type: application/json; charset=utf-8');

try {
    // ─── Connexion à MySQL (sans spécifier de BD) ───
    $db = new PDO(
        "mysql:host=localhost;charset=utf8",
        "root",
        ""
    );
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    echo json_encode([
        "status" => "Initialisation en cours...",
        "steps" => []
    ]);
    
    // ─── Suppression et création de la BD ───
    $db->exec("DROP DATABASE IF EXISTS arbres_db");
    $db->exec("CREATE DATABASE arbres_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci");
    $db->exec("USE arbres_db");

    echo "✅ Base de données créée\n";

    // ─── Création des tables ───
    $db->exec("
        CREATE TABLE stade_dev (
          stadedev VARCHAR(50) NOT NULL,
          CONSTRAINT stade_dev_PK PRIMARY KEY (stadedev)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table stade_dev créée\n";

    $db->exec("
        CREATE TABLE port (
          type_port VARCHAR(50) NOT NULL,
          CONSTRAINT port_PK PRIMARY KEY (type_port)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table port créée\n";

    $db->exec("
        CREATE TABLE espece (
          nomlatin VARCHAR(50) NOT NULL,
          nomfrancais VARCHAR(50) NOT NULL,
          CONSTRAINT espece_PK PRIMARY KEY (nomlatin)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table espece créée\n";

    $db->exec("
        CREATE TABLE pied (
          type_pied VARCHAR(50) NOT NULL,
          CONSTRAINT pied_PK PRIMARY KEY (type_pied)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table pied créée\n";

    $db->exec("
        CREATE TABLE coordonnees (
          id INT NOT NULL AUTO_INCREMENT,
          longitude DECIMAL(8,5) NOT NULL,
          latitude DECIMAL(8,5) NOT NULL,
          CONSTRAINT coordonnees_PK PRIMARY KEY (id)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table coordonnees créée\n";

    $db->exec("
        CREATE TABLE etat (
          arb_etat VARCHAR(50) NOT NULL,
          CONSTRAINT etat_PK PRIMARY KEY (arb_etat)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table etat créée\n";

    $db->exec("
        CREATE TABLE arbre (
          id INT NOT NULL AUTO_INCREMENT,
          haut_tot INT NOT NULL,
          haut_tronc INT NOT NULL,
          tronc_diam INT NOT NULL,
          remarquable TINYINT(1) NOT NULL,
          type_pied VARCHAR(50) NOT NULL,
          nomlatin VARCHAR(50) NOT NULL,
          arb_etat VARCHAR(50) NOT NULL,
          stadedev VARCHAR(50) NOT NULL,
          type_port VARCHAR(50) NOT NULL,
          id_coordonnees INT NOT NULL,
          CONSTRAINT arbre_PK PRIMARY KEY (id),
          CONSTRAINT arbre_type_pied_FK FOREIGN KEY (type_pied) REFERENCES pied (type_pied),
          CONSTRAINT arbre_nomlatin_FK FOREIGN KEY (nomlatin) REFERENCES espece (nomlatin),
          CONSTRAINT arbre_arb_etat_FK FOREIGN KEY (arb_etat) REFERENCES etat (arb_etat),
          CONSTRAINT arbre_stadedev_FK FOREIGN KEY (stadedev) REFERENCES stade_dev (stadedev),
          CONSTRAINT arbre_type_port_FK FOREIGN KEY (type_port) REFERENCES port (type_port),
          CONSTRAINT arbre_id_coordonnees_FK FOREIGN KEY (id_coordonnees) REFERENCES coordonnees (id)
        ) ENGINE=InnoDB;
    ");
    echo "✅ Table arbre créée\n";

    // ─── Insertion des données de référence ───
    $db->exec("
        INSERT INTO espece (nomlatin, nomfrancais) VALUES 
        ('Quercus robur', 'Chêne pédonculé'),
        ('chene', 'Chêne'),
        ('Acer pseudoplatanus', 'Érable sycomore'),
        ('Fagus sylvatica', 'Hêtre commun'),
        ('Pinus sylvestris', 'Pin sylvestre')
    ");
    echo "✅ Espèces insérées\n";

    $db->exec("
        INSERT INTO etat (arb_etat) VALUES 
        ('Inconnu'),
        ('Bon'),
        ('Moyen'),
        ('Mauvais')
    ");
    echo "✅ États insérés\n";

    $db->exec("
        INSERT INTO stade_dev (stadedev) VALUES 
        ('Inconnu'),
        ('Jeune'),
        ('Adulte'),
        ('Vieux')
    ");
    echo "✅ Stades de développement insérés\n";

    $db->exec("
        INSERT INTO port (type_port) VALUES 
        ('Inconnu'),
        ('Érigé'),
        ('Étalé'),
        ('Pleureur')
    ");
    echo "✅ Types de port insérés\n";

    $db->exec("
        INSERT INTO pied (type_pied) VALUES 
        ('Inconnu'),
        ('Libre'),
        ('Limité'),
        ('Restreint')
    ");
    echo "✅ Types de pied insérés\n";

    echo "\n✅ ✅ ✅ Base de données initialisée avec succès ! ✅ ✅ ✅\n";
    echo "\nVous pouvez maintenant essayer d'ajouter un arbre !\n";

} catch (PDOException $e) {
    http_response_code(500);
    echo "❌ ERREUR: " . $e->getMessage() . "\n";
    echo "Code: " . $e->getCode() . "\n";
}
