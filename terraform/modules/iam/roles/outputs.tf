output "role_arn" {
  description = "ARN of the created IAM role"
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the created IAM role"
  value       = aws_iam_role.this.name
}

output "custom_policy_arns" {
  description = "Map of custom policy names to their ARNs"
  value       = { for name, policy in aws_iam_policy.this : name => policy.arn }
}
