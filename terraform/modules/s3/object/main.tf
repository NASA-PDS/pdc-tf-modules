resource "aws_s3_object" "object" {
  bucket       = var.bucket
  key          = var.key
  source       = var.source_path
  etag         = try(filemd5(var.source_path), null)
  # content_type = "text/plain"
}
