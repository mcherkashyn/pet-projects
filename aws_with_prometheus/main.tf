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


resource "aws_subnet" "tf_public_subnet" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[0]
  availability_zone = data.aws_availability_zones.available.names[0]
  tags = {
    Name = "tf_public_subnet"
    Terraform = "true"
  }
}


resource "aws_subnet" "tf_public_subnet_2" {
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[1]
  availability_zone = data.aws_availability_zones.available.names[1]
  tags = {
    Name = "tf_public_subnet_2"
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


resource "aws_route_table_association" "route_table_association_1" {
  subnet_id      = aws_subnet.tf_public_subnet.id
  route_table_id = aws_route_table.tf_public_route_table.id
}


resource "aws_route_table_association" "route_table_association_2" {
  subnet_id      = aws_subnet.tf_public_subnet_2.id
  route_table_id = aws_route_table.tf_public_route_table.id
}


resource "aws_security_group" "tf_monitoring_asg_sg" {
  name = "tf_monitoring_asg_sg"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.tf_monitoring_lb_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.tf_monitoring_lb_sg.id]
  }

  vpc_id = aws_vpc.tf_vpc.id
}


resource "aws_security_group" "tf_monitoring_lb_sg" {
  name = "tf_monitoring_lb_sg"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  vpc_id = aws_vpc.tf_vpc.id
}


resource "aws_launch_configuration" "tf_monitoring_lc" {
  name_prefix     = "tf_monitoring_lc"
  image_id        = var.settings.ec2_instance.ami
  instance_type   = var.settings.ec2_instance.instance_type
  user_data       = file("user_data.sh")
  security_groups = [aws_security_group.tf_monitoring_asg_sg.id]

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_autoscaling_group" "tf_monitoring_asg" {
  min_size             = 1
  max_size             = 3
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.tf_monitoring_lc.name
  vpc_zone_identifier  = [aws_subnet.tf_public_subnet.id, aws_subnet.tf_public_subnet_2.id]
}


resource "aws_lb" "tf_monitoring_lb" {
  name               = "tf-monitoring-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_monitoring_lb_sg.id]
  subnets            = [aws_subnet.tf_public_subnet.id, aws_subnet.tf_public_subnet_2.id]
}


resource "aws_lb_listener" "terramino" {
  load_balancer_arn = aws_lb.tf_monitoring_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_monitoring_lb_tg.arn
  }
}


resource "aws_lb_target_group" "tf_monitoring_lb_tg" {
   name     = "tf-monitoring-lb-tg"
   port     = 80
   protocol = "HTTP"
   vpc_id   = aws_vpc.tf_vpc.id
 }


resource "aws_autoscaling_attachment" "tf_monitoring_asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.tf_monitoring_asg.id
  lb_target_group_arn   = aws_lb_target_group.tf_monitoring_lb_tg.arn
}
