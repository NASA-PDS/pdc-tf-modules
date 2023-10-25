output "account_id" {
  value = local.aws_account_id
}

output "ec2_instance_ids" {
  value = module.mcp-instances.ec2_instance_id
}

output "security_group_ids" {
  value = module.custom_security_groups.security_group_id
}
