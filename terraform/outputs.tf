output "account_id" {
  value = local.aws_account_id
}

output "ec2_instance_ids" {
  value = module.pds-ec2-instances.ec2_instance_id
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
  description = "The name of the IAM role created by the IAM module."
  value       = module.iam_roles.role_name
}

output "module_iam_role_arn" {
  description = "The ARN of the IAM role created by the IAM module."
  value       = module.iam_roles.role_arn
}

output "ecs_clusters" {
  description = "ECS Cluster ID"
  value       = module.ecs.ecs_cluster_id
}

output "ecs_task_definitions" {
  description = "ECS Task Definitions ARNS"
  value       = module.ecs.task_definition_arn
}

output "ecs_services" {
  description = "ECS Service Names"
  value       = module.ecs.ecs_service_name
}

output "s3_bucket_id" {
  description = "ID of the S3 bucket"
  value       = module.s3_bucket.bucket_name
}
output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = module.s3_bucket.bucket_arn
}

output "opensearch_serverless_collection_arn" {
  value = module.opensearch_serverless_collection.collection_arn
}

output "opensearch_serverless_endpoint" {
  value = module.opensearch_serverless_collection.collection_endpoint
}
