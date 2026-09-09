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
  description = "Required resource tags (can be omitted if provider default_tags are configured)"
  type        = map(string)
  default     = {}
}

variable "abort_incomplete_multipart_upload_days" {
  description = "Number of days after which incomplete multipart uploads will be aborted. Set to 0 to disable this lifecycle rule."
  type        = number
  default     = 7
}

variable "logging_target_bucket" {
  description = "S3 bucket to deliver access logs to. When set, access logging is enabled. Leave empty to disable access logging (must be documented in calling module if intentionally disabled)."
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access log object keys within the logging target bucket."
  type        = string
  default     = "s3-access-logs/"
}

variable "storage_class" {
  description = <<-EOT
    Desired object storage class managed via lifecycle transition.
    STANDARD = no transition (objects stay in S3 Standard).
    Other values create a lifecycle rule transitioning objects after
    storage_class_transition_days (default 0).
  EOT
  type        = string
  default     = "INTELLIGENT_TIERING"

  validation {
    condition = contains(
      [
        "STANDARD",
        "INTELLIGENT_TIERING",
        "STANDARD_IA",
        "ONEZONE_IA",
        "GLACIER_IR",
        "GLACIER",
        "DEEP_ARCHIVE",
      ],
      upper(var.storage_class)
    )
    error_message = "storage_class must be one of: STANDARD, INTELLIGENT_TIERING, STANDARD_IA, ONEZONE_IA, GLACIER_IR, GLACIER, DEEP_ARCHIVE."
  }
}

variable "storage_class_transition_days" {
  description = "Days after object creation before transitioning to storage_class. Ignored when storage_class is STANDARD."
  type        = number
  default     = 0
}
