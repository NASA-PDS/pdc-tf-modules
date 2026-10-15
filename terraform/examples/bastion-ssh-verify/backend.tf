terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    key = "tests/bastion-ssh-verify.tfstate"
    # bucket, region, dynamodb_table provided via -backend-config at init time.
  }
}
