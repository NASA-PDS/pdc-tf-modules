
module "pds-ec2-instances" {
  source = "./modules/ec2"

  ec2_instance_configs        = var.ec2_instance_configs
  associate_public_ip_address = var.associate_public_ip_address
  ami_id                      = var.ami_id
  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
module "custom_security_groups" {
  source = "./modules/security-groups"

  vpc_id          = var.vpc_id
  security_groups = var.security_groups
  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "pds_cognito" {
  source = "./modules/cognito"

  pds_cognito_initial_users  = var.pds_cognito_initial_users
  pds_welcome_page_client_id = var.pds_welcome_page_client_id
  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
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
             "Sid": "AllowSSLRequestsOnly",
             "Effect": "Deny",
             "Principal": "*",
             "Action": "s3:*",
             "Resource": [
                "arn:${var.partition}:s3:::${var.s3_bucket_name}",
                "arn:${var.partition}:s3:::${var.s3_bucket_name}/*"
              ],
              "Condition": {
                "Bool": {
                   "aws:SecureTransport": "false"
                 }
             }
         }
     ]
  }
  POLICY
  enable_blocks = true
  enable_policy = true

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "iam_roles" {
  source = "./modules/iam/roles"

  role_name          = var.iam_role_name
  role_description   = var.iam_role_description
  assume_role_policy = var.iam_assume_role_policy

  custom_policies     = var.iam_custom_policies
  custom_policy_arns  = var.iam_custom_policy_arns
  managed_policy_arns = var.iam_managed_policy_arns

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "opensearch_serverless_collection" {
  source = "./modules/opensearch-serverless"

  collection_name         = var.collection_name
  encryption_policy_name  = var.encryption_policy_name
  network_policy_name     = var.network_policy_name
  data_access_policy_name = var.data_access_policy_name
  collection_type         = var.collection_type
  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "ecs" {
  source         = "./modules/ecs"
  config_file    = var.config_file
  create_service = var.create_service
  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

