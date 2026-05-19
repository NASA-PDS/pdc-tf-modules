# create an S3 bucket using a variable for the name.
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
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

# Configure access logging. Requires a separate S3 bucket designated as the log target.
# Access logging should be enabled for security auditing and compliance.
# If intentionally disabled (logging_target_bucket = ""), document the reason at the call site.
resource "aws_s3_bucket_logging" "bucket_logging" {
  count         = var.logging_target_bucket != "" ? 1 : 0
  bucket        = aws_s3_bucket.bucket.id
  target_bucket = var.logging_target_bucket
  target_prefix = var.logging_target_prefix
}

# Configure lifecycle policy to abort incomplete multipart uploads
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle" {
  count  = var.abort_incomplete_multipart_upload_days > 0 ? 1 : 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    id     = "abort-incomplete-multipart-upload"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = var.abort_incomplete_multipart_upload_days
    }
  }
}
