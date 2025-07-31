# TODO SA add the s3 bucket for logs, from a module somewhere else
# TODO Dev make terraform code for s3-browser
# TODO Dev update registry API terraform
# TODO SA add origin/behavior for DUM API gateway, should be under path /api/dum ?

resource "aws_cloudfront_function" "api_alb_rewrite_url" {
  name    = "api_alb_rewrite_url"
  runtime = "cloudfront-js-2.0"
  comment = "removes URL prefix before forwarding request to s3 origin bucket"
  publish = true
  code    = file("${path.module}/js/api_alb_rewrite_url.js")
}

resource "aws_cloudfront_function" "one_page_app_rewrite_url" {
  name    = "one_page_app_s3_rewrite_url"
  runtime = "cloudfront-js-2.0"
  comment = "removes URL prefix before forwarding request to s3 origin bucket"
  publish = true
  code    = file("${path.module}/js/one_page_app_s3_rewrite_url.js")
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "example"
  description                       = "Grant cloudfront access to s3 buckets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

data "aws_cloudfront_origin_request_policy" "manged_all_viewer_origin_request_policy" {
  name = "Managed-AllViewer"
}

resource "aws_cloudfront_distribution" "pds_distribution" {
  origin {
    origin_id   = "default_web_site"
    domain_name = "${data.aws_ssm_parameter.s3_web_site_bkt.value}.s3.${data.aws_ssm_parameter.region.value}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  origin {
    origin_id    = "registry_api_lb"
    domain_name  = data.aws_ssm_parameter.load_balancer_domain.value
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  origin {
    origin_id   = "s3_browser_bkt"
    domain_name = "${data.aws_ssm_parameter.s3_browser_bkt.value}.s3.${data.aws_ssm_parameter.region.value}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  origin {
    origin_id   = "portal_wp_bkt"
    domain_name = "${data.aws_ssm_parameter.portal_wp_bkt.value}.s3.${data.aws_ssm_parameter.region.value}.amazonaws.com"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  origin {
    origin_id   = "nucleus_auth_lb"
    domain_name = data.aws_ssm_parameter.nucleus_auth_load_balancer_domain.value

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Main PDS ${data.aws_ssm_parameter.venue.value} Cloudfront distribution"
  default_root_object = "index.html"

  logging_config {
    include_cookies = false
    bucket          = "pds-logs-${data.aws_ssm_parameter.venue.value}.s3.${data.aws_ssm_parameter.region.value}.amazonaws.com"
  }

  aliases = [data.aws_route53_zone.main.name]

  viewer_certificate {
    acm_certificate_arn            = data.aws_ssm_parameter.acm_certificate_arn.value
    cloudfront_default_certificate = true
    ssl_support_method             = "sni-only" # TODO TO BE CONFIRMED
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "default_web_site"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_ssm_parameter.cloud_front_origin_request_policy_id.value
  }

  ordered_cache_behavior {
    path_pattern     = "/data*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "s3_browser_bkt"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.one_page_app_rewrite_url.arn
    }


    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_ssm_parameter.cloud_front_origin_request_policy_id.value

  }

  ordered_cache_behavior {
    path_pattern     = "/api*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "registry_api_lb"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_alb_rewrite_url.arn
    }


    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"

  }

  ordered_cache_behavior {
    path_pattern     = "/portal*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "portal_wp_bkt"
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.one_page_app_rewrite_url.arn
    }

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_ssm_parameter.cloud_front_origin_request_policy_id.value

  }

  ordered_cache_behavior {
    path_pattern     = "/assets*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "portal_wp_bkt"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_ssm_parameter.cloud_front_origin_request_policy_id.value
  }

  ordered_cache_behavior {
    path_pattern     = "/nucleus*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "nucleus_auth_lb"

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.manged_all_viewer_origin_request_policy.id
  }

  ordered_cache_behavior {
    path_pattern     = "/oauth2*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = "nucleus_auth_lb"

    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
    compress               = true
    viewer_protocol_policy = "https-only"
    cache_policy_id = data.aws_ssm_parameter.cloud_front_cache_policy_id.value
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.manged_all_viewer_origin_request_policy.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Alfa = "en"
    Bravo = data.aws_ssm_parameter.venue.value
    Charlie = "frontend"
  }
}

resource "aws_ssm_parameter" "cloudfront_distribution" {
  name  = "/pds/core/cloudfront-distribution/arn"
  type  = "String"
  value = aws_cloudfront_distribution.pds_distribution.arn
}

resource "aws_s3_bucket_policy" "allow_s3_browser_access_from_cloudfront_dist" {
  bucket = data.aws_s3_bucket.s3_browser_bkt.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "${data.aws_s3_bucket.s3_browser_bkt.arn}/**",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": aws_cloudfront_distribution.pds_distribution.arn
                }
            }
        }
    ]
})
}

resource "aws_s3_bucket_policy" "allow_web_site_access_from_cloudfront_dist" {
  bucket = data.aws_s3_bucket.s3_web_site_bkt.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudfront.amazonaws.com"
            },
            "Action": "s3:GetObject",
            "Resource": "${data.aws_s3_bucket.s3_web_site_bkt.arn}/**",
            "Condition": {
                "StringEquals": {
                    "AWS:SourceArn": aws_cloudfront_distribution.pds_distribution.arn
                }
            }
        }
    ]
})
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.id
  name    = data.aws_route53_zone.main.name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.pds_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.pds_distribution.hosted_zone_id
    evaluate_target_health = true
  }
}
