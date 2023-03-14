provider "aws" {
  region = var.aws_region
}


resource "aws_s3_bucket" "terraform_state" {
  bucket = var.bucket_name
  versioning {
    enabled = true
  }
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
