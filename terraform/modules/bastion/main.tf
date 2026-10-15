# ──────────────────────────────────────────────────────────────────────────────
# Security groups
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-${var.resource_name}-sg"
  description = "Bastion host: inbound SSH from allowed CIDRs, outbound SSH to private subnet only"
  vpc_id      = var.vpc_id

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-${var.resource_name}-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  for_each = toset(var.allowed_ssh_cidrs)

  security_group_id = aws_security_group.bastion.id
  description       = "Inbound SSH from allowed CIDR"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = each.value
}

resource "aws_vpc_security_group_egress_rule" "bastion_to_private" {
  security_group_id = aws_security_group.bastion.id
  description       = "Outbound SSH to private subnet"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.private_subnet_cidr
}

# SSM Agent, package updates, and other management traffic require outbound HTTPS.
resource "aws_vpc_security_group_egress_rule" "bastion_https_out" {
  security_group_id = aws_security_group.bastion.id
  description       = "Outbound HTTPS for SSM Agent and management traffic"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Callers attach this SG to any private EC2 that should be reachable via the
# bastion — no hard-coded IPs, no open-world SSH.
resource "aws_security_group" "target" {
  name        = "${var.name_prefix}-${var.resource_name}-target-sg"
  description = "Allow SSH from the ${var.name_prefix}-${var.resource_name} SG only - attach to private EC2s reachable via this bastion"
  vpc_id      = var.vpc_id

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-${var.resource_name}-target-sg" })
}

resource "aws_vpc_security_group_ingress_rule" "target_ssh_from_bastion" {
  security_group_id            = aws_security_group.target.id
  description                  = "SSH from bastion SG"
  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.bastion.id
}

# ──────────────────────────────────────────────────────────────────────────────
# Bastion EC2 instance
# ──────────────────────────────────────────────────────────────────────────────

module "ec2" {
  source = "../ec2"

  ami_id                      = var.ami_id
  instance_profile            = var.instance_profile_name
  associate_public_ip_address = true
  pds_resource_prefix         = var.name_prefix
  required_tags               = var.required_tags

  root_volume_delete_on_termination = true

  ec2_instance_configs = [{
    instance_name   = var.resource_name
    instance_type   = var.instance_type
    subnet_id       = var.subnet_id
    security_groups = [aws_security_group.bastion.id]
  }]
}

# ──────────────────────────────────────────────────────────────────────────────
# Elastic IP — allocation and association are separate resources so the EIP
# allocation survives instance replacement without being destroyed/recreated.
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_eip" "bastion" {
  count  = var.assign_eip ? 1 : 0
  domain = "vpc"

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-${var.resource_name}-eip" })
}

resource "aws_eip_association" "bastion" {
  count         = var.assign_eip ? 1 : 0
  instance_id   = module.ec2.ec2_instance_id[0]
  allocation_id = aws_eip.bastion[0].id
}
