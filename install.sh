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

if [ "$INSTALL_ENTREPRISE" = "True" ]; then
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
sudo adduser --system --quiet --shell=/bin/bash --home=$ENTREPRISE_HOME --gecos 'ODOO' --group $ENTREPRISE_USER

# Ajouter l'utilisateur au groupe sudo
sudo adduser $ENTREPRISE_USER sudo

echo -e "\n=========== Création du répertoire de logs ================"
sudo mkdir /var/log/$ENTREPRISE_USER
sudo chown -R $ENTREPRISE_USER:$ENTREPRISE_USER /var/log/$ENTREPRISE_USER

# Installer Odoo depuis la source
echo -e "\n========== Installation du serveur ODOO ==============="
sudo git clone --depth 1 --branch $ENTREPRISE_VERSION https://www.github.com/odoo/odoo $ENTREPRISE_HOME_EXT/
sudo pip3 install -r $ENTREPRISE_HOME_EXT/requirements.txt
if [ $INSTALL_ENTREPRISE = "True" ]; then
    # Installation d'Odoo Enterprise
    sudo pip3 install psycopg2-binary pdfminer.six
    echo -e "\n============ Création de lien symbolique pour node ==============="
    sudo ln -s /usr/bin/nodejs /usr/bin/node
    sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/enterprise"
    sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/enterprise/addons"

    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $ENTREPRISE_VERSION https://www.github.com/odoo/enterprise "$ENTREPRISE_HOME/enterprise/addons" 2>&1)
    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
        echo "\n============== AVERTISSEMENT ====================="
        echo "Votre authentification avec Github a échoué ! Veuillez réessayer."
        printf "Pour cloner et installer la version Enterprise d'Odoo, vous devez être un partenaire officiel d'Odoo et avoir accès à\nhttp://github.com/odoo/enterprise.\n"
        echo "ASTUCE : Appuyez sur ctrl+c pour arrêter ce script."
        echo "\n============================================="
        echo " "
        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $ENTREPRISE_VERSION https://www.github.com/odoo/enterprise "$ENTREPRISE_HOME/enterprise/addons" 2>&1)
    done

    echo -e "\n========= Code Enterprise ajouté sous $ENTREPRISE_HOME/enterprise/addons ========="
    echo -e "\n============= Installation des bibliothèques spécifiques à Enterprise ============"
    sudo -H pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
    sudo npm install -g less-plugin-clean-css

    if [ "$ENTREPRISE_VERSION_SPECIFIC" = "14" ]; then
        echo -e "\n======== Ajout de certains modules entreprise pour Odoo 14 ============="
        wget https://www.soladrive.com/downloads/enterprise-14.0.tar.gz
        tar -zxvf enterprise-14.0.tar.gz
        cp -rf odoo-14.0*/odoo/addons/* ${ENTREPRISE_HOME}/enterprise/addons
        rm enterprise-14.0.tar.gz
    elif [ "$ENTREPRISE_VERSION_SPECIFIC" = "15" ]; then
        echo -e "\n======== Ajout de certains modules entreprise pour Odoo 15 ============="
        wget https://www.soladrive.com/downloads/enterprise-15.0.tar.gz
        tar -zxvf enterprise-15.0.tar.gz
        cp -rf odoo-15.0*/odoo/addons/* ${ENTREPRISE_HOME}/enterprise/addons
        rm enterprise-15.0.tar.gz
    fi

    sudo chown -R $ENTREPRISE_USER:$ENTREPRISE_USER ${ENTREPRISE_HOME}/
fi

echo -e "\n========= Création du répertoire des modules personnalisés ============"
sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/custom"
sudo su $ENTREPRISE_USER -c "mkdir $ENTREPRISE_HOME/custom/addons"

echo -e "\n======= Définir les permissions sur le dossier home =========="
sudo chown -R $ENTREPRISE_USER:$ENTREPRISE_USER $ENTREPRISE_HOME/

echo -e "\n========== Création du fichier de configuration du serveur ============="
sudo touch /etc/${ENTREPRISE_CONFIG}.conf
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
if [ $GENERATE_RANDOM_PASSWORD = "True" ]; then
    echo -e "\n========= Génération du mot de passe admin aléatoire ==========="
    ENTREPRISE_SUPERADMIN=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
fi
sudo su root -c "printf 'admin_passwd = ${ENTREPRISE_SUPERADMIN}\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
if [ $ENTREPRISE_VERSION > "11.0" ]; then
    sudo su root -c "printf 'http_port = ${ENTREPRISE_PORT}\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
else
    sudo su root -c "printf 'xmlrpc_port = ${ENTREPRISE_PORT}\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
fi
sudo su root -c "printf 'logfile = /var/log/${ENTREPRISE_USER}/${ENTREPRISE_CONFIG}.log\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'addons_path=${ENTREPRISE_HOME_EXT}/addons,${ENTREPRISE_HOME}/custom/addons' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'xmlrpc_interface = 127.0.0.1\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'netrpc_interface = 127.0.0.1\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'dbfilter = ^%d$\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'proxy_mode = True\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'workers = 4\n' >> /etc/${ENTREPRISE_CONFIG}.conf"
sudo su root -c "printf 'max_cron_threads = 2\n' >> /etc/${ENTREPRISE_CONFIG}.conf"

echo -e "\n=========== Créer le service Odoo =============="
sudo touch /etc/systemd/system/$ENTREPRISE_CONFIG.service
sudo su root -c "printf '[Unit]\nDescription=Odoo\nDocumentation=http://www.odoo.com\n[Service]\n' >> /etc/systemd/system/$ENTREPRISE_CONFIG.service"
sudo su root -c "printf 'User=$ENTREPRISE_USER\nGroup=$ENTREPRISE_USER\n' >> /etc/systemd/system/$ENTREPRISE_CONFIG.service"
sudo su root -c "printf 'ExecStart=/usr/bin/python3 $ENTREPRISE_HOME_EXT/odoo-bin -c /etc/${ENTREPRISE_CONFIG}.conf\n' >> /etc/systemd/system/$ENTREPRISE_CONFIG.service"
sudo su root -c "printf 'StandardOutput=journal+console\n' >> /etc/systemd/system/$ENTREPRISE_CONFIG.service"
sudo su root -c "printf '[Install]\nWantedBy=multi-user.target\n' >> /etc/systemd/system/$ENTREPRISE_CONFIG.service"
sudo systemctl daemon-reload
sudo systemctl enable $ENTREPRISE_CONFIG
sudo systemctl start $ENTREPRISE_CONFIG

if [ $INSTALL_NGINX = "True" ]; then
    echo -e "\n================ Installation de Nginx =================="
    sudo apt install -y nginx
    sudo rm /etc/nginx/sites-enabled/default
    sudo rm /etc/nginx/sites-available/default
    sudo touch /etc/nginx/sites-available/$ENTREPRISE_USER
    sudo ln -s /etc/nginx/sites-available/$ENTREPRISE_USER /etc/nginx/sites-enabled/$ENTREPRISE_USER
    sudo su root -c "printf 'server {\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    listen 80;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    server_name $WEBSITE_NAME;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_read_timeout 720s;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_connect_timeout 720s;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_send_timeout 720s;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_set_header X-Forwarded-Host \$host;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_set_header X-Forwarded-Proto \$scheme;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    proxy_set_header X-Real-IP \$remote_addr;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    add_header Strict-Transport-Security max-age=15768000;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    location / {\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        proxy_pass http://127.0.0.1:$ENTREPRISE_PORT;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    }\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    location /longpolling {\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        proxy_pass http://127.0.0.1:$LONGPOLLING_PORT;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    }\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    location ~* /web/static/ {\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        proxy_cache_valid 200 90m;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        proxy_buffering on;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        expires 864000;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '        proxy_pass http://127.0.0.1:$ENTREPRISE_PORT;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    }\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '    gzip on;\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo su root -c "printf '}\n' >> /etc/nginx/sites-available/$ENTREPRISE_USER"
    sudo systemctl restart nginx
fi

if [ $ENABLE_SSL = "True" ]; then
    echo -e "\n============ Installation de Certbot pour SSL ============="
    sudo apt install certbot python3-certbot-nginx -y
    sudo certbot --nginx -d $WEBSITE_NAME --non-interactive --agree-tos --email $ADMIN_EMAIL
    sudo systemctl reload nginx
fi

echo -e "\n==== Installation terminée ! ===="
echo "-----------------------------------------------------------"
echo "Odoo a été installé avec succès sur votre système."
echo "URL: http://$WEBSITE_NAME"
echo "Mot de passe admin: $ENTREPRISE_SUPERADMIN"
echo "-----------------------------------------------------------"
