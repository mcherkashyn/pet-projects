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
  count = var.subnet_count.public
  vpc_id            = aws_vpc.tf_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
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


resource "aws_route_table_association" "route_table_association" {
  count = var.subnet_count.public
  subnet_id      = aws_subnet.tf_public_subnet[count.index].id
  route_table_id = aws_route_table.tf_public_route_table.id
}


resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb"
  description = "inbound: 80,443 + outbound: all"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "eks_sg" {
  name        = "${var.project_name}-eks"
  description = "inbound: 80 from ALB security group + outbound: all"
  vpc_id      = aws_vpc.tf_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_alb" "alb" {
  name               = var.project_name
  load_balancer_type = "application"
  subnets            = [for subnet in aws_subnet.tf_public_subnet : subnet.id]
  security_groups    = [aws_security_group.alb.id]

  tags = {
    Name = var.project_name
  }
}


resource "aws_alb_target_group" "alb_target_group" {
  name        = var.project_name
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.tf_vpc.id
  target_type = "ip"
}


resource "aws_alb_listener" "alb_listener" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.alb_target_group.arn
    type             = "forward"
  }
}


resource "aws_ecr_repository" "ecr_repository" {
  name                 = var.project_name
  image_tag_mutability = "MUTABLE"
  force_delete = true
}


data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role" "eks_iam_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
}


resource "aws_iam_role_policy_attachment" "tf-eks-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_iam_role.name
}


/*
data "aws_iam_policy_document" "ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role_policy.json
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_attachment" {
  role = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
*/


resource "aws_eks_cluster" "tf-eks-cluster" {
  name     = "tf-eks-cluster"
  role_arn = aws_iam_role.eks_iam_role.arn

  vpc_config {
    subnet_ids = [for subnet in aws_subnet.tf_public_subnet : subnet.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.tf-eks-AmazonEKSClusterPolicy,
  ]
}

