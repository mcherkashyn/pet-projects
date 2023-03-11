#!/bin/bash
sudo apt-get update
sudo apt install apache2 -y
sudo systemctl start apache2
sudo apt-get install libapache2-mod-wsgi-py3
sudo apt install git
sudo apt-get install python3
sudo apt install python3-pip -y
sudo pip3 install Flask Flask-SQLAlchemy psycopg2-binary
sudo mkdir //project
cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/terraform-with-aws/testapp
sudo sed -i '7 i\dialect = "${var.settings.database.dialect}"' app.py
sudo sed -i '8 i\username = "${var.settings.database.username}"' app.py
sudo sed -i '9 i\password = "${var.settings.database.password}"' app.py
sudo sed -i '10 i\host = "${aws_db_instance.tf-rds.address}"' app.py
sudo sed -i '11 i\port = "${var.settings.database.port}"' app.py
sudo sed -i '12 i\database = "${var.settings.database.db_name}"' app.py
cd ..
sudo mv testapp/app.conf /etc/apache2/sites-available/
sudo mv testapp /var/www/
cd /etc/apache2/sites-available
sudo sed -i '4 i\    ServerName ${aws_eip.tf-eip[0].public_ip}' app.conf
sudo a2ensite app.conf
sudo systemctl restart apache2
