# EC2 Module

> ⚠️ **Internal/local use only** — This module is referenced in [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) via a local filesystem path (`../../pds-tf-modules/terraform/modules/ec2`), not via a versioned git ref. It has not been consumed or tested as a standalone remote module.
>
> If you adopt this module via a git ref and it works in your environment, please open a pull request to update the [Known Consumers](#known-consumers) table and the [module status in the root README](../../../../README.md).

## Known Consumers

| Repository | Source Reference | Notes |
|------------|-----------------|-------|
| [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) | Local path `../../pds-tf-modules/terraform/modules/ec2` | Not a versioned git ref — developer workspace coupling |

---

Provisions one or more Oracle Linux 9 EC2 instances in a PDC AWS environment. The AMI is auto-selected as the most recent `Oracle-Linux-9*` image. The instance profile must be set to the venue-scoped role created by `pdc-cds-infra` (e.g. `pds-cds-dev-ec2-instance-role`).

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `ec2_instance_configs` | List of EC2 instance configuration objects | `list(any)` | `[]` | yes |
| `associate_public_ip_address` | Whether to associate a public IP for all instances | `bool` | `false` | no |
| `instance_profile` | EC2 instance profile name (e.g. `pds-cds-dev-ec2-instance-role`) | `string` | `""` | yes |
| `pds_resource_prefix` | Optional prefix for resource naming | `string` | `""` | no |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `ec2_instance_id` | List of IDs of the created EC2 instances |

## Usage

```hcl
module "ec2" {
  source = "git@github.com:NASA-PDS/pds-tf-modules.git//terraform/modules/ec2?ref=main"

  ec2_instance_configs = [
    {
      ami           = "ami-0abcdef1234567890"
      instance_type = "t3.medium"
      subnet_id     = var.subnet_id
      name          = "pds-worker"
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
