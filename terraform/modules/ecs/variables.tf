variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "config_file" {
  description = "Path to the environment-specific YAML file (eg: dev.yaml, prod.yaml)"
  type        = string
}

variable "create_service" {
  description = "Flag to control where the ECS service should be created or not"
  type        = bool
  default     = true
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
}
