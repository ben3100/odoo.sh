# Script d'installation d'Odoo sur Ubuntu 22.04 LTS

## Auteurs
- [Ben Belaouedj](https://fr.linkedin.com/in/ben-belaouedj)

## Description

Ce script permet d'installer Odoo sur un serveur Ubuntu 22.04 LTS. Il peut également être utilisé pour d'autres versions d'Ubuntu. Le script prend en charge l'installation de plusieurs instances d'Odoo sur un seul serveur Ubuntu grâce à l'utilisation de différents ports `xmlrpc`.

## Prérequis

- Un serveur Ubuntu 22.04 LTS
- Un accès root ou sudo

## Fonctionnalités

- Mise à jour du serveur
- Configuration du fuseau horaire
- Installation de PostgreSQL
- Installation des dépendances Python
- Installation de Node.js et npm
- Installation de wkhtmltopdf
- Création d'un utilisateur système pour Odoo
- Installation d'Odoo depuis la source
- Option d'installation de la version entreprise d'Odoo (versions 14 ou 15)
- Configuration de Nginx comme proxy inverse
- Configuration de SSL avec Certbot

## Utilisation

### Étape 1: Télécharger le script

Clonez le dépôt contenant le script :

```sh
git clone https://github.com/ben3100/odoo.sh.git
cd odoo.sh
