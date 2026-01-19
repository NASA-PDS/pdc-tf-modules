
variable "bucket_name" {
  type = string
}

variable "partition" {
  type    = string
  default = "aws"
}

variable "bucket_policy" {
  type    = string
  default = ""
}

variable "sse_algorithm" {
  type    = string
  default = "AES256"
}

variable "block_public_acls" {
  type    = bool
  default = true
}

variable "block_public_policy" {
  type    = bool
  default = true
}

variable "ignore_public_acls" {
  type    = bool
  default = true
}

variable "restrict_public_buckets" {
  type    = bool
  default = true
}

variable "enable_blocks" {
  description = "This toggles if the public access restrictions are applied.Some venues have this enforced at a higher level. That is the only time this should false. (MCP is an example venue)"
  type        = bool
  default     = true
}

variable "enable_policy" {
  description = "This toggles if the public access policy is created.Some venues have this enforced at a higher level. That is the only time this should false. (MCP is an example venue)"
  type        = bool
  default     = true
}

variable "versioning" {
  description = "Whether bucket versioning should be enabled or disabled"
  type        = string
  default     = "Disabled"
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

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which incomplete multipart uploads will be aborted. Set to 0 to disable this lifecycle rule."
  type        = number
  default     = 7
}
