output "instance_ids" {
  description = "Map of instance_name to EC2 instance ID."
  value       = { for name, i in aws_instance.pds_ec2 : name => i.id }
}

output "public_ips" {
  description = "Map of instance_name to public IP (empty string when none is assigned). Changes on stop/start unless an Elastic IP is attached."
  value       = { for name, i in aws_instance.pds_ec2 : name => i.public_ip }
}

output "private_ips" {
  description = "Map of instance_name to private IP."
  value       = { for name, i in aws_instance.pds_ec2 : name => i.private_ip }
}
