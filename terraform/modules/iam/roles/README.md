> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pds-tf-modules/pulls)._

---

# IAM Role

Generic Terraform module that creates an IAM role with a permissions boundary, configurable trust relationship, and support for multiple policy attachments.

## Resources Created

- **IAM Role** — with configurable trust policy and permissions boundary
- **IAM Policies** — zero or more custom policies (created from inline documents)
- **Policy Attachments** — attaches custom policies, existing policy ARNs, and/or AWS managed policies

## Usage

### S3 Read-Only Role

```hcl
module "s3_readonly_role" {
  source = "../../modules/iam/roles"

  role_name        = "PDS-S3-ReadOnly-Staging-Logs-Role"
  role_description = "Read-only access to PDS logs and staging S3 buckets"

  assume_role_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowTenantOperatorAssume"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:sts::<account-id>:assumed-role/<venue>-en-platform-engineer"
        }
        Action = "sts:AssumeRole"
      }
    ]
  }

  custom_policies = {
    "PDS-S3-ReadOnly-Staging-Logs" = {
      description = "Read-only access to PDS logs and staging S3 buckets"
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "ListBuckets"
            Effect   = "Allow"
            Action   = ["s3:ListBucket", "s3:GetBucketLocation"]
            Resource = ["arn:aws:s3:::pds-logs-dev", "arn:aws:s3:::pds-*-staging-dev"]
          },
          {
            Sid      = "ReadObjects"
            Effect   = "Allow"
            Action   = ["s3:GetObject", "s3:GetObjectVersion", "s3:GetObjectTagging"]
            Resource = ["arn:aws:s3:::pds-logs-dev/*", "arn:aws:s3:::pds-*-staging-dev/*"]
          }
        ]
      }
    }
  }

  required_tags = {
    tenant    = "en"
    venue     = "pds-cds-dev"
    component = "s3-readonly-role"
    cicd      = "terraform"
    managedby = "your.email@jpl.nasa.gov"
  }
}
```

### ECS Task Role with Mixed Policy Types

```hcl
module "ecs_task_role" {
  source = "../../modules/iam/roles"

  role_name        = "PDS-ECS-Task-Role"
  role_description = "PDS Registry ECS Task Role"

  assume_role_policy = {
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Action    = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = "123456789012"
          }
        }
      }
    ]
  }

  custom_policies = {
    "PDS-ECS-CloudWatch-Policy" = {
      description = "Allow ECS tasks to create CloudWatch log groups"
      policy_document = {
        Version = "2012-10-17"
        Statement = [
          {
            Sid      = "CloudWatchAccess"
            Effect   = "Allow"
            Action   = "logs:CreateLogGroup"
            Resource = "arn:aws:logs:*:*:*"
          }
        ]
      }
    }
  }

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]

  required_tags = {
    tenant    = "en"
    venue     = "pds-cds-dev"
    component = "ecs-task-role"
    cicd      = "terraform"
    managedby = "your.email@jpl.nasa.gov"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `role_name` | Name of the IAM role | `string` | — | yes |
| `role_description` | Description of the IAM role | `string` | `""` | no |
| `assume_role_policy` | Trust relationship policy document (JSON-encoded by the module) | `any` | — | yes |
| `permissions_boundary_policy_name` | Name of the permissions boundary policy | `string` | `""` | no |
| `custom_policies` | Map of custom policies to create and attach (key = policy name) | `map(object({description, policy_document}))` | `{}` | no |
| `custom_policy_arns` | List of existing IAM policy ARNs to attach | `list(string)` | `[]` | no |
| `managed_policy_arns` | List of AWS managed policy ARNs to attach | `list(string)` | `[]` | no |
| `required_tags` | Required resource tags (must include: tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `role_arn` | ARN of the created IAM role |
| `role_name` | Name of the created IAM role |
| `custom_policy_arns` | Map of custom policy names to their ARNs |
