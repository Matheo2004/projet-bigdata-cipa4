-- ----------------------------------------------------------
-- Script MYSQL pour mcd 
-- ----------------------------------------------------------


-- ----------------------------
-- Table: stade_dev
-- ----------------------------
CREATE TABLE stade_dev (
  stadedev VARCHAR(50) NOT NULL,
  CONSTRAINT stade_dev_PK PRIMARY KEY (stadedev)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: port
-- ----------------------------
CREATE TABLE port (
  type_port VARCHAR(50) NOT NULL,
  CONSTRAINT port_PK PRIMARY KEY (type_port)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: espece
-- ----------------------------
CREATE TABLE espece (
  nomlatin VARCHAR(50) NOT NULL,
  nomfrancais VARCHAR(50) NOT NULL,
  CONSTRAINT espece_PK PRIMARY KEY (nomlatin)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: pied
-- ----------------------------
CREATE TABLE pied (
  type_pied VARCHAR(50) NOT NULL,
  CONSTRAINT pied_PK PRIMARY KEY (type_pied)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: coordonnees
-- ----------------------------
CREATE TABLE coordonnees (
  id INT NOT NULL AUTO_INCREMENT,
  longitude DECIMAL(8,5) NOT NULL,
  latitude DECIMAL(8,5) NOT NULL,
  CONSTRAINT coordonnees_PK PRIMARY KEY (id)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: etat
-- ----------------------------
CREATE TABLE etat (
  arb_etat VARCHAR(50) NOT NULL,
  CONSTRAINT etat_PK PRIMARY KEY (arb_etat)
)ENGINE=InnoDB;


-- ----------------------------
-- Table: arbre
-- ----------------------------
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
)ENGINE=InnoDB;

-- ----------------------------
-- Initialisation des données de référence
-- ----------------------------
INSERT INTO espece (nomlatin, nomfrancais) VALUES 
('Quercus robur', 'Chêne pédonculé'),
('chene', 'Chêne'),
('Acer pseudoplatanus', 'Érable sycomore'),
('Fagus sylvatica', 'Hêtre commun'),
('Pinus sylvestris', 'Pin sylvestre');

INSERT INTO etat (arb_etat) VALUES 
('Inconnu'),
('Bon'),
('Moyen'),
('Mauvais');

INSERT INTO stade_dev (stadedev) VALUES 
('Inconnu'),
('Jeune'),
('Adulte'),
('Vieux');

INSERT INTO port (type_port) VALUES 
('Inconnu'),
('Érigé'),
('Étalé'),
('Pleureur');

INSERT INTO pied (type_pied) VALUES 
('Inconnu'),
('Libre'),
('Limité'),
('Restreint');

