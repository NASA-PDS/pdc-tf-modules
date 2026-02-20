data "aws_ami" "amzn-linux-2023" {
  most_recent = true

  filter {
    name   = "name"
    values = ["MCP Amazon Linux 2 *"]
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

data "aws_iam_instance_profile" "mcp-instance-profile" {
  name = var.instance_profile
}

resource "aws_instance" "mcp_ec2_instance" {
  count                  = length(var.ec2_instance_configs)
  ami                    = data.aws_ami.amzn-linux-2023.id
  iam_instance_profile   = data.aws_iam_instance_profile.mcp-instance-profile.name
  instance_type          = var.ec2_instance_configs[count.index].instance_type
  key_name               = var.ec2_instance_configs[count.index].key_pair_name
  availability_zone      = var.ec2_instance_configs[count.index].az
  subnet_id              = var.ec2_instance_configs[count.index].subnet_id
  vpc_security_group_ids = var.ec2_instance_configs[count.index].security_groups

  root_block_device {
    encrypted             = true
    delete_on_termination = false
  }

  tags = merge(var.required_tags, {
    Name = var.pds_resource_prefix != "" ? "${var.pds_resource_prefix}-${var.ec2_instance_configs[count.index].instance_name}" : var.ec2_instance_configs[count.index].instance_name
  })
}
