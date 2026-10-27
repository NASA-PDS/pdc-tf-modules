data "aws_ssm_parameter" "bastion_target_sg" {
  count = var.bastion_target_sg_ssm_path != "" ? 1 : 0
  name  = var.bastion_target_sg_ssm_path
}

locals {
  # Keyed by instance_name so adding, removing or reordering entries never replaces
  # unrelated instances.
  instances = { for c in var.ec2_instance_configs : c.instance_name => c }

  # lifecycle.ignore_changes only accepts literal attribute names, so it cannot be toggled
  # by a variable. Instances that opt in to ignore_instance_profile_changes are created by
  # aws_instance.pds_ec2_profile_unmanaged; every other instance by aws_instance.pds_ec2.
  instances_managed           = { for name, c in local.instances : name => c if !c.ignore_instance_profile_changes }
  instances_profile_unmanaged = { for name, c in local.instances : name => c if c.ignore_instance_profile_changes }

  bastion_target_sg_ids = var.bastion_target_sg_ssm_path != "" ? [data.aws_ssm_parameter.bastion_target_sg[0].value] : []

  instance_full_names = {
    for name, _ in local.instances :
    name => var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${name}" : name
  }

  # Both resource types, so outputs do not care which one an instance landed in.
  all_instances = merge(aws_instance.pds_ec2, aws_instance.pds_ec2_profile_unmanaged)
}

# Every launch setting is declared on aws_instance, so Terraform diffs and applies each
# one. In-place vs. replacement behavior is documented in the module README.
#
# KEEP aws_instance.pds_ec2 AND aws_instance.pds_ec2_profile_unmanaged IDENTICAL except for
# for_each and the lifecycle block. The test suite asserts they stay in sync.
resource "aws_instance" "pds_ec2" {
  for_each = local.instances_managed

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  availability_zone           = each.value.az
  vpc_security_group_ids      = concat(each.value.security_groups, local.bastion_target_sg_ids)
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = each.value.key_pair_name
  iam_instance_profile        = var.instance_profile != "" ? var.instance_profile : null
  user_data_base64            = each.value.user_data
  user_data_replace_on_change = each.value.user_data_replace_on_change

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
    Name  = local.instance_full_names[each.key]
    Patch = "true"
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

# Same as aws_instance.pds_ec2, for instances whose IAM instance profile is changed outside
# Terraform after boot (ignore_instance_profile_changes = true). The profile is set at
# launch and never reverted by later applies.
resource "aws_instance" "pds_ec2_profile_unmanaged" {
  for_each = local.instances_profile_unmanaged

  ami                         = var.ami_id
  instance_type               = each.value.instance_type
  subnet_id                   = each.value.subnet_id
  availability_zone           = each.value.az
  vpc_security_group_ids      = concat(each.value.security_groups, local.bastion_target_sg_ids)
  associate_public_ip_address = var.associate_public_ip_address
  key_name                    = each.value.key_pair_name
  iam_instance_profile        = var.instance_profile != "" ? var.instance_profile : null
  user_data_base64            = each.value.user_data
  user_data_replace_on_change = each.value.user_data_replace_on_change

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
    Name  = local.instance_full_names[each.key]
    Patch = "true"
  })

  # Tags for the EBS volumes attached to the instance (root volume included).
  volume_tags = merge(var.required_tags, {
    Name = local.instance_full_names[each.key]
  })

  lifecycle {
    # Compliance automation stamps Audit, CreatedBy, CreationTime on launch - ignore to avoid stripping them on re-apply.
    ignore_changes = [tags["Audit"], tags["CreatedBy"], tags["CreationTime"], iam_instance_profile]
  }
}
