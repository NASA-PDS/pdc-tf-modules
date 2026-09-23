# ALB Module

> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pdc-tf-modules/pulls)._

---

Creates an Application Load Balancer for PDC AWS environments.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | yes |

## Outputs

_No outputs defined._

## Usage

```hcl
module "alb" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/alb?ref=main"

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```
