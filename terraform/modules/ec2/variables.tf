variable "ec2_instance_configs" {
  type        = list(any)
  default     = []
  description = "List of EC2 instances"
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
  default     = ""
  description = "Explicit AMI ID. When set, skips the Oracle Linux 9 auto-detection lookup. Use when a pre-provisioned or component-specific AMI is required."
}

variable "pds_resource_prefix" {
  type        = string
  default     = ""
  description = "Optional prefix for resource naming (e.g., pds-dev-gh01dc)"
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
  default     = {}
}
