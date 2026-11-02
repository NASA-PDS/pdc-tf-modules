# route53/private-zone

Shared Route 53 private hosted zone module. It creates one private zone, associates it with one VPC, and publishes the zone ID and name to SSM so consumers never look the zone up by name.

Names in a private zone resolve only from resolvers inside an associated VPC. From anywhere else the lookup returns NXDOMAIN. Use the zone for internal service hostnames (OpenSearch, Logstash) that must not appear in public DNS.

The module is reused wherever the zone is needed: the shared infra layer (`pdc-cds-infra`) and each tenant account and venue.

## Usage

```hcl
module "private_zone" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/route53/private-zone?ref=<tag-or-commit>"

  name   = "internal.${var.public_zone_name}"
  vpc_id = var.vpc_id

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```

Consumers create records in the zone with the ID from the module output or from SSM:

```hcl
data "aws_ssm_parameter" "private_zone_id" {
  name = "/pds/private-hosted-zone/id"
}

data "aws_ssm_parameter" "private_zone_name" {
  name = "/pds/private-hosted-zone/name"
}

resource "aws_route53_record" "example" {
  zone_id = data.aws_ssm_parameter.private_zone_id.value
  name    = "example.${data.aws_ssm_parameter.private_zone_name.value}"
  type    = "CNAME"
  ttl     = 300
  records = ["target.example.org"]
}
```

## Inputs

| Name | Default | Description |
|---|---|---|
| `name` | required | Zone DNS name. Lowercase, at least two labels, no trailing dot. |
| `vpc_id` | required | VPC the zone is associated with. |
| `vpc_region` | provider region | Region of the VPC. |
| `comment` | `Private hosted zone for internal service hostnames` | Zone comment. |
| `force_destroy` | `false` | Delete the zone even if it still has records. |
| `publish_ssm_parameters` | `true` | Publish `<ssm_prefix>/id` and `<ssm_prefix>/name`. |
| `ssm_prefix` | `/pds/private-hosted-zone` | SSM path prefix. Starts with `/`, no trailing `/`. |
| `required_tags` | `{}` | Tags for the zone and the SSM parameters. |

## Outputs

| Name | Description |
|---|---|
| `zone_id` | Zone ID. |
| `zone_name` | Zone name. |
| `zone_arn` | Zone ARN. |

## SSM parameters

| Parameter | Value |
|---|---|
| `<ssm_prefix>/id` | Zone ID. |
| `<ssm_prefix>/name` | Zone name. |

## Choosing the zone name

Use a dedicated subdomain of a name the venue owns, such as `internal.<public-zone>`. Do not reuse the public zone's own name. When a private zone and a public zone share a name, resolvers in the VPC answer only from the private zone for that whole domain, so every public name that is not copied into the private zone returns NXDOMAIN from inside the VPC.

## VPC requirements

The VPC must have `enable_dns_support` and `enable_dns_hostnames` set to `true`. The module fails the plan with a clear message when either is off.

## Associating more VPCs

The module associates one VPC. To attach more VPCs in the same account, add `aws_route53_zone_association` resources outside the module. The zone ignores changes to its inline `vpc` block, so those associations are kept. A VPC in another account needs `aws_route53_vpc_association_authorization` in the zone's account first.

## Verify

Run the first lookup from a host inside the VPC and the second from a host outside it. `RECORD_NAME` is the full name of a record in the zone:

```bash
RECORD_NAME="example.internal.example.org"
nslookup "${RECORD_NAME}"
```

Expect the record value from inside the VPC and `NXDOMAIN` from outside.

## Tests

```bash
cd terraform/modules/route53/private-zone
terraform init
terraform test
```
