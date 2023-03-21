#!/bin/bash

#install Jenkins
sudo apt-get update
sudo apt install openjdk-17-jre -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt-get update
sudo apt install jenkins -y
sudo sed -i '16 i\PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/lib/jvm/java-17-openjdk-amd64/bin/' /etc/init.d/jenkins
sudo service jenkins start

#install Terraform
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \ gpg --dearmor | \ sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \ https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \ sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update
sudo apt-get install terraform
