#!/bin/bash -eux

echo "==> waiting for cloud-init to finish"
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
    echo 'Waiting for Cloud-Init...'
    sleep 1
done

echo "==> updating apt cache"
sudo apt-get update -qq

echo "==> upgrade apt packages"
sudo apt-get upgrade -y -qq

echo "==> installing qemu-guest-agent"
sudo apt-get install -y -qq qemu-guest-agent

echo "==> install dependencies"
sudo apt install -y apache2 \
                 ghostscript \
                 libapache2-mod-php \
                 mysql-server \
                 php \
                 php-bcmath \
                 php-curl \
                 php-imagick \
                 php-intl \
                 php-json \
                 php-mbstring \
                 php-mysql \
                 php-xml \
                 php-zip \
                 curl \
                 ufw

echo "==> install wordpress"
sudo mkdir -p /srv/www
sudo chown www-data: /srv/www
curl https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

echo "==> configure apache for wordpress"
echo "- create apache site for wordpress"
echo "<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/wordpress.conf

echo "- enable the site"
sudo a2ensite wordpress

echo "- enable url rewriting"
sudo a2enmod rewrite

echo "- disable the default “It Works” site"
sudo a2dissite 000-default

echo "- reload apache2"
sudo service apache2 reload


echo "==> configure database"
# Define MySQL variables
DB_NAME="wordpress"
DB_USER="wordpress"
DB_PASS="wordpress"

sudo service mysql start
# Execute MySQL commands as root
sudo mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME};
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

sudo service mysql start

echo "==> configure wordpress to connect the database"
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php

sudo -u www-data sed -i 's/database_name_here/wordpress/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/username_here/wordpress/' /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i 's/password_here/wordpress/' /srv/www/wordpress/wp-config.php

echo "==> WordPress set up successfully"


echo "==> configure firewall rule"
sudo ufw allow 22
ufw allow 80
ufw allow 443
ufw --force enable


echo "==> create ssh banner"
echo "Welcome to Application Wordpress" > /etc/issue.net

# Enable SSH banner in sshd config
sed -i 's|^#Banner.*|Banner /etc/issue.net|' /etc/ssh/sshd_config

# Restart SSH service to apply changes
systemctl restart sshd
