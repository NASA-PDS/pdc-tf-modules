# create an S3 bucket using a variable for the name.
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
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
