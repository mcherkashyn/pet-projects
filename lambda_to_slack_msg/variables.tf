variable "aws_region" {
        default = "us-east-1"
}

variable "lambda_function" {
        description = "Lambda function name"
        default = "tf_lambda"
}

variable "lambda_layer" {
        description = "Lambda layer name"
        default = "tf_lambda_layer"
}

variable "kms_key" {
        description = "KMS key name"
        default = "tf_kms_key"
}

variable "key_owner_arn" {
        description = "Key owner ARN"
        default = ""
}

variable "secret_arn" {
        description = "Secret ARN"
        default = ""
}
