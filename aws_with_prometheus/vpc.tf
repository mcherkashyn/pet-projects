module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name                   = var.vpc_name
  cidr                   = var.cidr
  azs                    = var.azs
  public_subnets         = var.public_subnets
  private_subnets        = var.private_subnets
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  tags = {
    Name = "tf_resource"
    Terraform = "true"
  }

  public_subnet_tags = {
    Name = "tf_public_subnet"
  }

  private_subnet_tags = {
    Name = "tf_private_subnet"
  }
}
