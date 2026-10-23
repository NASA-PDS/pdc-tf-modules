# EC2 Module

## Known Consumers

| Repository | Source Reference | Notes |
|------------|-----------------|-------|
| [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) | `?ref=main` (`terraform/logstash`) | Logstash EC2. |
| [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) | Local path `../../pds-tf-modules/terraform/modules/ec2` | Not a versioned git ref — developer workspace coupling |

---

**Prerequisite:** this module looks up an existing IAM instance profile by name — it does not create one. Create the role/profile first with the [`iam/roles/ec2`](../iam/roles/ec2) module (see its README for usage), then pass the resulting `instance_profile_name` output into this module's `instance_profile` input.

Provisions one or more EC2 instances (via a launch template + `aws_instance`) in a PDC AWS environment. The AMI is **not** auto-selected — `ami_id` must be the exact, SA-provided AMI ID for the target venue. It defaults to `ami-0ed8a3d7cef9ee5b2`, the current SA-provided AMI used across the system; override it explicitly if a different AMI is required. The instance profile is **not created by this module**; it looks up an existing instance profile by name via `instance_profile`. Use the [`iam/roles/ec2`](../iam/roles/ec2) module to create that role/profile (e.g. `pds-cds-<venue>-ec2-role`), or reference another venue-scoped role created elsewhere.

Every instance is tagged `Patch = "true"` (in addition to `required_tags` and `Name`) so it is picked up by patching automation.

Instances are **private by default** — `associate_public_ip_address` defaults to `false`, so no public IP is assigned unless a consumer explicitly opts in via that variable.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `ec2_instance_configs` | List of EC2 instance configuration objects (see below) | `list(any)` | `[]` | yes |
| `ami_id` | AMI ID for the EC2 instances. Must be the exact SA-provided AMI ID for the target venue — override the default. | `string` | `"ami-0ed8a3d7cef9ee5b2"` | no |
| `instance_profile` | Name of an existing EC2 instance profile (e.g. from the [`iam/roles/ec2`](../iam/roles/ec2) module's `instance_profile_name` output) | `string` | `""` | yes |
| `associate_public_ip_address` | Whether to associate a public IP address for all EC2 instances created by this module. **Defaults to `false`** — instances are not internet-reachable unless explicitly opted in. | `bool` | `false` | no |
| `bastion_target_sg_ssm_path` | SSM path for the bastion target SG ID (e.g. `/pds/<component>/bastion-core/target-security-group-id`). When set, that SG is appended to every instance's security groups, enabling SSH from the bastion. Empty (default) skips it — set empty on the bastion EC2 itself to avoid a self-referencing loop. | `string` | `""` | no |
| `disable_api_termination` | Enable EC2 termination protection. Prevents accidental deletion via the AWS console or API. Terraform handles disabling this automatically before a `destroy`. | `bool` | `true` | no |
| `pds_resource_prefix` | Optional prefix for resource naming (e.g., `pds-dev-gh01dc`) | `string` | `""` | no |
| `root_volume_delete_on_termination` | Delete the root EBS volume when the instance terminates. Defaults to `false` to preserve existing behavior for current consumers. | `bool` | `false` | no |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | yes |

### `ec2_instance_configs` object shape

Each entry in `ec2_instance_configs` supports:

| Key | Description | Required | Default |
|-----|-------------|----------|---------|
| `instance_name` | Name for the instance (combined with `pds_resource_prefix` if set) | yes | — |
| `instance_type` | EC2 instance type (e.g. `t3.medium`) | yes | — |
| `subnet_id` | Subnet ID to launch the instance in | yes | — |
| `security_groups` | List of security group IDs. Prefer a dedicated SG scoped to this instance/component over reusing a broad, shared SG — see [Usage](#usage) below. | yes | — |
| `key_pair_name` | SSH key pair name | no | `null` |
| `user_data` | Instance user data | no | `null` |
| `az` | Availability zone override for the instance | no | `null` |
| `root_volume_size` | Root EBS volume size in GB | no | `30` |
| `root_volume_type` | Root EBS volume type | no | `"gp3"` |

The root EBS volume is always encrypted. Whether it is deleted on termination is controlled by `root_volume_delete_on_termination` (default `false`). IMDSv2 is required (`http_tokens = "required"`).

## Outputs

| Name | Description |
|------|-------------|
| `ec2_instance_id` | List of IDs of the created EC2 instances |
| `ec2_public_ip` | List of public IPs (empty string per instance when none assigned; changes on stop/start unless an EIP is attached) |

## Usage

A dedicated, purpose-scoped security group is recommended over reusing a broad, shared one — see the [`security-groups`](../security-groups) module. A shared SG tends to accumulate rules over time as unrelated services reuse it, so any one instance ends up with more open ports/sources than it actually needs.

```hcl
module "ec2_instance_role" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/iam/roles/ec2?ref=main"

  venue     = var.venue
  component = var.component

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}

module "ec2_security_group" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/security-groups?ref=main"

  vpc_id = var.vpc_id

  security_groups = [
    {
      name        = "${var.component}-ec2-sg"
      description = "Dedicated SG for the ${var.component} EC2 instances"
      sg_name_tag = "${var.component}-ec2-sg"
      ingress_rules = [
        {
          description = "SSH from the bastion/VPN CIDR only"
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_blocks = [var.management_cidr]
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

module "ec2" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/ec2?ref=main"

  ami_id                     = var.ami_id
  instance_profile           = module.ec2_instance_role.instance_profile_name
  bastion_target_sg_ssm_path = "/pds/<component>/bastion-core/target-security-group-id"

  ec2_instance_configs = [
    {
      instance_name   = "pds-worker"
      instance_type   = "t3.medium"
      subnet_id       = var.subnet_id
      security_groups = module.ec2_security_group.security_group_id
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

> **Bastion SSH access:** set `bastion_target_sg_ssm_path` to the SSM path published by the bastion stack (e.g. `/pds/cds-infra/bastion-core/target-security-group-id`). The module reads the SG ID and appends it automatically — no manual data source needed. Leave empty to skip.
>
> **Termination protection:** `disable_api_termination` defaults to `true` — instances are protected against accidental deletion via the console or API. Set `false` for ephemeral test instances.
>
> **SSM Session Manager** (via `AmazonSSMManagedInstanceCore`, attached by the [`iam/roles/ec2`](../iam/roles/ec2) module) needs no inbound rule and is the recommended access path for day-to-day operations.
