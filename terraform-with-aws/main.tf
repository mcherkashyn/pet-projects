provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region = "us-east-1"
}

resource "aws_vpc" "tf-vpc" {
  cidr_block = "172.30.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "tf-vpc"
  }
}

resource "aws_eip" "tf-eip" {
  instance = "${aws_instance.tf-instance.id}"
  vpc      = true
  tags = {
    Name = "tf-eip"
  }
}

resource "aws_subnet" "tf-subnet" {
  vpc_id            = aws_vpc.tf-vpc.id
  cidr_block        = "172.30.0.0/20"
  availability_zone = "us-east-1a"
  tags = {
    Name = "tf-subnet"
  }
}

resource "aws_internet_gateway" "tf-igw" {
  vpc_id = "${aws_vpc.tf-vpc.id}"
  tags = {
    Name = "tf-igw"
  }
}

resource "aws_route_table" "tf-route-table" {
  vpc_id = "${aws_vpc.tf-vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.tf-igw.id}"
  }
  tags = {
    Name = "tf-route-table"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.tf-subnet.id}"
  route_table_id = "${aws_route_table.tf-route-table.id}"
}

#resource "aws_network_interface" "foo" {
#  subnet_id   = aws_subnet.tf-subnet.id
#  private_ips = ["172.30.0.100"]
#  tags = {
#    Name = "terraform-network-interface"
#  }
#}

resource "aws_security_group" "tf-sg" {
  name        = "tf-sg"
  description = "Allow SSH traffic"
  vpc_id      = aws_vpc.tf-vpc.id

 # ingress {
 #   protocol  = -1
 #   self      = true
 #   from_port = 0
 #   to_port   = 0
 # }
  
  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-sg"
  }
}

resource "aws_instance" "tf-instance" {
  ami           = "ami-0557a15b87f6559cf"
  instance_type = "t2.micro"
  key_name = "test-key-pair"
  security_groups = ["${aws_security_group.tf-sg.id}"]

#network_interface {
#    network_interface_id = aws_network_interface.foo.id
#    device_index         = 0
#  }

  tags = {
    Name = "tf-instance"
  }
  subnet_id = "${aws_subnet.tf-subnet.id}"
}
