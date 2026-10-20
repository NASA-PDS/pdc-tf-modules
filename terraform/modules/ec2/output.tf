output "ec2_instance_id" {
  value = aws_instance.pds_ec2[*].id
}

output "ec2_public_ip" {
  description = "Public IP of each instance (empty string when none is assigned). Changes on stop/start unless an Elastic IP is attached."
  value       = aws_instance.pds_ec2[*].public_ip
}

output "ec2_private_ip" {
  description = "Private IP of each instance."
  value       = aws_instance.pds_ec2[*].private_ip
}
