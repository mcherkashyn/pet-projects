variable "aws_region" {
        default = "us-east-1"
}

variable "access_key" {
        type = string
}

variable "secret_key" {
        type = string
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

variable "settings" {
        description = "Configuration settings"
        type = map(any)
        default = {
                "ec2_instance" = {
                        ami = "ami-0557a15b87f6559cf"
                        instance_type = "t2.micro"
                        key_name = "test-key-pair"
                }
        }
}
