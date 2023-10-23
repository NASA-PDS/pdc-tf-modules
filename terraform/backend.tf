terraform {
  backend "s3" {
    bucket = "pds-infra"
    key    = "dev/en_infra.tfstate"
    region = "us-west-2"
  }
}
