variable "bucket" {
  type = string
  description = "Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified."
}

variable "key" {
  type = string
  description = "Name of the object once it is in the bucket"
}

variable "source_path" {
  type = string
  description = "Path to a file that will be read and uploaded as raw bytes for the object content."
}

# variable "content_type" {
#   type = string
#   description = "The type of object you want to upload"
# }