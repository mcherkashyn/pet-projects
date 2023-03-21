#!/bin/bash
sudo apt-get update
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo apt-get update
sudo docker pull jenkins/jenkins:lts-jdk11
sudo docker run --name jenkins --restart always -p 8080:8080 -p 80:80 -v /home/ubuntu:/var/jenkins_home -v /home/ubuntu/sock:/var/run/docker.sock jenkins/jenkins:lts-jdk11

# sudo apt install openjdk-17-jre -y
# wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key |sudo gpg --dearmor -o /usr/share/keyrings/jenkins.gpg
# sudo sh -c 'echo deb [signed-by=/usr/share/keyrings/jenkins.gpg] http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
# sudo apt-get update
# sudo apt install jenkins -y
# sudo sed -i '16 i\PATH=/bin:/usr/bin:/sbin:/usr/sbin:/usr/lib/jvm/java-17-openjdk-amd64/bin/' /etc/init.d/jenkins
# sudo usermod -aG docker jenkins
# sudo service jenkins start
