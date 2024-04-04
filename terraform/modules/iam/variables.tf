
variable "policy_file_path" {
  type        = string
  description = "Path to the YAML containing IAM policy and trust relationships"
  default     = ""
}

variable "iam_role_preffix" {
  type        = string
  description = "IAM role Preffix"
}

variable "permission_boundary" {
  type        = string
  description = "ARN of the permission boundary policy to attach to the IAM role"
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "Node, Venue and Component values for PDS application"
  default     = {}
}

locals {
  policy_data = yamldecode(file(var.policy_file_path))["iam_roles"]
  policies_flat = flatten([
    for role in local.policy_data : [
      for policy in role.policies : {
        iam_role_name       = role.iam_role_name
        iam_policy_name     = policy.iam_policy_name
        iam_policy_document = policy.iam_policy_document
      }
    ]
  ])
}
