resource "aws_ssm_parameter" "ec2_instance_role_arn" {
  name        = "/pds/${var.component}/iam/roles/ec2/instance-role-arn"
  type        = "String"
  value       = aws_iam_role.ec2.arn
  description = "ARN of the ${var.component} EC2 instance IAM role"
  tags        = var.required_tags
}

resource "aws_ssm_parameter" "ec2_instance_profile_name" {
  name        = "/pds/${var.component}/iam/roles/ec2/instance-profile-name"
  type        = "String"
  value       = aws_iam_instance_profile.ec2.name
  description = "Name of the ${var.component} EC2 instance profile"
  tags        = var.required_tags
}

output "role_arn" {
  description = "ARN of the EC2 instance IAM role."
  value       = aws_iam_role.ec2.arn
}

output "instance_profile_name" {
  description = "Name of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.name
}

output "instance_profile_arn" {
  description = "ARN of the EC2 instance profile."
  value       = aws_iam_instance_profile.ec2.arn
}
