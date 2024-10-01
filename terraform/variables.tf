variable "ec2_instance_configs" {
  type        = list(any)
  default     = []
  description = "List of EC2 instances"
}
variable "security_groups" {
  description = "List of security groups"
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

variable "pds_cognito_initial_users" {
  type = list(
    object(
      {
        username = string
        password = string
        group    = string
        email    = string
      }
    )
  )
  description = "List of Cognito users to pre-populate the User Pool with"
}

variable "pds_welcome_page_client_id" {
  type        = string
  description = "PDS Welcome page client ID"
  default     = "[PDS Welcome page client ID]"
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}
