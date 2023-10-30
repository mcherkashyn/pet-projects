output "lambda_function_arn" {
  value       = module.lambda_function.lambda_function_arn
}

output "lambda_function_name" {
  value       = module.lambda_function.lambda_function_name
}

output "lambda_role_arn" {
  value       = module.lambda_function.lambda_role_arn
}

output "lambda_role_name" {
  value       = module.lambda_function.lambda_role_name
}

output "lambda_layer_arn" {
  value       = module.lambda_layer_local.lambda_layer_arn
}

output "lambda_layer_version" {
  value       = module.lambda_layer_local.lambda_layer_version
}

output "kms_key_id" {
  value       = module.kms.key_id
}
