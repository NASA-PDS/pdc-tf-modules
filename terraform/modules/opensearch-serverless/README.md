# OpenSearch Serverless Module

> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pdc-tf-modules/pulls)._

---

Creates an OpenSearch Serverless collection with encryption policy, network policy, and data access policy.

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `collection_name` | Name of the OpenSearch Serverless collection | `string` | yes |
| `collection_type` | Collection type: `SEARCH`, `TIMESERIES`, or `VECTORSEARCH` | `string` | yes |
| `encryption_policy_name` | Name of the security encryption policy | `string` | yes |
| `network_policy_name` | Name of the network policy | `string` | yes |
| `data_access_policy_name` | Name of the data access policy | `string` | yes |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `public_network_policy_arn` | Name of the public network access policy |
| `data_access_policy_arn` | Name of the data access policy |
| `collection_name` | Name of the serverless collection |
| `collection_arn` | ARN of the serverless collection |
| `collection_endpoint` | OpenSearch Serverless collection endpoint |
| `dashboard_endpoint` | OpenSearch Serverless dashboard endpoint |

## Usage

```hcl
module "opensearch_serverless" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/opensearch-serverless?ref=main"

  collection_name         = "pds-registry"
  collection_type         = "SEARCH"
  encryption_policy_name  = "pds-registry-encryption"
  network_policy_name     = "pds-registry-network"
  data_access_policy_name = "pds-registry-data-access"

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```
