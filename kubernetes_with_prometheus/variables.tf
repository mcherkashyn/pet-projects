variable "aws_region" {
        default = "us-east-1"
}

variable "vpc_cidr_block" {
        description = "CIDR block for vpc"
        default = "172.20.0.0/16"
}

variable "subnet_count" {
        description = "Number of subnets"
        type = map(number)
        default = {
                public = 2,
        }
}

variable "public_subnet_cidr_blocks" {
        description = "CIDR blocks for public subnets"
        type = list(string)
        default = [
                "172.20.1.0/24",
                "172.20.2.0/24"
        ]
}

variable project_name {
  default = "eks-prometheus"
}
