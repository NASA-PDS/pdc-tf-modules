# Instance profile published by an existing IAM stack (e.g. pdc-cds-infra/bastion-core/iam).
# Must already exist — this example does not create IAM resources (P19).
data "aws_ssm_parameter" "instance_profile_name" {
  name = var.instance_profile_name_ssm_path
}

# Pick the first available private subnet in the VPC.
data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
  filter {
    name   = "map-public-ip-on-launch"
    values = ["false"]
  }
}

# Minimal SG — no inbound rules (bastion_target_sg_ssm_path adds the SSH ingress).
# Outbound open so the SSM agent and DynamoDB SSH auth can reach AWS endpoints.
resource "aws_security_group" "test" {
  name        = "pds-cds-bastion-ssh-verify"
  description = "Test EC2 for bastion SSH verification - destroy after use"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.required_tags, { Name = "pds-cds-bastion-ssh-verify" })
}

module "ec2" {
  source = "git::ssh://git@github.com/NASA-PDS/pdc-tf-modules.git//terraform/modules/ec2?ref=feature/51-bastion-module"

  ami_id                     = var.ami_id
  instance_profile           = data.aws_ssm_parameter.instance_profile_name.value
  bastion_target_sg_ssm_path = var.bastion_target_sg_ssm_path
  disable_api_termination    = false # test instance — easy to destroy
  required_tags              = var.required_tags

  ec2_instance_configs = [{
    instance_name   = "bastion-ssh-verify"
    instance_type   = "t3.micro"
    subnet_id       = sort(data.aws_subnets.private.ids)[0]
    security_groups = [aws_security_group.test.id]
  }]
}
