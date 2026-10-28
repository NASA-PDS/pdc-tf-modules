# pdc-tf-modules

Reusable Terraform modules for NASA PDS infrastructure deployed to PDC (Planetary Data Cloud) AWS environments.

## Module Status

| Module | Status | Known Consumers |
|--------|--------|-----------------|
| [`s3/bucket`](terraform/modules/s3) | ✅ Actively used | [data-upload-manager](https://github.com/NASA-PDS/data-upload-manager), [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra), [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) |
| [`s3/object`](terraform/modules/s3) | ✅ Actively used | [data-upload-manager](https://github.com/NASA-PDS/data-upload-manager), [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) |
| [`ec2`](terraform/modules/ec2) | ✅ Actively used | [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) (Logstash EC2), [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) (local path ref — not consumed via git ref) |
| [`ecs`](terraform/modules/ecs) | ❓ Untested | None |
| [`iam/roles`](terraform/modules/iam/roles) | ❓ Untested | None |
| [`iam/roles/ec2`](terraform/modules/iam/roles/ec2) | ✅ Actively used | [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) |
| [`alb`](terraform/modules/alb) | ❓ Untested | None |
| [`cognito`](terraform/modules/cognito) | ❓ Untested | None |
| [`opensearch-serverless`](terraform/modules/opensearch-serverless) | ❓ Untested | None |
| [`security-groups`](terraform/modules/security-groups) | ❓ Untested | None |
| `cloudfront` | 🗃️ Archived | Moved to `terraform.archive/` |

**Legend:**
- ✅ **Actively used** — confirmed production consumers in the NASA-PDS org
- ⚠️ **Internal/local use only** — consumed via a local filesystem path, not a versioned git ref
- ❓ **Untested** — module exists but has no known external consumers; use with caution
- 🗃️ **Archived** — no longer maintained; kept for historical reference only

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- AWS credentials with appropriate PDC tenant permissions
- SSH access to this repository (required by Terraform to fetch modules via `git@github.com:...`)

See [terraform/modules/s3/README.md](terraform/modules/s3/README.md) for SSH key setup instructions.

## Quick Start

Reference a module in your Terraform configuration:

```hcl
module "s3_bucket" {
  source      = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/s3/bucket?ref=main"
  bucket_name = var.s3_bucket_name
  partition   = var.partition

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```

> **Tip:** Always pin to a specific tag or commit ref (`?ref=v1.2.3` or `?ref=<commit-sha>`) rather than a branch name to avoid unexpected changes on `terraform init`.

Then initialize:

```sh
terraform init
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
```

## Required Tags

Every module accepts a `required_tags = map(string)` variable with these standard organizational tags:

| Tag | Description |
|-----|-------------|
| `tenant` | PDC tenant identifier (e.g. `en`) |
| `venue` | Deployment environment (e.g. `pds-cds-dev`) |
| `component` | Application component name |
| `cicd` | CI/CD method (e.g. `terraform`, `pds-github`) |
| `managedby` | Owner email or team identifier |

## Repository Structure

```
terraform/
├── main.tf          # Root orchestration — calls all modules
├── variables.tf     # Top-level input variables
├── outputs.tf       # Root outputs
├── provider.tf      # AWS provider + S3 remote backend
├── modules/         # Reusable modules (see status table above)
└── tfvars/          # Environment-specific var files (dev.tfvars, etc.)
terraform.archive/   # Archived modules no longer in active use
```

## Secret Detection

This repo uses [`detect-secrets`](https://github.com/Yelp/detect-secrets) to prevent credentials from being committed.

### How it works

- **Pre-commit hook** — `scripts/detect_secrets_baseline.sh` runs automatically on every commit and checks for new or unresolved findings.
- **GitHub Actions workflow** — `.github/workflows/secrets-detection.yaml` runs the same check on every push and pull request to `main`.
- **Baseline file** — `.secrets.baseline` tracks all known false positives that have been audited and confirmed safe.
- **Exclusions file** — `.detect-secrets-ignore` lists path patterns (regexes, one per line) that are excluded from scanning for this repo.

### First-time setup

```sh
pip install detect-secrets~=1.5.0
pre-commit install
```

### Handling a new finding

If a commit is blocked or CI fails with a secret detection warning:

1. **Regenerate the baseline** to capture the new finding:
   ```sh
   scripts/detect_secrets_baseline.sh scan
   ```

2. **Audit each finding** — classify it as a real secret or a false positive:
   ```sh
   scripts/detect_secrets_baseline.sh audit
   ```

3. If the finding is a **real secret**, remove it from the codebase before committing.
4. If it is a **false positive**, commit the updated `.secrets.baseline`.

To permanently exclude a file path from future scans, add a regex to `.detect-secrets-ignore`.

## Contributing

If you adopt an **untested** module and it works in your environment, please open a pull request to:
1. Add your project to the Known Consumers column in the table above
2. Update the module's README with your usage example

For bugs, feature requests, or new module proposals, [open an issue](https://github.com/NASA-PDS/pdc-tf-modules/issues).

See [CONTRIBUTING.md](https://github.com/NASA-PDS/.github/blob/main/CONTRIBUTING.md) for general NASA-PDS contribution guidelines.

## Code of Conduct

All contributors are expected to abide by the [NASA-PDS Code of Conduct](https://github.com/NASA-PDS/.github/blob/main/CODE_OF_CONDUCT.md).
