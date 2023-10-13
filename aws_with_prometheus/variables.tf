variable "aws_region" {
        default = "us-east-1"
}

variable "access_key" {
        type = string
}

variable "secret_key" {
        type = string
}

variable "vpc_name" {
        description = "VPC name"
        default = "tf_vpc"
}

variable "cidr" {
        description = "CIDR for VPC"
        default = "10.0.0.0/16"
}

variable "azs" {
        description = "Availability Zones"
        default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "public_subnets" {
        description = "CIDR blocks for public subnets"
        default     = ["10.0.101.0/24"]
}

#,, "10.0.102.0/24" "10.0.103.0/24"

variable "private_subnets" {
        description = "CIDR blocks for private subnets"
        default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

#, "10.0.2.0/24", "10.0.3.0/24"

variable "master_ec2" {
        description = "Master EC2 instance name"
        default = "tf_master_ec2"
}

variable "slave_asg" {
        description = "Slave EC2 instances name"
        default = "tf_slave_ec2"
}

variable "instance_type" {
        description = "EC2 instance type"
        default = "t2.micro"
}

variable "ami" {
        description = "EC2 AMI"
        default = "ami-0557a15b87f6559cf"
}

variable "sg" {
        description = "Security group name"
        default = "tf_sg"
}

variable "lt" {
        description = "Autoscaling group launch template name"
        default = "tf_slave_lt"
}
