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
    error_message = "instance_type and root volume size must be set on aws_instance."
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

  assert {
    condition     = aws_instance.pds_ec2["alpha"].tags["Patch"] == "true" && !contains(keys(aws_instance.pds_ec2["alpha"].volume_tags), "Patch")
    error_message = "Instances must be tagged Patch = \"true\" (instance tags only, not volume tags)."
  }

  assert {
    condition     = aws_instance.pds_ec2["alpha"].user_data_replace_on_change == false
    error_message = "user_data_replace_on_change must default to false."
  }
}

run "user_data_replace_on_change_is_set_per_instance" {
  command = plan

  variables {
    ec2_instance_configs = [
      { instance_name = "bootstrap", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], user_data = "dGVzdA==", user_data_replace_on_change = true },
      { instance_name = "plain", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], user_data = "dGVzdA==" },
    ]
  }

  assert {
    condition     = aws_instance.pds_ec2["bootstrap"].user_data_replace_on_change == true && aws_instance.pds_ec2["plain"].user_data_replace_on_change == false
    error_message = "user_data_replace_on_change must apply only to the instances that set it."
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

run "profile_flag_routes_instances_and_keeps_both_resources_in_sync" {
  command = plan

  variables {
    instance_profile = "profile-a"
    ec2_instance_configs = [
      { instance_name = "managed", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], root_volume_size = 80, user_data = "dGVzdA==", user_data_replace_on_change = true },
      { instance_name = "swapped", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], root_volume_size = 80, user_data = "dGVzdA==", user_data_replace_on_change = true, ignore_instance_profile_changes = true },
    ]
  }

  assert {
    condition     = contains(keys(aws_instance.pds_ec2), "managed") && !contains(keys(aws_instance.pds_ec2), "swapped")
    error_message = "Instances without the flag belong to aws_instance.pds_ec2 only."
  }

  assert {
    condition     = contains(keys(aws_instance.pds_ec2_profile_unmanaged), "swapped") && !contains(keys(aws_instance.pds_ec2_profile_unmanaged), "managed")
    error_message = "Instances with ignore_instance_profile_changes belong to aws_instance.pds_ec2_profile_unmanaged only."
  }

  assert {
    condition     = length(output.instance_ids) == 2 && contains(keys(output.instance_ids), "managed") && contains(keys(output.instance_ids), "swapped")
    error_message = "Outputs must include instances from both resources."
  }

  # Guard against the two near-identical resource blocks drifting apart.
  assert {
    condition = alltrue([
      aws_instance.pds_ec2["managed"].ami == aws_instance.pds_ec2_profile_unmanaged["swapped"].ami,
      aws_instance.pds_ec2["managed"].instance_type == aws_instance.pds_ec2_profile_unmanaged["swapped"].instance_type,
      aws_instance.pds_ec2["managed"].subnet_id == aws_instance.pds_ec2_profile_unmanaged["swapped"].subnet_id,
      aws_instance.pds_ec2["managed"].vpc_security_group_ids == aws_instance.pds_ec2_profile_unmanaged["swapped"].vpc_security_group_ids,
      aws_instance.pds_ec2["managed"].iam_instance_profile == aws_instance.pds_ec2_profile_unmanaged["swapped"].iam_instance_profile,
      aws_instance.pds_ec2["managed"].user_data_base64 == aws_instance.pds_ec2_profile_unmanaged["swapped"].user_data_base64,
      aws_instance.pds_ec2["managed"].user_data_replace_on_change == aws_instance.pds_ec2_profile_unmanaged["swapped"].user_data_replace_on_change,
      { for k, v in aws_instance.pds_ec2["managed"].tags : k => v if k != "Name" } == { for k, v in aws_instance.pds_ec2_profile_unmanaged["swapped"].tags : k => v if k != "Name" },
      { for k, v in aws_instance.pds_ec2["managed"].volume_tags : k => v if k != "Name" } == { for k, v in aws_instance.pds_ec2_profile_unmanaged["swapped"].volume_tags : k => v if k != "Name" },
      aws_instance.pds_ec2["managed"].disable_api_termination == aws_instance.pds_ec2_profile_unmanaged["swapped"].disable_api_termination,
      aws_instance.pds_ec2["managed"].associate_public_ip_address == aws_instance.pds_ec2_profile_unmanaged["swapped"].associate_public_ip_address,
      aws_instance.pds_ec2["managed"].metadata_options[0].http_endpoint == aws_instance.pds_ec2_profile_unmanaged["swapped"].metadata_options[0].http_endpoint,
      aws_instance.pds_ec2["managed"].metadata_options[0].http_tokens == aws_instance.pds_ec2_profile_unmanaged["swapped"].metadata_options[0].http_tokens,
      aws_instance.pds_ec2["managed"].metadata_options[0].http_put_response_hop_limit == aws_instance.pds_ec2_profile_unmanaged["swapped"].metadata_options[0].http_put_response_hop_limit,
      aws_instance.pds_ec2["managed"].root_block_device[0].volume_size == aws_instance.pds_ec2_profile_unmanaged["swapped"].root_block_device[0].volume_size,
      aws_instance.pds_ec2["managed"].root_block_device[0].volume_type == aws_instance.pds_ec2_profile_unmanaged["swapped"].root_block_device[0].volume_type,
      aws_instance.pds_ec2["managed"].root_block_device[0].encrypted == aws_instance.pds_ec2_profile_unmanaged["swapped"].root_block_device[0].encrypted,
      aws_instance.pds_ec2["managed"].root_block_device[0].delete_on_termination == aws_instance.pds_ec2_profile_unmanaged["swapped"].root_block_device[0].delete_on_termination,
    ])
    error_message = "aws_instance.pds_ec2 and aws_instance.pds_ec2_profile_unmanaged must apply identical settings."
  }
}

run "apply_with_initial_profile" {
  command = apply

  variables {
    instance_profile = "profile-a"
    ec2_instance_configs = [
      { instance_name = "managed", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"] },
      { instance_name = "swapped", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], ignore_instance_profile_changes = true },
    ]
  }
}

run "later_profile_change_only_reaches_instances_that_did_not_opt_out" {
  command = plan

  variables {
    instance_profile = "profile-b"
    ec2_instance_configs = [
      { instance_name = "managed", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"] },
      { instance_name = "swapped", instance_type = "t3.medium", subnet_id = "subnet-1", security_groups = ["sg-1"], ignore_instance_profile_changes = true },
    ]
  }

  assert {
    condition     = aws_instance.pds_ec2["managed"].iam_instance_profile == "profile-b"
    error_message = "A changed instance_profile must be applied to instances that did not opt out."
  }

  assert {
    condition     = aws_instance.pds_ec2_profile_unmanaged["swapped"].iam_instance_profile == "profile-a"
    error_message = "ignore_instance_profile_changes must keep the existing instance profile on later applies."
  }
}
