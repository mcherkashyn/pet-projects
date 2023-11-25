variable "aws_region" {
        default = "us-east-1"
}

variable "vpc_name" {
        description = "VPC name"
        default = ""
}

variable "vpc_cidr_block" {
        description = "CIDR block for vpc"
        default = "172.20.0.0/16"
}
