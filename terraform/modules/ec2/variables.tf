variable "ec2_instance_configs" {
  type        = list(any)
  default     = []
  description = "List of EC2 instances"
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
  default     = {}
}
