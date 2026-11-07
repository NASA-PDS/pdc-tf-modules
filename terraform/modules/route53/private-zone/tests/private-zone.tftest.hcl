mock_provider "aws" {
  mock_data "aws_vpc" {
    defaults = {
      enable_dns_support   = true
      enable_dns_hostnames = true
    }
  }
}

variables {
  name          = "internal.example.org"
  vpc_id        = "vpc-0123456789abcdef0"
  required_tags = { tenant = "t", venue = "v", component = "c", cicd = "manual", managedby = "me" }
}

run "zone_is_private_and_associated_with_the_vpc" {
  command = plan

  assert {
    condition     = aws_route53_zone.this.name == "internal.example.org"
    error_message = "The zone must use the name input."
  }

  assert {
    condition     = one(aws_route53_zone.this.vpc).vpc_id == "vpc-0123456789abcdef0"
    error_message = "The zone must be associated with vpc_id, which makes it private."
  }

  assert {
    condition     = aws_route53_zone.this.force_destroy == false
    error_message = "force_destroy must default to false."
  }

  assert {
    condition     = aws_route53_zone.this.tags["component"] == "c"
    error_message = "required_tags must be applied to the zone."
  }
}

run "zone_id_and_name_are_published_to_ssm_by_default" {
  command = plan

  assert {
    condition     = aws_ssm_parameter.zone_id[0].name == "/pds/private-hosted-zone/id"
    error_message = "The zone ID must be published at <ssm_prefix>/id."
  }

  assert {
    condition     = aws_ssm_parameter.zone_name[0].name == "/pds/private-hosted-zone/name" && aws_ssm_parameter.zone_name[0].value == "internal.example.org"
    error_message = "The zone name must be published at <ssm_prefix>/name."
  }
}

run "ssm_prefix_is_configurable" {
  command = plan

  variables {
    ssm_prefix = "/pds/custom/zone"
  }

  assert {
    condition     = aws_ssm_parameter.zone_id[0].name == "/pds/custom/zone/id" && aws_ssm_parameter.zone_name[0].name == "/pds/custom/zone/name"
    error_message = "ssm_prefix must set the published parameter paths."
  }
}

run "ssm_publishing_can_be_disabled" {
  command = plan

  variables {
    publish_ssm_parameters = false
  }

  assert {
    condition     = length(aws_ssm_parameter.zone_id) == 0 && length(aws_ssm_parameter.zone_name) == 0
    error_message = "No SSM parameters may be created when publish_ssm_parameters is false."
  }
}

run "trailing_dot_in_name_is_rejected" {
  command = plan

  variables {
    name = "internal.example.org."
  }

  expect_failures = [var.name]
}

run "single_label_name_is_rejected" {
  command = plan

  variables {
    name = "internal"
  }

  expect_failures = [var.name]
}

run "ssm_prefix_with_trailing_slash_is_rejected" {
  command = plan

  variables {
    ssm_prefix = "/pds/private-hosted-zone/"
  }

  expect_failures = [var.ssm_prefix]
}

run "vpc_without_dns_hostnames_is_rejected" {
  command = plan

  override_data {
    target = data.aws_vpc.this
    values = {
      enable_dns_support   = true
      enable_dns_hostnames = false
    }
  }

  expect_failures = [aws_route53_zone.this]
}
