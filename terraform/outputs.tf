output "account_id" {
  value = local.aws_account_id
}

output "ec2_instance_ids" {
  value = module.mcp-instances.ec2_instance_id
}

output "security_group_ids" {
  value = module.custom_security_groups.security_group_id
}

output "pds_cognito_user_pool_id" {
  value = module.pds_cognito.pds_cognito_user_pool_id
}

output "pds_cognito_user_pool_client_id" {
  value = module.pds_cognito.pds_cognito_user_pool_client_id
}

output "pds_cognito_initial_users" {
  value = module.pds_cognito.pds_cognito_initial_users
}

output "module_iam_role_name" {
  description = "The name of the IAM roles created by the IAM module."
  value       = module.iam_roles.iam_role_name
}

output "module_iam_role_arn" {
  description = "The ARN of the IAM roles created by the IAM module."
  value       = module.iam_roles.iam_role_arn
}
