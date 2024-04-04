output "iam_role_name" {
  description = "Name of the IAM Role"
  value       = { for iam_role_name, role in aws_iam_role.iam_role : role.name => role.name }
}

output "iam_role_arn" {
  description = "ARN of the IAM Role"
  value       = { for iam_role_name, role in aws_iam_role.iam_role : role.name => role.arn }
}
