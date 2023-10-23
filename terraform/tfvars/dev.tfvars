aws_region = "us-west-2"
# vpc_id     = "vpc-02f8cc4962d6f8dc6"
security_groups = [
  {
    name           = "Test SG"
    description    = "Enable SSH/HTTP/HTTPS access on ports 22/80/443"
    vpc_id         = "vpc-02f8cc4962d6f8dc6"
    sg_name_tag    = "PDS Registry TCP SG"
    node_name_abbr = "en"
    venue          = "prod"
    component      = "registry"
    ingress_rules = [
      {
        description = "Allow SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.1.0.0/16"]
      },
      {
        description = "Allow HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["10.1.0.0/16"]
      },
      {
        description = "Allow HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.1.0.0/16"]
      }
    ]
    egress_rules = [
      {
        description = "Allow All Outbound Traffic"
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
]
# node_name_abbr = "en"
# venue          = "prod"
# component      = "pds-registry"
