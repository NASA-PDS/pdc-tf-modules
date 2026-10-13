output "instance_id" {
  description = "Instance ID of the test EC2. Look up its private IP with: aws ec2 describe-instances --instance-ids <id> --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text"
  value       = module.ec2.ec2_instance_id[0]
}
