# route53/private-zone

Shared Route 53 private hosted zone module. It creates one private zone, associates it with one VPC, and publishes the zone ID and name to SSM so consumers never look the zone up by name.

Names in a private zone resolve only from resolvers inside an associated VPC. From anywhere else the lookup returns NXDOMAIN. Use the zone for internal service hostnames (for example an EC2 instance) that must not appear in public DNS.

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
| `vpc_id` | required | VPC the zone is associated with. Must be in the provider's region. Applies at creation only (see [Changing the VPC](#changing-the-vpc)). |
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

## Requirements

The module requires Terraform 1.3 or newer.

## VPC requirements

The VPC must have `enable_dns_support` and `enable_dns_hostnames` set to `true`. The module fails the plan with a clear message when either is off.

The VPC must be in the region of the AWS provider the module uses. The module reads the VPC and creates the association through that one provider. For a VPC in another region, pass the module a provider configured for that region:

```hcl
provider "aws" {
  alias  = "vpc_region"
  region = "us-east-1"
}

module "private_zone" {
  source    = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/route53/private-zone?ref=<tag-or-commit>"
  providers = { aws = aws.vpc_region }

  name   = "internal.${var.public_zone_name}"
  vpc_id = var.vpc_id
}
```

## Associating more VPCs

The module associates one VPC. To attach more VPCs in the same account, add `aws_route53_zone_association` resources outside the module. The zone ignores changes to its inline `vpc` block, so those associations are kept. A VPC in another account needs `aws_route53_vpc_association_authorization` in the zone's account first.

## Changing the VPC

Because the zone ignores changes to its inline `vpc` block, `vpc_id` is a creation-time input. Changing it on an existing zone produces a clean plan and leaves the zone associated with the original VPC, so workloads in the new VPC cannot resolve its records.

To move the zone to a different VPC without replacing it:

1. Associate the new VPC with an `aws_route53_zone_association` outside the module, using `module.private_zone.zone_id`, and apply.
2. Remove the original association. Route 53 requires at least one associated VPC, which the new association satisfies:

   ```bash
   ZONE_ID="<zone-id>"
   OLD_VPC_ID="<original-vpc-id>"
   OLD_VPC_REGION="<original-vpc-region>"
   aws route53 disassociate-vpc-from-hosted-zone \
     --hosted-zone-id "${ZONE_ID}" \
     --vpc "VPCRegion=${OLD_VPC_REGION},VPCId=${OLD_VPC_ID}"
   ```

3. Set the module's `vpc_id` to the new VPC so the configuration matches. The plan stays clean.

Replacing the zone also works, with `terraform apply -replace`, but it creates a zone with a new ID. Records in the old zone must be removed first (or set `force_destroy = true` for that apply), and consumers must recreate their records in the new zone.

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
