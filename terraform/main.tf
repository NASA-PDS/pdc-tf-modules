
module "mcp-instances" {
  source = "./modules/ec2"

  ec2_instance_configs = var.ec2_instance_configs
  required_tags = {
    Alfa    = var.node_name_abbr
    Bravo   = var.venue
    Charlie = var.component
  }
}
module "custom_security_groups" {
  source = "./modules/security-groups"

  vpc_id          = var.vpc_id
  security_groups = var.security_groups
  required_tags = {
    Alfa    = var.node_name_abbr
    Bravo   = var.venue
    Charlie = var.component
  }
}

module "pds_cognito" {
  source = "./modules/cognito"

  pds_cognito_initial_users = var.pds_cognito_initial_users
  pds_welcome_page_client_id = var.pds_welcome_page_client_id
}

module "s3_bucket" {
  source = "./modules/s3/bucket"
  bucket_name = var.test_bucket
  partition = var.partition
  bucket_policy = <<POLICY
 {
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Deny",
             "Principal": {
                 "AWS": "*"
             },
             "Action": "s3:*",
             "Resource": [
                 "arn:${var.partition}:s3:::${var.test_bucket}/*",
                 "arn:${var.partition}:s3:::${var.test_bucket}"
             ]
         }
     ]
 }
 POLICY
  enable_blocks = true
  enable_policy = true
}
