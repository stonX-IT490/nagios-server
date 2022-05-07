#!/bin/bash

# Update repos
sudo apt update

# Do full upgrade of system
sudo apt full-upgrade -y

# Remove leftover packages and purge configs
sudo apt autoremove -y --purge

# Install required packages
sudo apt install autoconf gcc libmcrypt-dev make libssl-dev wget dc build-essential gettext

# Nagios
sudo useradd nagios

# Install Nagios NRPE - Remote Monitoring Plugin
cd ~
VER="4.0.3"
wget https://github.com/NagiosEnterprises/nrpe/releases/download/nrpe-$VER/nrpe-$VER.tar.gz
tar xvf nrpe-$VER.tar.gz
cd nrpe-$VER
./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make check_nrpe
sudo make install-plugin

