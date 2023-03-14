terraform {
  backend "s3" {
    bucket = var.bucket_name
    key    = "terraform.tfstate"
    region = var.aws_region
  }
}


provider "aws" {
  region = var.aws_region
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "tf_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "tf_vpc"
    Terraform = "true"
  }
}


resource "aws_eip" "tf_eip" {
  count = var.settings.ec2_instance.count
  instance = aws_instance.tf_ec2_instance[count.index].id
  vpc = true
  tags = {
    Name = "tf_eip"
    Terraform = "true"
  }
}


resource "aws_subnet" "tf_public_subnet" {
  count = var.subnet_count.public
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_block[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "tf_public_subnet"
    Terraform = "true"
  }
}


resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_igw"
    Terraform = "true"
  }
}


resource "aws_route_table" "tf_public_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf_igw.id
  }

  tags = {
    Name = "tf_public_route_table"
    Terraform = "true"
  }
}


resource "aws_route_table_association" "tf_public_rt_association" {
  count = var.subnet_count.public
  subnet_id      = aws_subnet.tf_public_subnet[count.index].id
  route_table_id = aws_route_table.tf_public_route_table.id 
}


resource "aws_security_group" "tf_ec2_sg" {
  name        = "tf_ec2_sg"
  description = "Security group for ec2 instance"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf_ec2_sg"
    Terraform = "true"
  }
}


resource "aws_instance" "tf_ec2_instance" {
  count = var.settings.ec2_instance.count
  ami = var.settings.ec2_instance.ami
  instance_type = var.settings.ec2_instance.instance_type
  key_name = var.settings.ec2_instance.key_name
  security_groups = [aws_security_group.tf_ec2_sg.id]
  subnet_id = aws_subnet.tf_public_subnet[count.index].id
  user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt install git
sudo apt-get install python3
sudo apt install python3-pip -y
sudo apt install apache2 -y
sudo apt-get install libapache2-mod-wsgi-py3
sudo pip3 install Flask
sudo mv /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.old
sudo mkdir //project && cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/ci_cd_with_aws/flaskapp
sudo mv apache2_config.conf /etc/apache2/sites-enabled/
cd ..
sudo mv flaskapp /var/www/html
sudo systemctl reload apache2
EOF

  tags = {
    Name = "tf_ec2_instance"
    Terraform = "true"
  }
}
