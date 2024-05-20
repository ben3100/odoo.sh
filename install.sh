#!/bin/bash

################################################################################
# Script pour installer Odoo sur Ubuntu 22.04 LTS (peut également être utilisé pour d'autres versions)
# Auteur : https://fr.linkedin.com/in/ben-belaouedj
#-------------------------------------------------------------------------------
# Ce script installera Odoo sur votre serveur Ubuntu 22.04. Il peut installer plusieurs instances d'Odoo
# sur un seul Ubuntu grâce aux différents xmlrpc_ports
#-------------------------------------------------------------------------------
# crontab -e
# 43 6 * * * certbot renew --post-hook "systemctl reload nginx"
# Créez un nouveau fichier :
# sudo nano install_odoo_ubuntu.sh
# Placez ce contenu dedans et rendez ensuite le fichier exécutable :
# sudo chmod +x install_odoo_ubuntu.sh
# Exécutez le script pour installer Odoo :
# ./install_odoo_ubuntu.sh
################################################################################

OE_USER="ben"
OE_HOME="/opt/$OE_USER"
OE_HOME_EXT="/opt/$OE_USER/${OE_USER}-server"
# Le port par défaut où cette instance Odoo fonctionnera (à condition d'utiliser la commande -c dans le terminal)
# Mettez à true si vous voulez l'installer, false si vous n'en avez pas besoin ou si vous l'avez déjà installé.
INSTALL_WKHTMLTOPDF="True"
# Définir le port Odoo par défaut (vous devez toujours utiliser -c /etc/odoo-server.conf par exemple pour utiliser ceci.)
OE_PORT="8015"
# Choisissez la version d'Odoo que vous souhaitez installer. Par exemple : 16.0, 15.0 ou 14.0. En utilisant 'master', la version master sera installée.
# IMPORTANT ! Ce script contient des bibliothèques supplémentaires nécessaires spécifiquement pour Odoo 14.0
OE_VERSION="16.0"
# Mettez ceci à True si vous souhaitez installer la version entreprise d'Odoo !
IS_ENTERPRISE="False"
# Mettez ceci à True si vous souhaitez installer Nginx !
INSTALL_NGINX="True"
# Définissez le mot de passe superadmin - si GENERATE_RANDOM_PASSWORD est défini sur "True", nous générerons automatiquement un mot de passe aléatoire, sinon nous utiliserons celui-ci
OE_SUPERADMIN="bendehiba"
# Définir sur "True" pour générer un mot de passe aléatoire, "False" pour utiliser la variable dans OE_SUPERADMIN
GENERATE_RANDOM_PASSWORD="True"
OE_CONFIG="${OE_USER}-server"
# Définir le nom du site web
WEBSITE_NAME="www.ben-belaouedj.fr"
# Définir le port de longpolling Odoo par défaut (vous devez toujours utiliser -c /etc/odoo-server.conf par exemple pour utiliser ceci.)
LONGPOLLING_PORT="8072"
# Définir sur "True" pour installer certbot et avoir ssl activé, "False" pour utiliser http
ENABLE_SSL="True"
# Fournir un email pour enregistrer le certificat ssl
ADMIN_EMAIL="admin@ben-belaouedj.fr"

###
#----------------------------------------------------
# Désactiver l'authentification par mot de passe
#----------------------------------------------------
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

##
#--------------------------------------------------
# Mettre à jour le serveur
#--------------------------------------------------
echo -e "\n============== Mise à jour du serveur ======================="
sudo apt update 
sudo apt upgrade -y
sudo apt autoremove -y

#--------------------------------------------------
# Configurer les fuseaux horaires
#--------------------------------------------------
# définir le fuseau horaire correct sur ubuntu
timedatectl set-timezone Parise/europe
timedatectl

#--------------------------------------------------
# Installer le serveur PostgreSQL
#--------------------------------------------------
sudo apt install -y postgresql
sudo systemctl start postgresql && sudo systemctl enable postgresql

echo -e "\n=============== Création de l'utilisateur PostgreSQL ODOO ========================="
sudo su - postgres -c "createuser -s $OE_USER" 2> /dev/null || true

#--------------------------------------------------
# Installer les dépendances Python
#--------------------------------------------------
echo -e "\n=================== Installation des dépendances Python ============================"
sudo apt install -y git python3 python3-dev python3-pip build-essential wget python3-venv python3-wheel python3-cffi libxslt-dev  \
libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi libatlas-base-dev libblas-dev liblcms2-dev \
zlib1g-dev libjpeg8-dev libxrender1

# installer libssl
sudo apt -y install libssl-dev

#--------------------------------------------------
# Installer les dépendances pip Python
#--------------------------------------------------
echo -e "\n=================== Installation des dépendances pip Python ============================"
sudo apt install -y libpq-dev libxml2-dev libxslt1-dev libffi-dev

echo -e "\n================== Installer Wkhtmltopdf ============================================="
sudo apt install -y xfonts-75dpi xfonts-encodings xfonts-utils xfonts-base fontconfig

echo -e "\n================== Installer les packages/requirements python ============================"
sudo pip3 install --upgrade pip
sudo pip3 install setuptools wheel


echo -e "\n=========== Installation de nodeJS NPM et rtlcss pour le support LTR =================="
sudo curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs npm -y
sudo npm install -g --upgrade npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo npm install -g rtlcss node-gyp

#--------------------------------------------------
# Installer Wkhtmltopdf si nécessaire
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
echo -e "\n---- Installer wkhtmltopdf et placer les raccourcis aux bons endroits pour ODOO 16 ----"
###  Liens de téléchargement WKHTMLTOPDF
## === Ubuntu Jammy x64 === (pour d'autres distributions, veuillez remplacer ce lien,
## afin d'avoir la version correcte de wkhtmltopdf installée, pour une note de danger référez-vous à
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
## https://www.odoo.com/documentation/16.0/setup/install.html#debian-ubuntu

  sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb 
  sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
   else
  echo "Wkhtmltopdf n'est pas installé en raison du choix de l'utilisateur !"
  fi
  
echo -e "\n============== Créer un utilisateur système ODOO ========================"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ben' --group $OE_USER

# L'utilisateur doit également être ajouté au groupe sudo'ers.
sudo adduser $OE_USER sudo

echo -e "\n=========== Créer le répertoire des logs ================"
sudo mkdir /var/log/$OE_USER
sudo chown -R $OE_USER:$OE_USER /var/log/$OE_USER

#--------------------------------------------------
# Installer Odoo à partir de la source
#--------------------------------------------------
echo -e "\n========== Installation du serveur ODOO ==============="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_HOME_EXT/
sudo pip3 install -r /$OE_HOME_EXT/requirements.txt
if [ $IS_ENTERPRISE = "True" ]; then
    # Installation de l'édition entreprise d'Odoo !
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n============ Créer un lien symbolique pour node ==============="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n============== AVERTISSEMENT ====================="
        echo "Votre authentification avec Github a échoué ! Veuillez réessayer."
        printf "Pour cloner et installer la version entreprise d'Odoo, vous devez être un partenaire officiel d'Odoo et avoir accès à\nhttp://github.com/odoo/enterprise.\n"
        echo "ASTUCE : Appuyez sur ctrl+c pour arrêter ce script."
        echo "\n============================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n
