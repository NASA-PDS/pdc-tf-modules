output "ec2_instance_id" {
  value = aws_instance.mcp_ec2_instance[*].id
}
