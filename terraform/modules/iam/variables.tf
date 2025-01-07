# variables
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

variable "required_tags" {
  type        = map(string)
  description = "Node, Venue and Component values for PDS application"
  default     = {}
}

locals {
  policy_data = yamldecode(file(var.policy_file_path))["iam_roles"]
  policies_flat = flatten([
    for role in local.policy_data : [
      for policy in try(role.custom_policies, []) : {
        iam_role_name       = role.iam_role_name
        iam_policy_name     = policy.iam_policy_name
        iam_policy_document = policy.iam_policy_document
      } if policy != null && policy != "" # Ensures that only non-null and non-empty policies are included. Making new IAM custom policies optional.
    ]
  ])
  custom_policy_attachments = flatten([
    for role in local.policy_data : [
      for custom_policy in try(role.custom_policy_arns, []) : {
        iam_role_name     = role.iam_role_name
        custom_policy_arn = custom_policy
      } if custom_policy != null && custom_policy != "" # Ensures that only non-null and non-empty ARNs are included. Making custom policy ARNs optional.
    ]
  ])
  managed_policy_attachments = flatten([
    for role in local.policy_data : [
      for managed_policy in try(role.managed_policy_arns, []) : {
        iam_role_name      = role.iam_role_name
        managed_policy_arn = managed_policy
      } if managed_policy != null && managed_policy != "" # Ensures that only non-null and non-empty ARNs are included. Making managed policy ARNs optional.
    ]
  ])
}
