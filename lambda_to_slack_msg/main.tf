module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.2.0"

  function_name = var.lambda_function
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.10"
  source_path   = "./files/lambda_function.py"

  kms_key_arn   = module.kms.key_arn

  attach_policy_json = true
  policy_json = jsonencode({
  
      "Version": "2012-10-17",
      "Statement": [
        {
          "Sid": "AllowKmsKeyAccess",
          "Effect": "Allow",
          "Action": [
            "kms:Encrypt",
            "kms:Decrypt",
            "kms:ReEncrypt*",
            "kms:GenerateDataKey*",
            "kms:DescribeKey"
          ],
          "Resource": "*"
        }
      ]
    })

  layers = [module.lambda_layer_local.lambda_layer_arn]

  environment_variables = {
    SECRET_VALUE = data.aws_kms_ciphertext.my_ciphertext.ciphertext_blob
  }

  tags = {
    Terraform = "true"
    Name      = var.lambda_function
  }

  depends_on = [module.lambda_layer_local]
}


module "lambda_layer_local" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "6.2.0"

  create_layer        = true
  layer_name          = var.lambda_layer
  compatible_runtimes = ["python3.10"]
  source_path         = "./files/packages"

  tags = {
    Terraform = "true"
    Name      = var.lambda_layer
  }
}


module "kms" {
  source  = "terraform-aws-modules/kms/aws"
  version = "2.0.1"

  description             = var.kms_key
  deletion_window_in_days = 7
  enable_key_rotation     = true
  is_enabled              = true
  key_usage               = "ENCRYPT_DECRYPT"
  multi_region            = false

  # Policy
  enable_default_policy                  = false
  key_owners                             = [var.key_owner_arn]
  key_administrators                     = [var.key_owner_arn]
  key_users                              = [var.key_owner_arn]

  # Aliases
  aliases = [var.kms_key]

  # Grants
  grants = {
    lambda = {
      grantee_principal = module.lambda_function.lambda_role_arn
      operations        = ["Encrypt", "Decrypt", "GenerateDataKey"]
    }
  }

  tags = {
    Terraform = "true"
    Name      = var.kms_key
  }
}

data "aws_kms_ciphertext" "my_ciphertext" {
  key_id    = module.kms.key_id
  plaintext = data.aws_secretsmanager_secret_version.current.secret_string
}
