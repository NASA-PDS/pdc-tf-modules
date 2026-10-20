mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "sg-0123456789abcdef0"
    }
  }
}

variables {
  ami_id        = "ami-00000000"
  required_tags = { tenant = "t", venue = "v", component = "c", cicd = "manual", managedby = "me" }
  ec2_instance_configs = [
    {
      instance_name   = "alpha"
      instance_type   = "t3.medium"
      subnet_id       = "subnet-1"
      security_groups = ["sg-1"]
      user_data       = "IyEvYmluL2Jhc2gKZWNobyBoaQ==" # base64 of "#!/bin/bash\necho hi"
    },
    {
      instance_name    = "beta"
      instance_type    = "t3.large"
      subnet_id        = "subnet-1"
      security_groups  = ["sg-1"]
      root_volume_size = 100
    },
  ]
}

run "instances_are_keyed_by_name_with_settings_on_the_instance" {
  command = plan

  assert {
    condition     = length(aws_instance.pds_ec2) == 2 && contains(keys(aws_instance.pds_ec2), "alpha") && contains(keys(aws_instance.pds_ec2), "beta")
    error_message = "Instances should be keyed by instance_name."
  }

  assert {
    condition     = aws_instance.pds_ec2["beta"].instance_type == "t3.large" && aws_instance.pds_ec2["beta"].root_block_device[0].volume_size == 100
    error_message = "instance_type and root volume size must be set directly on aws_instance."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].root_block_device[0].volume_size == 50 && aws_instance.pds_ec2["alpha"].root_block_device[0].encrypted
    error_message = "Root volume should default to 50 GB and be encrypted."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].tags["Name"] == "alpha" && aws_instance.pds_ec2["alpha"].volume_tags["Name"] == "alpha"
    error_message = "Name must be set on the instance and its volumes."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].user_data_base64 == "IyEvYmluL2Jhc2gKZWNobyBoaQ=="
    error_message = "user_data must be passed through as user_data_base64 (callers supply base64)."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 must be required."
  }
}

run "prefix_and_bastion_sg_are_applied" {
  command = plan

  variables {
    pds_resource_prefix        = "pds-test"
    bastion_target_sg_ssm_path = "/pds/test/bastion/target-sg"
    instance_profile           = "my-profile"
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].tags["Name"] == "pds-test-alpha"
    error_message = "Name tag should include the prefix."
  }

  assert {
    condition     = length(aws_instance.pds_ec2["alpha"].vpc_security_group_ids) == 2
    error_message = "Bastion target SG should be appended to the instance's security groups."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].iam_instance_profile == "my-profile"
    error_message = "instance_profile should be attached."
  }
}

run "duplicate_instance_names_are_rejected" {
  command = plan

  variables {
    ec2_instance_configs = [
      { instance_name = "dup", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"] },
      { instance_name = "dup", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"] },
    ]
  }

  expect_failures = [var.ec2_instance_configs]
}

run "empty_security_groups_are_rejected" {
  command = plan

  variables {
    ec2_instance_configs = [
      { instance_name = "nosg", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = [] },
    ]
  }

  expect_failures = [var.ec2_instance_configs]
}
