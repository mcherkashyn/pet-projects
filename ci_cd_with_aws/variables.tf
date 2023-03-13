variable "access_key" {
        description = "Access key to AWS console"
}
variable "secret_key" {
       description = "Secret key to AWS console"
}

variable "aws_region" {
        default = "us-east-1"
}

variable "subnet_count" {
        description = "Number of subnets"
        type = map(number)
        default = {
                public = 1,
        }
}

variable "vpc_cidr_block" {
        description = "CIDR block for vpc"
        default = "172.20.0.0/16"
}

variable "public_subnet_cidr_block" {
        description = "CIDR blocks for public subnets"
        type = list(string)
        default = [
                "172.20.1.0/24",
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
