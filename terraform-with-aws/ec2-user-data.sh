#!/bin/bash
sudo apt-get update
sudo apt install apache2 -y
sudo apt-get install libapache2-mod-wsgi-py3
sudo apt install git
sudo apt install python3-pip -y
sudo pip3 install flask_sqlalchemy
sudo mkdir //project
cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/terraform-with-aws/testapp
sed -i '7 i\dialect = "${var.settings.database.engine}"' testapp.py
sed -i '8 i\username = "${var.settings.database.username}"' testapp.py
sed -i '9 i\password = "${var.settings.database.password}"' testapp.py
sed -i '10 i\host = "${aws_db_instance.tf-rds.address}"' testapp.py
sed -i '11 i\port = "${var.settings.database.port}"' testapp.py
sed -i '12 i\database = "${var.settings.database.db_name}"' testapp.py
cd ..
sudo mv testapp /var/www/html/
sudo mv testapp/testapp.conf /etc/apache2/sites-available/
sudo a2ensite testapp.conf
sudo service apache2 restart
