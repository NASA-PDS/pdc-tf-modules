variable "ec2_instance_configs" {
  type        = list(any)
  default     = []
  description = "List of EC2 instances"
}
variable "security_groups" {
  description = "List of security grousp"
  type        = list(any)
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "node_name_abbr" {
  description = "Tag value for Alfa. Abbreviated node name."
  type        = string
}

variable "venue" {
  description = "Tag value for Beta"
  type        = string
}

variable "component" {
  description = "Tag value for Charlie"
  type        = string
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}
