
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

module "iam_roles" {
  source              = "./modules/iam"
  iam_role_preffix    = var.iam_role_preffix
  permission_boundary = var.permission_boundary
  policy_file_path    = var.policy_file_path
  required_tags = {
    Alfa    = var.node_name_abbr
    Beta    = var.venue
    Charlie = var.component
  }
}

