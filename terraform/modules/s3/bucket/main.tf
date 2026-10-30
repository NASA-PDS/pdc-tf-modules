# create an S3 bucket using a variable for the name.
# Object Lock can be enabled on new and existing buckets (versioning must be Enabled).
# It cannot be disabled afterward; true -> false forces bucket replacement.
resource "aws_s3_bucket" "bucket" {
  bucket              = var.bucket_name
  object_lock_enabled = var.object_lock_enabled ? true : null
  tags                = var.required_tags

  lifecycle {
    precondition {
      condition     = !var.object_lock_enabled || var.versioning == "Enabled"
      error_message = "Object Lock requires versioning = \"Enabled\"."
    }
  }
}

# Disable ACLs by setting ownership controls to BucketOwnerEnforced
# Recommended security practice for new S3 buckets
resource "aws_s3_bucket_ownership_controls" "bucket_ownership" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# configure server-side encryption with the algorithm specified in "sse_algorithm"
resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-encryption" {
  bucket = aws_s3_bucket.bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = var.sse_algorithm
    }
  }
}

# This conditionally creates public access blocks, controlled by the "enable_blocks" variable.
resource "aws_s3_bucket_public_access_block" "bucket_blocks" {
  count                   = var.enable_blocks ? 1 : 0
  bucket                  = aws_s3_bucket.bucket.id
  block_public_acls       = var.block_public_acls
  block_public_policy     = var.block_public_policy
  ignore_public_acls      = var.ignore_public_acls
  restrict_public_buckets = var.restrict_public_buckets
}

# apply a bucket policy, with the policy defined in "bucket_policy" variable.
resource "aws_s3_bucket_policy" "bucket_policy" {
  count  = var.enable_policy ? 1 : 0
  bucket = aws_s3_bucket.bucket.id
  policy = var.bucket_policy
}

# Configure versioning, with the state controlled by "versioning" variable.
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.bucket.id
  versioning_configuration {
    status = var.versioning
  }
}

# Default retention for new objects. Governance mode allows a privileged
# principal to bypass the lock. Existing objects are not locked retroactively.
resource "aws_s3_bucket_object_lock_configuration" "bucket_object_lock" {
  count  = var.object_lock_enabled ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    default_retention {
      mode = "GOVERNANCE"
      days = var.object_lock_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.bucket_versioning]
}

# Configure access logging. Requires a separate S3 bucket designated as the log target.
# Access logging should be enabled for security auditing and compliance.
# If intentionally disabled (logging_target_bucket = ""), document the reason at the call site.
resource "aws_s3_bucket_logging" "bucket_logging" {
  count         = var.logging_target_bucket != "" ? 1 : 0
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix

  # Optional date partitioning: <prefix><account>/<region>/<bucket>/YYYY/MM/DD/...
  dynamic "target_object_key_format" {
    for_each = var.logging_partition_date_source != "" ? [1] : []
    content {
      partitioned_prefix {
        partition_date_source = var.logging_partition_date_source
      }
    }
  }
}

locals {
  storage_class_normalized        = upper(var.storage_class)
  enable_storage_class_transition = !contains(["STANDARD"], local.storage_class_normalized)
  enable_noncurrent_expiration    = var.versioning == "Enabled" && var.noncurrent_version_expiration_days > 0
  enable_object_expiration        = var.object_expiration_days > 0
  enable_lifecycle = (
    var.abort_incomplete_multipart_upload_days > 0 ||
    local.enable_storage_class_transition ||
    local.enable_noncurrent_expiration ||
    local.enable_object_expiration
  )
}

# Lifecycle: abort incomplete multipart uploads and/or transition to a storage class.
# STANDARD means no transition (objects remain in the default S3 Standard class).
# Other classes (e.g. INTELLIGENT_TIERING) are applied via lifecycle transition.
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  count  = local.enable_lifecycle ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  depends_on = [aws_s3_bucket_versioning.bucket_versioning]

  dynamic "rule" {
    for_each = var.abort_incomplete_multipart_upload_days > 0 ? [1] : []
    content {
      id     = "abort-incomplete-multipart-upload"
      status = "Enabled"
      filter {}

      abort_incomplete_multipart_upload {
        days_after_initiation = var.abort_incomplete_multipart_upload_days
      }
    }
  }

  dynamic "rule" {
    for_each = local.enable_storage_class_transition ? [1] : []
    content {
      id     = "transition-to-${lower(replace(local.storage_class_normalized, "_", "-"))}"
      status = "Enabled"
      filter {}

      transition {
        days          = var.storage_class_transition_days
        storage_class = local.storage_class_normalized
      }
    }
  }

  # Keeps the current version. Expires noncurrent versions past the retention
  # count once they are older than noncurrent_version_expiration_days.
  # newer_noncurrent_versions = 0 drops the cap and expires every old version.
  dynamic "rule" {
    for_each = local.enable_noncurrent_expiration ? [1] : []
    content {
      id     = "expire-old-noncurrent-versions"
      status = "Enabled"
      filter {}

      noncurrent_version_expiration {
        noncurrent_days           = var.noncurrent_version_expiration_days
        newer_noncurrent_versions = var.newer_noncurrent_versions > 0 ? var.newer_noncurrent_versions : null
      }
    }
  }

  # Current-object expiration. Used by the access-log bucket (60 days).
  # Left off for data buckets so archive objects are not deleted.
  dynamic "rule" {
    for_each = local.enable_object_expiration ? [1] : []
    content {
      id     = "expire-current-objects"
      status = "Enabled"
      filter {}

      expiration {
        days = var.object_expiration_days
      }
    }
  }
}
