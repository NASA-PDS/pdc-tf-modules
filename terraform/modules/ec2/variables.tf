variable "ec2_instance_configs" {
  type        = list(any)
  default     = []
  description = "List of EC2 instances. Each entry supports optional root_volume_size (GB, default 50) and root_volume_type (default \"gp3\") to size the root EBS volume."
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate a public IP address for all EC2 instances created by this module."
}

variable "instance_profile" {
  type        = string
  default     = ""
  description = "EC2 instance profile name"
}

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instances. Must be the exact SA-provided AMI ID for the target venue."
}

variable "pds_resource_prefix" {
  type        = string
  default     = ""
  description = "Optional prefix for resource naming (e.g., pds-<venue>-<component>)"
}

variable "bastion_target_sg_ssm_path" {
  type        = string
  default     = ""
  description = "SSM parameter path for the bastion target security group ID (e.g. /pds/<component>/bastion-core/target-security-group-id). When set, the SG is automatically appended to every instance's security groups, enabling SSH access from the bastion. Leave empty to skip (e.g. for the bastion EC2 itself)."
}

variable "disable_api_termination" {
  type        = bool
  default     = true
  description = "Enable EC2 termination protection. Prevents accidental deletion via the AWS console or API. Terraform's destroy command disables this automatically before terminating. Default true."
}

variable "root_volume_delete_on_termination" {
  type        = bool
  default     = false
  description = "Delete the root EBS volume when the instance terminates."
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
  default     = {}
}
