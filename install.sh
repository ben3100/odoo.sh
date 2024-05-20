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
# sudo nano install.sh
# Placez ce contenu dedans et rendez ensuite le fichier exécutable :
# sudo chmod +x install.sh
# Exécutez le script pour installer Odoo :
# sudo ./install.sh
################################################################################

# Demander à l'utilisateur d'entrer les paramètres
read -p "Entrez le nom d'utilisateur système pour Odoo (ex: odoo): " ENTREPRISE_USER
read -p "Entrez le mot de passe superadmin pour Odoo (ex: admin): " ENTREPRISE_SUPERADMIN
read -p "Entrez le nom du site web pour la configuration Nginx (ex: example.com): " WEBSITE_NAME
read -p "Entrez la version d'Odoo à installer (ex: 16.0, 17.0): " ENTREPRISE_VERSION
read -p "Voulez-vous installer la version entreprise d'Odoo ? (True/False): " INSTALL_ENTREPRISE

if [ "$INSTALL_ENTREPRISE" = "True" ]; alors
    read -p "Entrez la version entreprise d'Odoo à installer (14 ou 15): " ENTREPRISE_VERSION_SPECIFIC
fi

ENTREPRISE_HOME="/opt/$ENTREPRISE_USER"
ENTREPRISE_HOME_EXT="/opt/$ENTREPRISE_USER/${ENTREPRISE_USER}-server"
INSTALL_WKHTMLTOPDF="True"
ENTREPRISE_PORT="8069"
INSTALL_NGINX="True"
GENERATE_RANDOM_PASSWORD="True"
ENTREPRISE_CONFIG="${ENTREPRISE_USER}-server"
LONGPOLLING_PORT="8072"
ENABLE_SSL="True"
ADMIN_EMAIL="admin@${WEBSITE_NAME}"

# Désactiver l'authentification par mot de passe
sudo sed -i 's/#ChallengeResponseAuthentication yes/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/UsePAM yes/UsePAM no/' /etc/ssh/sshd_config 
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Mettre à jour le serveur
echo -e "\n============== Mise à jour du serveur ======================="
sudo apt update 
sudo apt upgrade -y
sudo apt autoremove -y

# Configurer le fuseau horaire
timedatectl set-timezone Europe/Paris
timedatectl

# Installer le serveur PostgreSQL
sudo apt install -y postgresql
sudo systemctl start postgresql && sudo systemctl enable postgresql

echo -e "\n=============== Création de l'utilisateur PostgreSQL ODOO ========================="
sudo su - postgres -c "createuser -s $ENTREPRISE_USER" 2> /dev/null || true

# Installer les dépendances Python
echo -e "\n=================== Installation des dépendances Python ============================"
sudo apt install -y git python3 python3-dev python3-pip build-essential wget python3-venv python3-wheel python3-cffi libxslt-dev \
libzip-dev libldap2-dev libsasl2-dev python3-setuptools node-less libjpeg-dev gdebi libatlas-base-dev libblas-dev liblcms2-dev \
zlib1g-dev libjpeg8-dev libxrender1

# Installer libssl
sudo apt -y install libssl-dev

# Installer les dépendances pip Python
echo -e "\n=================== Installation des dépendances pip Python ============================"
sudo apt install -y libpq-dev libxml2-dev libxslt1-dev libffi-dev

echo -e "\n================== Installer Wkhtmltopdf ============================================="
sudo apt install -y xfonts-75dpi xfonts-encodings xfonts-utils xfonts-base fontconfig

echo -e "\n================== Installation des packages/requirements Python ============================"
sudo pip3 install --upgrade pip
sudo pip3 install setuptools wheel

echo -e "\n=========== Installation de nodeJS NPM et rtlcss pour le support LTR =================="
sudo curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs npm -y
sudo npm install -g --upgrade npm
sudo ln -s /usr/bin/nodejs /usr/bin/node
sudo npm install -g less less-plugin-clean-css
sudo npm install -g rtlcss node-gyp

# Installer Wkhtmltopdf si nécessaire
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
echo -e "\n---- Installation de wkhtmltopdf et placement des raccourcis au bon endroit pour ODOO ----"
  sudo wget https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb 
  sudo dpkg -i wkhtmltox_0.12.6.1-2.jammy_amd64.deb
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf n'est pas installé en raison du choix de l'utilisateur !"
fi
  
echo -e "\n============== Création de l'utilisateur système ODOO ========================"
sudo adduser --system --quiet --shell=/bin/bash --home=$ENTREPRISE_HOME --gecos 'odoo' --group $ENTREPRISE_USER

# Ajouter l'utilisateur au groupe sudo
sudo adduser $ENTREPRISE_USER sudo

echo -e "\n=========== Création du répertoire de logs ================"
sudo mkdir /var/log/$ENTREPRISE_USER
sudo chown -R $ENTREPRISE_USER:$ENTREPRISE_USER /var/log/$ENTREPRISE_USER

