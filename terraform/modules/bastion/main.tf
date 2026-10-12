# ──────────────────────────────────────────────────────────────────────────────
# Security groups
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_security_group" "bastion" {
  name        = "${var.name_prefix}-bastion-sg"
  description = "Bastion host: inbound SSH from allowed CIDRs, outbound SSH to private subnet only"
  vpc_id      = var.vpc_id

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-bastion-sg" })
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

# Callers attach this SG to any private EC2 that should be reachable via the
# bastion — no hard-coded IPs, no open-world SSH.
resource "aws_security_group" "target" {
  name        = "${var.name_prefix}-bastion-target-sg"
  description = "Allow SSH from the ${var.name_prefix} bastion SG only - attach to private EC2s reachable via this bastion"
  vpc_id      = var.vpc_id

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-bastion-target-sg" })
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

  ec2_instance_configs = [{
    instance_name   = "bastion"
    instance_type   = var.instance_type
    subnet_id       = var.subnet_id
    security_groups = [aws_security_group.bastion.id]
  }]
}

# ──────────────────────────────────────────────────────────────────────────────
# Optional Elastic IP
# ──────────────────────────────────────────────────────────────────────────────

resource "aws_eip" "bastion" {
  count    = var.assign_eip ? 1 : 0
  domain   = "vpc"
  instance = module.ec2.ec2_instance_id[0]

  tags = merge(var.required_tags, { Name = "${var.name_prefix}-bastion-eip" })
}
