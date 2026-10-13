data "aws_ssm_parameter" "bastion_target_sg" {
  count = var.bastion_target_sg_ssm_path != "" ? 1 : 0
  name  = var.bastion_target_sg_ssm_path
}

resource "aws_launch_template" "pds_ec2" {
  count = length(var.ec2_instance_configs)

  name_prefix   = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}-" : "${var.ec2_instance_configs[count.index].instance_name}-"
  image_id      = var.ami_id
  instance_type = var.ec2_instance_configs[count.index].instance_type
  key_name      = try(var.ec2_instance_configs[count.index].key_pair_name, null)

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    subnet_id                   = var.ec2_instance_configs[count.index].subnet_id
    security_groups = concat(
      var.ec2_instance_configs[count.index].security_groups,
      var.bastion_target_sg_ssm_path != "" ? [data.aws_ssm_parameter.bastion_target_sg[0].value] : []
    )
  }

  iam_instance_profile {
    name = var.instance_profile
  }

  user_data = try(var.ec2_instance_configs[count.index].user_data, null)

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = try(var.ec2_instance_configs[count.index].root_volume_size, 50)
      volume_type           = try(var.ec2_instance_configs[count.index].root_volume_type, "gp3")
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(var.required_tags, {
      Name = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}" : var.ec2_instance_configs[count.index].instance_name
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(var.required_tags, {
      Name = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}" : var.ec2_instance_configs[count.index].instance_name
    })
  }

  tag_specifications {
    resource_type = "network-interface"
    tags          = var.required_tags
  }

  tags = var.required_tags
}

resource "aws_instance" "pds_ec2" {
  count             = length(var.ec2_instance_configs)
  availability_zone = try(var.ec2_instance_configs[count.index].az, null)

  # Mirrors the launch template's network_interfaces.associate_public_ip_address
  # (default false) — set explicitly here too since static analysis (SonarCloud)
  # scans this resource directly and can't resolve the inherited launch template value.
  associate_public_ip_address = var.associate_public_ip_address

  disable_api_termination = var.disable_api_termination

  launch_template {
    id      = aws_launch_template.pds_ec2[count.index].id
    version = "$Latest"
  }

  tags = merge(var.required_tags, {
    Name = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}" : var.ec2_instance_configs[count.index].instance_name
  })

  lifecycle {
    # Compliance automation stamps Audit, CreatedBy, CreationTime on launch — ignore to avoid stripping them on re-apply.
    ignore_changes = [tags["Audit"], tags["CreatedBy"], tags["CreationTime"]]
  }
}
