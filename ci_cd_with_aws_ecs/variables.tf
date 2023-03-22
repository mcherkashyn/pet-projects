variable "aws_region" {
        default = "us-east-1"
}

variable "subnet_count" {
        description = "Number of subnets"
        type = map(number)
        default = {
                public = 2
        }
}

variable "vpc_cidr_block" {
        description = "CIDR block for vpc"
        default = "172.20.0.0/16"
}

variable "public_subnet_cidr_blocks" {
        description = "CIDR blocks for public subnets"
        type = list(string)
        default = [
                "172.20.1.0/24",
                "172.20.2.0/24"
        ]
}

variable "private_subnet_cidr_blocks" {
        description = "CIDR blocks for private subnets"
        type = list(string)
        default = [
                "172.20.3.0/24",
                "172.20.4.0/24"
        ]
}

variable "settings" {
        description = "Configuration settings"
        type = map(any)
        default = {
                "ec2_instance" = {
                        count = 1
                        ami = "ami-0557a15b87f6559cf"
                        instance_type = "t2.micro"
                        key_name = "test-key-pair"
                }
        }
}

variable project_name {
  default = "github-action-ecr"
}

variable profile {
  default = "default"
}

variable ecr_image {
  default = "772320319753.dkr.ecr.us-east-1.amazonaws.com/github-action-ecr:1.0.0"
}

variable desired_count {
  default = 2
}