data "aws_ami" "oracle_linux_9" {
  most_recent = true

  filter {
    name   = "name"
    values = ["Oracle-Linux-9*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["794625662971"]
}

data "aws_iam_instance_profile" "ec2" {
  name = var.instance_profile
}

resource "aws_launch_template" "pds_ec2" {
  count = length(var.ec2_instance_configs)

  name_prefix   = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}-" : "${var.ec2_instance_configs[count.index].instance_name}-"
  image_id      = var.ami_id != "" ? var.ami_id : data.aws_ami.oracle_linux_9.id
  instance_type = var.ec2_instance_configs[count.index].instance_type
  key_name      = try(var.ec2_instance_configs[count.index].key_pair_name, null)

  network_interfaces {
    associate_public_ip_address = var.associate_public_ip_address
    subnet_id                   = var.ec2_instance_configs[count.index].subnet_id
    security_groups             = var.ec2_instance_configs[count.index].security_groups
  }

  iam_instance_profile {
    name = data.aws_iam_instance_profile.ec2.name
  }

  user_data = try(var.ec2_instance_configs[count.index].user_data, null)

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      encrypted             = true
      delete_on_termination = false
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
    tags = var.required_tags
  }

  tags = var.required_tags
}

resource "aws_instance" "pds_ec2" {
  count             = length(var.ec2_instance_configs)
  availability_zone = try(var.ec2_instance_configs[count.index].az, null)

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
