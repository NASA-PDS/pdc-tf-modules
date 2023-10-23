
module "custom_security_groups" {
  source = "./modules/security-groups"

  # vpc_id          = var.vpc_id
  security_groups = var.security_groups
  # required_tags = {
  #   Alfa    = var.node_name_abbr
  #   Bravo   = var.venue
  #   Charlie = var.component
  # }
}
