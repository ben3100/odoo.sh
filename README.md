
Installation Script for Odoo Open Source
This script provides the ability to define an xmlrpc_port in the .conf file generated under /etc/. It can be safely used on a multi-odoo code base server because the default Odoo port is changed before Odoo is started.

Installing Nginx
If you set the parameter INSTALL_NGINX to True, you should also configure workers. Without workers, you will likely experience connection loss issues. Refer to the Odoo deployment guide for configuring workers.

Installation Procedure
Download the script:

bash
Copier le code
wget https://raw.githubusercontent.com/hrmuwanika/odoo/16.0/install_odoo_ubuntu.sh
Modify the parameters as needed:
Here is a list of the most used configuration options:

OE_USER: The username for the system user.
GENERATE_RANDOM_PASSWORD: If set to True, the script generates a random password. If False, it uses the password in OE_SUPERADMIN. The default value is True.
OE_PORT: The port where Odoo should run, e.g., 8069.
OE_VERSION: The Odoo version to install, e.g., 14.0 for Odoo V14.
IS_ENTERPRISE: Set to True to install the Enterprise version on top of Odoo 16.0. Set to False for the community version of Odoo 16.
OE_SUPERADMIN: The master password for this Odoo installation.
INSTALL_NGINX: Set to True by default. Set to False to skip installing Nginx.
WEBSITE_NAME: Set the website name for Nginx configuration.
ENABLE_SSL: Set to True to install Certbot and configure Nginx with HTTPS using a free Let's Encrypt certificate.
ADMIN_EMAIL: Needed for Let's Encrypt registration. Replace the placeholder with your organization's email.
Make the script executable:

bash
Copier le code
sudo chmod +x install_odoo_ubuntu.sh
Execute the script:

bash
Copier le code
sudo ./install_odoo_ubuntu.sh
The installation should take about 10 minutes to complete. You will then be able to access it from anywhere in the world using its IP address.

For more information on hosting, upgrading to Odoo Enterprise, or changing your domain, contact me at work@ben-belaouedj.fr.

