provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
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
  }
}


resource "aws_eip" "tf_eip" {
  count = var.settings.ec2_instance.count
  instance = aws_instance.tf_ec2_instance[count.index].id
  vpc = true
  tags = {
    Name = "tf_eip"
  }
}


resource "aws_subnet" "tf_public_subnet" {
  count = var.subnet_count.public
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "tf_public_subnet"
  }
}


resource "aws_subnet" "tf_private_subnet" {
  count = var.subnet_count.private
  vpc_id = aws_vpc.tf_vpc.id
  cidr_block = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "tf_private_subnet"
  }
}


resource "aws_internet_gateway" "tf_igw" {
  vpc_id = aws_vpc.tf_vpc.id
  tags = {
    Name = "tf_igw"
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
  }
}


resource "aws_route_table" "tf_private_route_table" {
  vpc_id = aws_vpc.tf_vpc.id

  tags = {
    Name = "tf_private_route_table"
  }
}


resource "aws_route_table_association" "tf_private_rt_association" {
  count = var.subnet_count.private
  subnet_id = aws_subnet.tf_private_subnet[count.index].id
  route_table_id = aws_route_table.tf_private_route_table.id 
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
  }
}


resource "aws_security_group" "tf_rds_sg" {
  name        = "tf_rds_sg"
  description = "Security group for rds instance"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    description = "Allow rds traffic only for ec2 instance"
    from_port   = var.settings.database.port
    to_port     = var.settings.database.port
    protocol    = "tcp"
    security_groups = [aws_security_group.tf_ec2_sg.id]
  }
  
  tags = {
    Name = "tf_rds_sg"
  }
}


resource "aws_db_subnet_group" "tf_db_subnet_group" {
  name       = "tf_db_subnet_group"
  subnet_ids = [for subnet in aws_subnet.tf_private_subnet : subnet.id]

  tags = {
    Name = "tf_db_subnet_group"
  }
}


resource "aws_db_instance" "tf_rds" {
  allocated_storage = var.settings.database.allocated_storage
  storage_type = var.settings.database.storage_type
  engine = var.settings.database.engine
  engine_version = var.settings.database.engine_version
  instance_class = var.settings.database.instance_class
  db_name = var.settings.database.db_name
  username = var.settings.database.username
  password = var.settings.database.password
  publicly_accessible = var.settings.database.publicly_accessible
  skip_final_snapshot = var.settings.database.skip_final_snapshot
  port = var.settings.database.port
  db_subnet_group_name = aws_db_subnet_group.tf_db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.tf_rds_sg.id]

  tags = {
    Name = "tf_rds"
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
sudo pip3 install Flask SQLAlchemy Flask-SQLAlchemy psycopg2-binary
sudo mv /etc/apache2/sites-enabled/000-default.conf /etc/apache2/sites-enabled/000-default.conf.old
sudo mkdir //project && cd /project
sudo git clone https://github.com/mcherkashyn/pet-projects.git
cd pet-projects/terraform_with_aws/flaskapp
sudo mv apache2_config.conf /etc/apache2/sites-enabled/
sudo sed -i '7 i\dialect = "${var.settings.database.dialect}"' flaskapp.py
sudo sed -i '8 i\username = "${var.settings.database.username}"' flaskapp.py
sudo sed -i '9 i\password = "${var.settings.database.password}"' flaskapp.py
sudo sed -i '10 i\host = "${aws_db_instance.tf_rds.address}"' flaskapp.py
sudo sed -i '11 i\port = "${var.settings.database.port}"' flaskapp.py
sudo sed -i '12 i\database = "${var.settings.database.db_name}"' flaskapp.py
cd ..
sudo mv flaskapp /var/www/html
sudo systemctl reload apache2
EOF

  tags = {
    Name = "tf_ec2_instance"
  }
}
