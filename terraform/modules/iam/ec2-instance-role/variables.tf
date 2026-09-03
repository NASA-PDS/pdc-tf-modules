variable "venue" {
  type        = string
  description = "Deployment venue/environment (e.g. pds-cds-dev). Used in resource naming."
}

variable "component" {
  type        = string
  description = "Component name (e.g. o11y-cloudfront-batch). Combined with venue to form the role name: <venue>-<component>-ec2-role."
}

variable "permissions_boundary_arn" {
  type        = string
  description = "ARN of the permissions boundary policy to attach to the IAM role."
}

variable "additional_policy_arns" {
  type        = list(string)
  default     = []
  description = "Additional managed policy ARNs to attach beyond AmazonSSMManagedInstanceCore and CloudWatchAgentServerPolicy."
}

variable "required_tags" {
  type        = map(string)
  default     = {}
  description = "Resource tags (tenant, venue, component, cicd, managedby)."
}
