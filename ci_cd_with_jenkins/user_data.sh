#!/bin/bash
sudo apt-get update
sudo apt install openjdk-17-jre -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo sed -i '16 i\PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/lib/jvm/java-17-openjdk-amd64/bin/' /etc/init.d/jenkins
sudo service jenkins start
