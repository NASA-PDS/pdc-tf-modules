
module "mcp-instances" {
  source = "./modules/ec2"

  ec2_instance_configs = var.ec2_instance_configs
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}
module "custom_security_groups" {
  source = "./modules/security-groups"

  vpc_id          = var.vpc_id
  security_groups = var.security_groups
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

module "pds_cognito" {
  source = "./modules/cognito"

  pds_cognito_initial_users  = var.pds_cognito_initial_users
  pds_welcome_page_client_id = var.pds_welcome_page_client_id
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

module "s3_bucket" {
  source        = "./modules/s3/bucket"
  bucket_name   = var.s3_bucket_name
  partition     = var.partition
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
                 "arn:${var.partition}:s3:::${var.s3_bucket_name}/*",
                 "arn:${var.partition}:s3:::${var.s3_bucket_name}"
             ]
         }
     ]
 }
 POLICY
  enable_blocks = true
  enable_policy = true

  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

module "iam_roles" {
  source              = "./modules/iam"
  iam_role_preffix    = var.iam_role_preffix
  permission_boundary = var.permission_boundary
  policy_file_path    = var.policy_file_path
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

module "openserach_serverless_collection" {
  source = "./modules/opensearch_serverless"

  venue           = var.venue
  collection_type = var.colleciton_type
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

module "ecs" {
  source         = "./modules/ecs"
  config_file    = var.config_file
  create_service = var.create_service
  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}

