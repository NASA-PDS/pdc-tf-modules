aws_region     = "us-west-2"
vpc_id         = "vpc-02f8cc4962d6f8dc6"
node_name_abbr = "en"
venue          = "prod"
component      = "pds-registry"
ec2_instance_configs = [
  {
    instance_name   = "pdsmcp-dev1"
    instance_type   = "t2.medium"
    az              = "us-west-2a"
    key_pair_name   = ""
    subnet_id       = "subnet-07833269aab07a81f"
    security_groups = ["sg-0eff14527c8519106"]
  },
  {
    instance_name   = "pdsmcp-dev2"
    instance_type   = "t2.medium"
    az              = "us-west-2a"
    key_pair_name   = ""
    subnet_id       = "subnet-07833269aab07a81f"
    security_groups = ["sg-0eff14527c8519106"]
  },
  {
    instance_name   = "pdsmcp-engineering-dev"
    instance_type   = "t3.large"
    az              = "us-west-2a"
    key_pair_name   = ""
    subnet_id       = "subnet-07833269aab07a81f"
    security_groups = ["sg-0eff14527c8519106"]
  }
]
security_groups = [
  {
    name        = "PDS Registry Security Group"
    description = "Enable SSH/HTTP/HTTPS access on ports 22/80/443"
    sg_name_tag = "PDS Registry TCP SG"
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
