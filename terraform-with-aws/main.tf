provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-east-1"
}


data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "tf-vpc" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "tf-vpc"
  }
}


resource "aws_eip" "tf-eip" {
  instance = aws_instance.tf-ec2-instance.id
  vpc = true
  tags = {
    Name = "tf-eip"
  }
}


resource "aws_subnet" "tf-public-subnet" {
  vpc_id            = aws_vpc.tf-vpc.id
  cidr_block        = "172.20.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tf-public-subnet"
  }
}


resource "aws_subnet" "tf-private-subnet" {
  count = var.subnet_count.private
  vpc_id = aws_vpc.tf-vpc.id
  cidr_block = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "tf-private-subnet"
  }
}


resource "aws_internet_gateway" "tf-igw" {
  vpc_id = aws_vpc.tf-vpc.id
  tags = {
    Name = "tf-igw"
  }
}


resource "aws_route_table" "tf-public-route-table" {
  vpc_id = aws_vpc.tf-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.tf-igw.id
  }

  tags = {
    Name = "tf-public-route-table"
  }
}


resource "aws_route_table" "tf-private-route-table" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "tf-private-route-table"
  }
}


resource "aws_route_table_association" "tf-private-rt-association" {
  count = var.subnet_count.private
  subnet_id = aws_subnet.tf-private-subnet[count.index].id
  route_table_id = aws_route_table.tf-private-route-table.id 
}


resource "aws_route_table_association" "tf-public-rt-association" {
  subnet_id      = aws_subnet.tf-public-subnet.id
  route_table_id = aws_route_table.tf-public-route-table.id 
}


resource "aws_security_group" "tf-ec2-sg" {
  name        = "tf-ec2-sg"
  description = "Security group for ec2 instance"
  vpc_id      = aws_vpc.tf-vpc.id

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
    Name = "tf-ec2-sg"
  }
}


resource "aws_security_group" "tf-rds-sg" {
  name        = "tf-rds-sg"
  description = "Security group for rds instance"
  vpc_id      = aws_vpc.tf-vpc.id

  ingress {
    description = "Allow rds traffic only for ec2 instance"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    security_groups = [aws_security_group.tf-ec2-sg.id]
  }
  
  tags = {
    Name = "tf-rds-sg"
  }
}


resource "aws_instance" "tf-ec2-instance" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  key_name = "test-key-pair"
  security_groups = [aws_security_group.tf-ec2-sg.id]

  tags = {
    Name = "tf-ec2-instance"
  }
  subnet_id = aws_subnet.tf-public-subnet.id
}


resource "aws_db_subnet_group" "tf-db-subnet-group" {
  name       = "tf-db-subnet-group"
  subnet_ids = [for subnet in aws_subnet.tf-private-subnet : subnet.id]

  tags = {
    Name = "tf-db-subnet-group"
  }
}


resource "aws_db_instance" "tf-rds" {
allocated_storage = 20
storage_type = "gp2"
engine = "postgres"
engine_version = "15.2"
instance_class = "db.t3.micro"
db_name = "linguistdb"
username = "datauser"
password = "datauser"
publicly_accessible = false
skip_final_snapshot = true
port = 5432
db_subnet_group_name = aws_db_subnet_group.tf-db-subnet-group.id
vpc_security_group_ids = [aws_security_group.tf-rds-sg.id]

  tags = {
    Name = "tf-rds"
  }
}
