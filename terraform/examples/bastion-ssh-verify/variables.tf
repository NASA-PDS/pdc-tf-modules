variable "aws_region" {
  type        = string
  description = "AWS region."
  default     = "us-west-2"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID to launch the test EC2 into."
}

variable "ami_id" {
  type        = string
  description = "SA-provided AMI ID for the target venue."
}

variable "instance_profile_name_ssm_path" {
  type        = string
  description = "SSM path to an existing EC2 instance profile name. The profile must allow dynamodb:GetItem/Query/Scan on the ec2-users table (SSH auth gate)."
}

variable "bastion_target_sg_ssm_path" {
  type        = string
  description = "SSM path to the bastion target SG ID (e.g. from pdc-cds-infra/bastion-core). Attaches the SG so the test EC2 accepts SSH from the bastion."
}

variable "required_tags" {
  type        = map(string)
  description = "Required resource tags."
  default     = {}
}
