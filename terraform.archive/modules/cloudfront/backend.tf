terraform {
  backend "s3" {
    bucket = "<S3 Bucket Name>"
    key    = "dev/couldfront_infra.tfstate"
    region = "us-west-2"
  }
}
