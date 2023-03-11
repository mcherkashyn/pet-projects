#!/bin/bash
sudo apt-get update
sudo apt install git
sudo apt-get install python3
sudo apt install python3-pip -y
sudo apt install apache2 -y
sudo apt-get install libapache2-mod-wsgi-py3
sudo pip3 install Flask SQLAlchemy Flask-SQLAlchemy psycopg2-binary
sudo mkdir //project
cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/terraform-with-aws/flaskapp
sudo sed -i '7 i\dialect = "${var.settings.database.dialect}"' flaskapp.py
sudo sed -i '8 i\username = "${var.settings.database.username}"' flaskapp.py
sudo sed -i '9 i\password = "${var.settings.database.password}"' flaskapp.py
sudo sed -i '10 i\host = "${aws_db_instance.tf_rds.address}"' flaskapp.py
sudo sed -i '11 i\port = "${var.settings.database.port}"' flaskapp.py
sudo sed -i '12 i\database = "${var.settings.database.db_name}"' flaskapp.py
sudo mv /ect/apache2/sites-enable
cd ..
sudo mv flaskapp /var/www/html

cd /etc/apache2/sites-available
sudo systemctl reload apache2
