provider "aws" {
  region = var.aws_region
}


resource "aws_vpc" "tf_vpc" {
  cidr_block = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = var.vpc_name
    Terraform = "true"
  }
}
