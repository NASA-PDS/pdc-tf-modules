terraform {
  backend "s3" {
    bucket = "pds-infra"
    key    = "dev/couldfront_infra.tfstate"
    region = "us-west-2"
  }
}
