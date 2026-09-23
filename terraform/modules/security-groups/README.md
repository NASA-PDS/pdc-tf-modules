# Security Groups Module

> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pdc-tf-modules/pulls)._

---

Creates one or more VPC security groups from a list of configuration objects.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `security_groups` | List of security group configuration objects | `list(any)` | yes |
| `vpc_id` | VPC ID in which to create the security groups | `string` | yes |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `security_group_id` | List of IDs of the created security groups |

## Usage

```hcl
module "security_groups" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/security-groups?ref=main"

  vpc_id = var.vpc_id

  security_groups = [
    {
      name        = "pds-alb-sg"
      description = "Allow HTTPS inbound to ALB"
      sg_name_tag = "pds-alb-sg"
      ingress_rules = [
        {
          description = "HTTPS from anywhere"
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
      egress_rules = [
        {
          description = "Allow all outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  ]

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```
