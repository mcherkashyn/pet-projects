data "aws_secretsmanager_secret" "my_secret" {
  arn = var.secret_arn
}

data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.my_secret.id
}
