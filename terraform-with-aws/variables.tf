variable "access_key" {
        description = "Access key to AWS console"
}
variable "secret_key" {
        description = "Secret key to AWS console"
}

variable "subnet_count" {
        description = "Number of subnets"
        type = map(number)
        default = {
                public = 1,
                private = 2
        }
}

variable "private_subnet_cidr_blocks" {
        description = "CIDR blocks for private subnets"
        type = list(string)
        default = [
                "172.20.2.0/24",
                "172.20.3.0/24",
        ]
}