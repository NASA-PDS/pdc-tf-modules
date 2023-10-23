resource "aws_security_group" "security_groups" {
  count       = length(var.security_groups)
  name        = var.security_groups[count.index].name
  description = var.security_groups[count.index].description
  # vpc_id      = var.vpc_id
  vpc_id = var.security_groups[count.index].vpc_id

  dynamic "ingress" {
    for_each = var.security_groups[count.index].ingress_rules

    content {
      description = ingress.value.description
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = var.security_groups[count.index].egress_rules

    content {
      description = egress.value.description
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  # tags = merge(var.required_tags, {
  #   Name = var.security_groups[count.index].sg_name_tag
  # })

  tags = merge({
    Name    = var.security_groups[count.index].sg_name_tag
    Alfa    = var.security_groups[count.index].node_name_abbr
    Bravo   = var.security_groups[count.index].venue
    Charlie = var.security_groups[count.index].component
  })
}
