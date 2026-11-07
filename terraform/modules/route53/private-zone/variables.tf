variable "name" {
  description = <<-EOT
    DNS name of the private zone, for example internal.<your-public-zone>.
    Use a dedicated subdomain. A private zone with the same name as a public
    zone hides that whole public zone from the associated VPC: any public name
    not copied into the private zone returns NXDOMAIN from inside the VPC.
  EOT
  type        = string

  validation {
    condition     = can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?\\.)+[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "name must be a lowercase DNS name with at least two labels and no trailing dot."
  }
}

variable "vpc_id" {
  description = <<-EOT
    VPC the zone is associated with. Must be in the region of the AWS provider
    passed to the module, and must have DNS support and DNS hostnames enabled.
    Applies at creation only: changing it later does not move the association.
  EOT
  type        = string
}

variable "comment" {
  description = "Zone comment shown in the Route 53 console."
  type        = string
  default     = "Private hosted zone for internal service hostnames"
}

variable "force_destroy" {
  description = "Delete the zone even if it still contains records. Leave false so a destroy fails while consumers still have records in the zone."
  type        = bool
  default     = false
}

variable "publish_ssm_parameters" {
  description = "Publish the zone ID and name to SSM under ssm_prefix so consumers do not look the zone up by name."
  type        = bool
  default     = true
}

variable "ssm_prefix" {
  description = "SSM path prefix for the published parameters: <prefix>/id and <prefix>/name. Used only when publish_ssm_parameters is true."
  type        = string
  default     = "/pds/private-hosted-zone"

  validation {
    condition     = startswith(var.ssm_prefix, "/") && !endswith(var.ssm_prefix, "/")
    error_message = "ssm_prefix must start with / and must not end with /."
  }
}

variable "required_tags" {
  description = "Required resource tags (can be omitted if provider default_tags are configured)"
  type        = map(string)
  default     = {}
}
