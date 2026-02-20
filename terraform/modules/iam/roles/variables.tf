variable "role_name" {
  description = "Name of the IAM role"
  type        = string
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = ""
}

variable "assume_role_policy" {
  description = "Trust relationship policy document (will be JSON-encoded by the module)"
  type        = any
}

variable "permissions_boundary_policy_name" {
  description = "Name of the permissions boundary policy"
  type        = string
  default     = "mcp-tenantOperator-APIG"
}

variable "custom_policies" {
  description = "Map of custom IAM policies to create and attach. Key is the policy name."
  type = map(object({
    description     = string
    policy_document = any
  }))
  default = {}
}

variable "custom_policy_arns" {
  description = "List of existing IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "managed_policy_arns" {
  description = "List of AWS managed policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for t in ["tenant", "venue", "component", "cicd", "managedby"] : contains(keys(var.required_tags), t)])
    error_message = "The required_tags map must contain the following keys: tenant, venue, component, cicd, managedby."
  }
}
