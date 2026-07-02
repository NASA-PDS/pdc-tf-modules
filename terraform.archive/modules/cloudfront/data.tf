# base configuration
data "aws_ssm_parameter" "venue" {
    name = "/pds/core/venue"
}

data "aws_ssm_parameter" "region" {
    name = "/pds/core/region"
}

## interfaces

# S3-browser
data "aws_ssm_parameter" "s3_browser_bkt" {
    name = "/pds/s3-browser/s3-bucket"
}

data "aws_s3_bucket" "s3_browser_bkt" {
  bucket = data.aws_ssm_parameter.s3_browser_bkt.value
}

# Web site
data "aws_ssm_parameter" "s3_web_site_bkt" {
  name = "/pds/web-site/s3-bucket"
}

data "aws_s3_bucket" "s3_web_site_bkt" {
  bucket = data.aws_ssm_parameter.s3_web_site_bkt.value
}

# Web modernization portal
data "aws_ssm_parameter" "portal_wp_bkt" {
  name = "/pds/portal-wp/s3-bucket"
}

data "aws_s3_bucket" "portal_wp_bkt" {
  bucket = data.aws_ssm_parameter.portal_wp_bkt.value
}

# API load balancer
data "aws_ssm_parameter" "load_balancer_domain" {
  name= "/pds/registry/load-balancer-domain"
}

# Nucleus authentication load balancer
data "aws_ssm_parameter" "nucleus_auth_load_balancer_domain" {
  name= "/pds/nucleus/auth-load-balancer-domain"
}

# route 53 hosted zone
data "aws_ssm_parameter" "hosted_zone_name" {
  name = "/pds/hosted-zone/name"
}

data "aws_route53_zone" "main" {
  name = data.aws_ssm_parameter.hosted_zone_name.value
}

# SSL certificate
data "aws_ssm_parameter" "acm_certificate_arn" {
  name = "/pds/core/acm-certificate-arn"
}


# pre-existing policies in dev
data "aws_ssm_parameter" "cloud_front_cache_policy_id" {
  name = "/pds/core/cache_policy_id"
}

data "aws_ssm_parameter" "cloud_front_origin_request_policy_id" {
  name = "/pds/core/origin_request_policy_id"
}
