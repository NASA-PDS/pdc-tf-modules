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
  description = "Bucket versioning status: Enabled or Disabled. Off by default; the caller opts in. Object Lock requires Enabled."
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.versioning)
    error_message = "versioning must be Enabled or Disabled."
  }
}

variable "object_lock_enabled" {
  description = <<-EOT
    Enable S3 Object Lock. Off by default; the caller opts in. Retention mode is
    always GOVERNANCE, for object_lock_days days.
    Works on new and existing buckets; versioning must be Enabled. Once on, it
    cannot be turned off, and false -> true is the only supported direction
    (true -> false forces bucket replacement in the AWS provider).
    Default retention applies to objects written after it is set.
  EOT
  type        = bool
  default     = false
}

variable "object_lock_days" {
  description = "Object Lock default retention in days. Used only when object_lock_enabled is true."
  type        = number
  default     = 90

  validation {
    condition     = var.object_lock_days >= 1
    error_message = "object_lock_days must be at least 1."
  }
}

variable "noncurrent_version_expiration_days" {
  description = <<-EOT
    Expire noncurrent object versions after this many days. Applies only when
    versioning is Enabled, so a versioned bucket never keeps old versions
    forever. Default 90. Set 0 to create no rule and keep every noncurrent
    version.
  EOT
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days >= 0
    error_message = "noncurrent_version_expiration_days must be 0 or greater."
  }
}

variable "newer_noncurrent_versions" {
  description = <<-EOT
    How many noncurrent versions to keep, in addition to the current version.
    Versions beyond that count are eligible for expiration once
    noncurrent_version_expiration_days has passed. Default 2. Used only when
    that variable is greater than 0.
    0 puts no count limit: every noncurrent version expires after
    noncurrent_version_expiration_days. Use 0 where each object key is written
    once (for example a log bucket), otherwise the single noncurrent version of
    each key is always inside the "keep 2" count and never expires.
  EOT
  type        = number
  default     = 2

  validation {
    condition     = var.newer_noncurrent_versions >= 0
    error_message = "newer_noncurrent_versions must be 0 or greater."
  }
}

variable "object_expiration_days" {
  description = <<-EOT
    Expire current objects after this many days. 0 (default) leaves current
    objects in place. Meant for log buckets; do not set it on buckets that hold
    data. Object Lock blocks deletion until retention ends, so a bucket that
    expires objects earlier than object_lock_days should leave
    object_lock_enabled false.
  EOT
  type        = number
  default     = 0

  validation {
    condition     = var.object_expiration_days >= 0
    error_message = "object_expiration_days must be 0 or greater."
  }
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
  description = <<-EOT
    S3 bucket that receives server access logs. When set, access logging is
    enabled. Leave empty to disable it, and document why at the call site.
    PDS tenant buckets set this to pds-<node>-logs-<venue>. The logs bucket
    itself must leave this empty and set object_expiration_days = 60.
  EOT
  type        = string
  default     = ""
}

variable "logging_target_prefix" {
  description = "Prefix for access log object keys within the logging target bucket."
  type        = string
  default     = "s3-access-logs/"
}

variable "logging_partition_date_source" {
  description = <<-EOT
    Partition server access log object keys by date. Empty (default) keeps the
    simple key format: <prefix><timestamp>-<id>. Set to "EventTime" or
    "DeliveryTime" to use S3 partitioned prefixes:
    <prefix><account-id>/<region>/<source-bucket>/YYYY/MM/DD/<timestamp>-<id>
    EventTime partitions by the date of the request. DeliveryTime partitions
    by the date S3 wrote the log object. Used only when logging_target_bucket
    is set.
  EOT
  type        = string
  default     = ""

  validation {
    condition     = contains(["", "EventTime", "DeliveryTime"], var.logging_partition_date_source)
    error_message = "logging_partition_date_source must be \"\", \"EventTime\" or \"DeliveryTime\"."
  }
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
