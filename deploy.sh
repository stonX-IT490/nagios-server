#!/bin/bash

# Update repos
sudo apt update

# Do full upgrade of system
sudo apt full-upgrade -y

# Remove leftover packages and purge configs
sudo apt autoremove -y --purge

# Install required packages
sudo apt install -y ufw php-amqp php-bcmath php-cli php-common php-curl php-fpm php-json php-mbstring php-mysql php-readline php-opcache php-gmp php-zip nginx wget unzip inotify-tools 

# Setup firewall
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Install zerotier
sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
curl -s https://install.zerotier.com | sudo bash

# Setup Central Logging
git clone git@github.com:stonX-IT490/logging.git ~/logging
cd ~/logging
chmod +x deploy.sh
./deploy.sh
cd ~/

# Setup Nagios Server
sudo apt install -y vim wget curl build-essential unzip openssl libssl-dev apache2 php libapache2-mod-php php-gd libgd-dev
cd ~
export VER="4.4.7"
wget https://github.com/NagiosEnterprises/nagioscore/releases/download/nagios-$VER/nagios-$VER.tar.gz
tar xvzf nagios-$VER.tar.gz
cd nagios-$VER
./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make install-groups-users
sudo usermod -a -G nagios www-data
sudo make all
sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config
sudo make install-webconf
sudo a2enmod rewrite cgi
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin
sudo chown www-data:www-data /usr/local/nagios/etc/htpasswd.users
sudo chmod 640 /usr/local/nagios/etc/htpasswd.users

# Install Nagios Plugins Bundle
cd ~
VER="2.4.0"
wget https://github.com/nagios-plugins/nagios-plugins/releases/download/release-$VER/nagios-plugins-$VER.tar.gz
tar xvf nagios-plugins-$VER.tar.gz
cd nagios-plugins-$VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install

# Install Nagios NRPE - Remote Monitoring Plugin
cd ~
VER="4.0.3"
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-$VER/nrpe-$VER.tar.gz
tar xvf nrpe-$VER.tar.gz
cd nrpe-$VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make check_nrpe
sudo make install-plugin

# Configuring Nagios
echo "cfg_dir=/usr/local/nagios/etc/servers" >> /usr/local/nagios/etc/nagios.cfg
sudo mkdir /usr/local/nagios/etc/servers
touch /usr/local/nagios/etc/objects/contacts.cfg

echo "define command{
        command_name check_nrpe
        command_line $USER1$/check_nrpe -H $HOSTADDRESS$ -c $ARG1$
}" >> /usr/local/nagios/etc/objects/commands.cfg


# Allow Nagios in Firewall
sudo ufw allow 80
sudo ufw reload

# Start Nagios Service
sudo systemctl restart apache2
sudo systemctl start nagios.service

echo "go to http://<IP Address/FQDN>/nagios   user: nagiosadmin  pass: whatever you set it to";