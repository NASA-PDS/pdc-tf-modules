resource "aws_s3_object" "object" {
  bucket       = var.bucket
  key          = var.key
  source       = var.source_path
  etag         = filemd5(var.source_path)
  # content_type = "text/plain"
}