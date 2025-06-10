output "s3_object_key" {
  description = "The key of the S3 object"
  value       = aws_s3_object.object.key
}

output "s3_object_bucket" {
  description = "The name of the S3 bucket"
  value       = aws_s3_object.object.bucket
}

output "s3_oject_source" {
  description = "Source path of the S3 object"
  value       = var.source_path
}
