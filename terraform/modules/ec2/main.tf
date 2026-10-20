data "aws_ssm_parameter" "bastion_target_sg" {
  count = var.bastion_target_sg_ssm_path != "" ? 1 : 0
  name  = var.bastion_target_sg_ssm_path
}

locals {
  # Keyed by instance_name so adding, removing or reordering entries never replaces
  # unrelated instances (a list index would).
  instances = { for c in var.ec2_instance_configs : c.instance_name => c }

  bastion_target_sg_ids = var.bastion_target_sg_ssm_path != "" ? [data.aws_ssm_parameter.bastion_target_sg[0].value] : []

  instance_full_names = {
    for name, _ in local.instances :
    name => var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${name}" : name
  }
}

# Every launch setting is declared directly on aws_instance (no launch template) so that
# Terraform diffs and applies each one. In-place vs. replacement behavior is documented in
# the module README.
resource "aws_instance" "pds_ec2" {
  for_each = local.instances

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  availability_zone           = each.value.az
  vpc_security_group_ids      = concat(each.value.security_groups, local.bastion_target_sg_ids)
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = each.value.key_pair_name
  iam_instance_profile        = var.instance_profile != "" ? var.instance_profile : null
  user_data_base64            = each.value.user_data

  disable_api_termination = var.disable_api_termination

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  root_block_device {
    volume_size           = each.value.root_volume_size
    volume_type           = each.value.root_volume_type
    encrypted             = true
    delete_on_termination = var.root_volume_delete_on_termination
  }

  tags = merge(var.required_tags, {
    Name = local.instance_full_names[each.key]
  })

  # Tags for the EBS volumes attached to the instance (root volume included).
  volume_tags = merge(var.required_tags, {
    Name = local.instance_full_names[each.key]
  })

  lifecycle {
    # Compliance automation stamps Audit, CreatedBy, CreationTime on launch - ignore to avoid stripping them on re-apply.
    ignore_changes = [tags["Audit"], tags["CreatedBy"], tags["CreationTime"]]
  }
}