# Installer Odoo depuis la source
echo -e "\n========== Installation du serveur ODOO ==============="
sudo git clone --depth 1 --branch $ENTREPRISE_VERSION https://www.github.com/odoo/odoo $ENTREPRISE_HOME_EXT/
sudo pip3 install -r /$ENTREPRISE_HOME_EXT/requirements.txt
if [ $INSTALL_ENTREPRISE = "True" ]; then
    # Installation d'Odoo Enterprise
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n============ Création de lien symbolique pour node ==============="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/enterprise"
    sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/enterprise/addons"
    git clone --depth 1 --branch $ENTREPRISE_VERSION https://www.github.com/odoo/enterprise "$ENTREPRISE_HOME/enterprise/addons"
fi

# Configurer les permissions
echo -e "\n=========== Configurer les permissions du système ================"
sudo chown -R $ENTREPRISE_USER:$ENTREPRISE_USER $ENTREPRISE_HOME/*

# Créer le fichier de configuration Odoo
echo -e "\n=========== Création du fichier de configuration ODOO ================"
sudo touch /etc/${ENTREPRISE_CONFIG}.conf
sudo su root -c "printf '[options] \n
; This is the password that allows database operations:\n
admin_passwd = ${ENTREPRISE_SUPERADMIN} \n
db_host = False \n
db_port = False \n
db_user = ${ENTREPRISE_USER} \n
db_password = False \n
addons_path = ${ENTREPRISE_HOME_EXT}/addons,${ENTREPRISE_HOME}/custom/addons \n
logfile = /var/log/${ENTREPRISE_USER}/${ENTREPRISE_CONFIG}.log\n
logrotate = True\n
xmlrpc_interface = 127.0.0.1 \n
netrpc_interface = 127.0.0.1 \n
dbfilter = .*\n
proxy_mode = True\n
workers = 4\n
max_cron_threads = 2\n' > /etc/${ENTREPRISE_CONFIG}.conf"

# Créer le service système Odoo
echo -e "* Creating systemd service file"
sudo touch /etc/systemd/system/$ENTREPRISE_USER.service
sudo su root -c "echo '[Unit]
Description=Odoo
Documentation=http://www.odoo.com
[Service]
# Ubuntu/Debian convention:
Type=simple
User=$ENTREPRISE_USER
ExecStart=/usr/bin/python3 $ENTREPRISE_HOME_EXT/odoo-bin -c /etc/${ENTREPRISE_CONFIG}.conf
[Install]
WantedBy=default.target' > /etc/systemd/system/$ENTREPRISE_USER.service"

echo -e "* Starting Odoo Service"
sudo systemctl daemon-reload
sudo systemctl start $ENTREPRISE_USER.service
sudo systemctl enable $ENTREPRISE_USER.service

# Installer et configurer Nginx
if [ $INSTALL_NGINX = "True" ]; then
    echo -e "\n* Installing and configuring Nginx"
    sudo apt install -y nginx
    cat <<EOF | sudo tee /etc/nginx/sites-available/$ENTREPRISE_USER
server {
    listen 80;
    server_name $WEBSITE_NAME;

    proxy_buffers 16 64k;
    proxy_buffer_size 128k;

    proxy_read_timeout 900s;
    proxy_connect_timeout 900s;
    proxy_send_timeout 900s;

    client_max_body_size 0;

    gzip on;
    gzip_min_length 1100;
    gzip_buffers 4 32k;
    gzip_types text/plain application/x-javascript text/xml text/css;
    gzip_vary on;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    location / {
        proxy_pass http://127.0.0.1:$ENTREPRISE_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forward-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~* /web/static/ {
        proxy_cache_valid 200 90m;
        proxy_buffering on;
        expires 864000;
        proxy_pass http://127.0.0.1:$ENTREPRISE_PORT;
    }

    # common gzip
    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
    gzip on;
}
EOF

    sudo ln -s /etc/nginx/sites-available/$ENTREPRISE_USER /etc/nginx/sites-enabled/$ENTREPRISE_USER
    sudo rm /etc/nginx/sites-enabled/default
    sudo systemctl restart nginx
fi

# Configurer SSL avec Let's Encrypt
if [ $ENABLE_SSL = "True" ]; then
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d $WEBSITE_NAME --non-interactive --agree-tos -m $ADMIN_EMAIL
fi

# Configurer UFW (Uncomplicated Firewall)
echo -e "\n========== Configurer UFW (Uncomplicated Firewall) ============"
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw allow 8069/tcp
sudo ufw allow 8072/tcp
sudo ufw --force enable
sudo ufw allow 6010/tcp
sudo ufw allow 22/tcp

echo "-----------------------------------------------------------"
echo "Installation complète de Odoo"
echo "-----------------------------------------------------------"
echo "Vous pouvez maintenant accéder à votre instance Odoo via l'adresse IP de votre serveur ou le nom de domaine que vous avez configuré."
echo "Nom d'utilisateur système: $ENTREPRISE_USER"
echo "Port Odoo: $ENTREPRISE_PORT"
echo "-----------------------------------------------------------"
