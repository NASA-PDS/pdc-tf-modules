output "bastion_instance_id" {
  description = "Instance ID of the bastion host."
  value       = module.ec2.ec2_instance_id[0]
}

output "bastion_eip" {
  description = "Elastic IP address of the bastion host. Null when assign_eip = false."
  value       = var.assign_eip ? aws_eip.bastion[0].public_ip : null
}

output "bastion_security_group_id" {
  description = "Security group ID of the bastion host."
  value       = aws_security_group.bastion.id
}

output "target_security_group_id" {
  description = "Security group ID to attach to private EC2s that should be reachable via this bastion. No hard-coded IPs — callers add this SG to vpc_security_group_ids on their private instances."
  value       = aws_security_group.target.id
}
