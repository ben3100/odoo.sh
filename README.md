
# Script d'installation d'Odoo sur Ubuntu 22.04 LTS

## Auteur :
- [Ben Belaouedj](https://fr.linkedin.com/in/ben-belaouedj)

## Description :

Ce script permet d'installer Odoo sur un serveur Ubuntu 22.04 LTS. Il peut également être utilisé pour d'autres versions d'Ubuntu. Le script prend en charge l'installation de plusieurs instances d'Odoo sur un seul serveur Ubuntu grâce à l'utilisation de différents ports `xmlrpc`.

## Prérequis :

- Un serveur Ubuntu 22.04 LTS
- Un accès root ou sudo

## Fonctionnalités :

- **Mise à jour du serveur**
- **Configuration du fuseau horaire**
- **Installation de PostgreSQL**
- **Installation des dépendances Python**
- **Installation de Node.js et npm**
- **Installation de wkhtmltopdf**
- **Création d'un utilisateur système pour Odoo**
- **Installation d'Odoo depuis la source**
- **Option d'installation de la version entreprise d'Odoo** (versions 14 ou 15)
- **Configuration de Nginx comme proxy inverse**
- **Configuration de SSL avec Certbot**

## Utilisation :

### Étape 1: Télécharger le script

Clonez le dépôt contenant le script :

\`\`\`sh
git clone https://github.com/ben3100/odoo.sh.git
cd odoo.sh
\`\`\`

### Étape 2: Rendre le script exécutable

Rendez le script exécutable :

\`\`\`sh
sudo chmod +x install.sh
\`\`\`

### Étape 3: Exécuter le script

Lancez le script pour installer Odoo :

\`\`\`sh
sudo ./install.sh
\`\`\`

### Étape 4: Suivre les instructions

Le script vous demandera de fournir plusieurs informations :

- **Nom d'utilisateur système pour Odoo (par exemple, odoo)**
- **Mot de passe superadmin pour Odoo (par exemple, admin)**
- **Nom du site web pour la configuration Nginx (par exemple, example.com)**
- **Version d'Odoo à installer (par exemple, 16.0 ou 17.0)**
- **Si vous souhaitez installer la version entreprise d'Odoo (True/False)**
- **Si vous choisissez d'installer la version entreprise, le script vous demandera de spécifier la version entreprise (14 ou 15).**

### Notes

- Si vous choisissez de générer un mot de passe admin aléatoire, le script le fera automatiquement.
- Le script configure Nginx pour agir comme un proxy inverse et installe également un certificat SSL via Certbot si l'option est activée.

## Vérification

Pour vérifier que le service Odoo est en cours d'exécution, utilisez la commande suivante :

\`\`\`sh
sudo systemctl status odoo
\`\`\`

## Accès à Odoo

Vous pouvez accéder à votre instance Odoo via l'adresse IP de votre serveur ou le nom de domaine que vous avez configuré :

\`\`\`
http://example.com
\`\`\`

## Informations supplémentaires

- **Port par défaut d'Odoo** : 8069
- **Fichier de configuration d'Odoo** : \`/etc/odoo-server.conf\`
- **Répertoire des addons personnalisés** : \`/opt/odoo/custom/addons\`

## Contact

Pour toute question ou problème, veuillez contacter les auteurs via LinkedIn :

- [Ben Belaouedj](https://fr.linkedin.com/in/ben-belaouedj)
