#!/bin/bash

#install Python, Apache
sudo apt-get update
sudo apt install git
sudo apt-get install python3
sudo apt install python3-pip -y
sudo apt install apache2 -y
sudo apt-get install libapache2-mod-wsgi-py3
sudo pip3 install Flask
sudo mv /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.old
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/ci_cd_with_aws/flaskapp
sudo mv apache2_config.conf /etc/apache2/sites-enabled/
cd ..
sudo mv flaskapp /var/www/html
sudo systemctl reload apache2
