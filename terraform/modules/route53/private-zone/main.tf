# Route 53 private hosted zone associated with one VPC.
# Names in the zone resolve only from inside associated VPCs; other resolvers get NXDOMAIN.
# The VPC needs DNS support and DNS hostnames enabled for private zones to resolve.
data "aws_vpc" "this" {
  id = var.vpc_id
}

resource "aws_route53_zone" "this" {
  name          = var.name
  comment       = var.comment
  force_destroy = var.force_destroy
  tags          = var.required_tags

  vpc {
    vpc_id = var.vpc_id
  }

  lifecycle {
    # Additional VPCs are attached with aws_route53_zone_association outside this
    # module. Without this, the inline vpc block would try to remove them. The
    # provider cannot ignore only those external associations, so vpc_id applies
    # at creation only; see "Changing the VPC" in the README.
    ignore_changes = [vpc]

    precondition {
      condition     = data.aws_vpc.this.enable_dns_support && data.aws_vpc.this.enable_dns_hostnames
      error_message = "VPC ${var.vpc_id} must have enable_dns_support and enable_dns_hostnames set to true, or the private zone will not resolve."
    }
  }
}

# Consumers read these instead of looking the zone up by name.
resource "aws_ssm_parameter" "zone_id" {
  count = var.publish_ssm_parameters ? 1 : 0

  name        = "${var.ssm_prefix}/id"
  type        = "String"
  value       = aws_route53_zone.this.zone_id
  description = "Route 53 private hosted zone ID for internal service hostnames"
  tags        = var.required_tags
}

resource "aws_ssm_parameter" "zone_name" {
  count = var.publish_ssm_parameters ? 1 : 0

  name        = "${var.ssm_prefix}/name"
  type        = "String"
  value       = aws_route53_zone.this.name
  description = "Route 53 private hosted zone name for internal service hostnames"
  tags        = var.required_tags
}
