# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Terraform modules repository for NASA PDS (Planetary Data System) infrastructure deployed to PDC (Planetary Data Cloud) AWS environments. It contains reusable Terraform modules alongside root-level orchestration config.

## Development Commands

### Terraform

```bash
# Initialize Terraform (required before other commands)
terraform -chdir=terraform init

# Format check
terraform -chdir=terraform fmt -check -recursive

# Validate configuration
terraform -chdir=terraform validate

# Plan with dev environment vars
terraform -chdir=terraform plan -var-file=tfvars/dev.tfvars

# Apply (auto-approve used in CI)
terraform -chdir=terraform apply -var-file=tfvars/dev.tfvars
```

### Python / Testing

```bash
# Run all tests, lint, and docs
tox

# Run only unit tests
pytest

# Run only linting (pre-commit against all files)
tox -e lint

# Build docs
tox -e docs
```

### Pre-commit

```bash
# Install hooks (one-time setup)
pre-commit install

# Run against all files manually
pre-commit run --all-files

# Regenerate secrets baseline (uses scripts/detect_secrets_baseline.sh internally)
scripts/detect_secrets_baseline.sh scan

# Interactively audit findings and mark as real or false positive
scripts/detect_secrets_baseline.sh audit
```

## Architecture

### Directory Structure

```
terraform/
├── main.tf          # Root orchestration — calls all modules
├── variables.tf     # Top-level input variables
├── outputs.tf       # Root outputs
├── provider.tf      # AWS provider + S3 remote backend
├── modules/         # Reusable modules (see below)
└── tfvars/          # Environment-specific var files (dev.tfvars, etc.)
```

### Modules

Located in `terraform/modules/`:

| Module | Description |
|--------|-------------|
| `s3/bucket` | S3 bucket creation with policy, versioning, encryption |
| `s3/object` | S3 object management |
| `ecs` | ECS clusters, task definitions, and services — **YAML-driven** (loads config from YAML files) |
| `ec2` | EC2 instance provisioning (takes a list of instance configs) |
| `iam/roles` | IAM role + policy management |
| `alb` | Application Load Balancer |
| `cloudfront` | CloudFront distribution with optional CloudFront Functions (JS) |
| `cognito` | Cognito user pools and app clients |
| `security-groups` | VPC security group creation |
| `opensearch-serverless` | OpenSearch Serverless collections with encryption/network policies |

### Key Design Patterns

**`required_tags`** — Every module accepts a `required_tags = map(string)` variable containing standard organizational tags: `tenant`, `venue`, `component`, `cicd`, `managedby`. Always pass these through when creating new modules.

**YAML-driven ECS config** — The ECS module reads cluster, task definition, and service definitions from YAML files rather than HCL variables. When modifying ECS resources, look at the YAML config files alongside the Terraform.

**Submodule organization** — S3 and IAM use nested submodule paths (`s3/bucket`, `s3/object`, `iam/roles`) to separate concerns. New grouped resources should follow this pattern.

**Remote state** — Terraform state lives in S3. The backend config in `provider.tf` uses a configured S3 bucket and key.

### CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `terraform_cicd.yaml` — Main workflow: init → fmt → validate → plan → apply. Uses AWS OIDC for authentication (no long-lived credentials). Auto-applies on merges to `main`.
- `branch_cicd.yaml` — Branch-specific workflow for PR validation.

### Secret Detection

`detect-secrets` is enforced via pre-commit using `.secrets.baseline`. Known false positives (e.g., email addresses in READMEs) are allowed in the baseline. When the pre-commit hook blocks a commit due to new secrets findings, either remediate the secret or update the baseline after confirming it's a false positive.

The Terraform-specific pre-commit hooks (tflint, terraform_fmt, terraform_validate, terrascan, tfsec) are present in `.pre-commit-config.yaml` but commented out — they are planned for future activation.
