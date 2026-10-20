variable "ec2_instance_configs" {
  type = list(object({
    instance_name                   = string
    instance_type                   = string
    subnet_id                       = string
    security_groups                 = list(string)
    key_pair_name                   = optional(string)
    user_data                       = optional(string)
    az                              = optional(string)
    root_volume_size                = optional(number, 50)
    root_volume_type                = optional(string, "gp3")
    ignore_instance_profile_changes = optional(bool, false)
  }))
  default     = []
  description = "List of EC2 instances to create. instance_name must be unique; it is the key of the module outputs and is combined with pds_resource_prefix for the Name tag. user_data must already be base64-encoded (e.g. base64encode(templatefile(...))). root_volume_size is in GB (default 50) and root_volume_type defaults to gp3. Set ignore_instance_profile_changes = true for an instance whose IAM instance profile is swapped outside Terraform after boot, so later applies do not revert it (default false)."

  validation {
    condition     = length(distinct([for c in var.ec2_instance_configs : c.instance_name])) == length(var.ec2_instance_configs)
    error_message = "instance_name must be unique across ec2_instance_configs."
  }

  validation {
    condition     = alltrue([for c in var.ec2_instance_configs : length(c.security_groups) > 0])
    error_message = "Each ec2_instance_configs entry needs at least one security group."
  }
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate a public IP address for all EC2 instances created by this module."
}

variable "instance_profile" {
  type        = string
  default     = ""
  description = "Name of an existing EC2 instance profile to attach. Empty attaches none."
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
