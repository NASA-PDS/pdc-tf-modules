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

variable "project" {
  description = "Tag value for project. Abbreviated project name."
  type        = string
}

variable "tenant" {
  description = "Tag value for Tenant (e.g. en, img, atm)"
  type        = string
}

variable "venue" {
  description = "Tag value for Venue (e.g. pds-<node>-dev, pds-<node>-prod)"
  type        = string
}

variable "component" {
  description = "Tag value for application component (e.g. dum, nucleus, registry)"
  type        = string
}

variable "cicd" {
  description = "Tag value for CICD deployment method (e.g. manual, terraform)"
  type        = string
}

variable "managedby" {
  description = "Tag value for owner managing the resource (E.g. owner email address)"
  type        = string
}

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
  description = "Required resource tags"
  type        = map(string)
  default     = {}
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

variable "collection_type" {
  type        = string
  description = "Type of the serverless collection. Ex: SEARCH, TIMESERIES or VECTORSEARCH"
}

variable "collection_name" {
  description = "The name of the OpenSearch Serverless collection"
  type        = string
}

variable "encryption_policy_name" {
  type        = string
  description = "Name of the Security Encryption Policy"
}

variable "network_policy_name" {
  type        = string
  description = "Name of the Network Policy"
}

variable "data_access_policy_name" {
  type        = string
  description = "Name of the Data Access Policy"
}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
}

variable "s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
}
variable "partition" {
  type    = string
  default = "aws"
}

variable "config_file" {
  description = "Path for the environment-specific YAML task definition file"
  type        = string
}

variable "create_service" {
  description = "Flag to control where the ECS service should be created or not"
  type        = bool
  default     = true
}
