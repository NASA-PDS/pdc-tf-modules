output "instance_id" {
  description = "Instance ID of the test EC2."
  value       = module.ec2.ec2_instance_id[0]
}

output "fqdn" {
  description = "DNS name of the test EC2 in the shared hosted zone. SSH to this from the bastion."
  value       = aws_route53_record.test.fqdn
}
