#!/bin/bash

#install Docker
sudo apt-get update
sudo apt install apt-transport-https ca-certificates curl gnupg lsb-release -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo mkdir //project && cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/docker_with_aws/web_app/
sudo docker build -t docker_web_app .
sudo docker run --log-driver=awslogs --log-opt awslogs-region=us-east-1 --log-opt awslogs-group="/flask_logs" -p 80:80 docker_web_app
