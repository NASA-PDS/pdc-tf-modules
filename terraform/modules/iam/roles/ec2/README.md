# IAM Role: EC2

## Known Consumers

| Repository | Source Reference | Notes |
|------------|-----------------|-------|
| [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) | `?ref=feature/update-ec2-module-oracle-linux-pdc` (`terraform/iam/roles`) | Tested — creates the EC2 instance role/profile for the Logstash instance. Update to `?ref=main` once this branch merges. |

---

Creates a venue/component-scoped IAM role and matching instance profile for EC2 instances, with a set of default policies attached to every role (see [Default Policies](#default-policies) below). Additional managed policy ARNs can be attached via `additional_policy_arns`.

The role ARN and instance profile name are also published to SSM Parameter Store so other stacks/components can look them up without a Terraform remote-state dependency.

This module pairs with the [`ec2`](../../../ec2) module — create the role here, then pass the resulting `instance_profile_name` into the `ec2` module's `instance_profile` input.

## Default Policies

Every EC2 instance role created by this module gets the following policies attached, regardless of `additional_policy_arns`:

| Policy | Type | Purpose |
|--------|------|---------|
| `CloudWatchAgentServerPolicy` | AWS managed | CloudWatch agent metrics/logs |
| `AmazonSSMManagedInstanceCore` | AWS managed | SSM Session Manager access |
| `ec2users-dynamodb` | Inline role policy | `dynamodb:Get*`/`dynamodb:Query` on the `ec2users` DynamoDB table (see `ec2users_dynamodb_table_arn`) |
| *(your custom policy)* | Managed, via `additional_policy_arns` | Component-specific permissions |

The `ec2users-dynamodb` policy grants read access to a DynamoDB table used to look up EC2 user account/login info. **This table's ARN is account/environment-specific and not published here** — pass it in via `ec2users_dynamodb_table_arn`. It is required for every EC2 instance role created with this module; ask a platform engineer for the correct ARN for your account if you don't have it.

## Resources Created

- **IAM Role** — trust policy scoped to `ec2.amazonaws.com`, named `<venue>-<component>-ec2-role`
- **IAM Role Policy Attachments** — `AmazonSSMManagedInstanceCore`, `CloudWatchAgentServerPolicy`, plus any ARNs in `additional_policy_arns`
- **IAM Role Policy (inline)** — `ec2users-dynamodb`, granting `dynamodb:Get*`/`dynamodb:Query` on `ec2users_dynamodb_table_arn`
- **IAM Instance Profile** — same name as the role
- **SSM Parameters**:
  - `/pds/<component>/iam/roles/ec2/instance-role-arn`
  - `/pds/<component>/iam/roles/ec2/instance-profile-name`

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `venue` | Deployment venue/environment (e.g. `pds-cds-dev`). Used in resource naming. | `string` | — | yes |
| `component` | Component name (e.g. `o11y-cloudfront-batch`). Combined with `venue` to form the role name: `<venue>-<component>-ec2-role`. | `string` | — | yes |
| `ec2users_dynamodb_table_arn` | ARN of the `ec2users` DynamoDB table. Account/environment-specific — see [Default Policies](#default-policies). Required on every instance role. | `string` | — | yes |
| `additional_policy_arns` | Additional managed policy ARNs to attach beyond the [default policies](#default-policies). | `list(string)` | `[]` | no |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the EC2 instance IAM role |
| `instance_profile_name` | Name of the EC2 instance profile |
| `instance_profile_arn` | ARN of the EC2 instance profile |

## Usage

```hcl
module "ec2_instance_role" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/iam/roles/ec2?ref=main"

  venue     = var.venue
  component = var.component

  # Account/environment-specific — see "Default Policies" above
  ec2users_dynamodb_table_arn = "arn:aws:dynamodb:<region>:<account-id>:table/ec2users"

  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "ec2_instances" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/ec2?ref=main"

  ami_id            = var.ami_id
  instance_profile  = module.ec2_instance_role.instance_profile_name

  ec2_instance_configs = [
    {
      instance_name   = "pds-worker"
      instance_type   = "t3.medium"
      subnet_id       = var.subnet_id
      security_groups = [var.security_group_id]
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
