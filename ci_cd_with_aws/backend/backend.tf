provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "tfbackend464"
  force_destroy = true
  versioning {
    enabled = true
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
