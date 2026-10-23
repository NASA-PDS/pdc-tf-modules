# EC2 Module

## Known Consumers

| Repository | Source Reference | Notes |
|------------|-----------------|-------|
| [o11y-cloudfront-batch](https://github.com/NASA-PDS/o11y-cloudfront-batch) | `?ref=main` (`terraform/logstash`) | Logstash EC2. |
| [pdc-cds-infra](https://github.com/NASA-PDS/pdc-cds-infra) | Local path `../../pds-tf-modules/terraform/modules/ec2` | Not a versioned git ref — developer workspace coupling |

---

**Prerequisite:** this module attaches an existing IAM instance profile by name — it does not create one. Create the role/profile first with the [`iam/roles/ec2`](../iam/roles/ec2) module (see its README for usage), then pass the resulting `instance_profile_name` output into this module's `instance_profile` input.

Provisions one or more EC2 instances (plain `aws_instance` resources) in a PDC AWS environment. The AMI is **not** auto-selected — `ami_id` is required and must be the exact, SA-provided AMI ID for the target venue. The instance profile is **not created by this module**; it attaches an existing instance profile by name via `instance_profile`. Use the [`iam/roles/ec2`](../iam/roles/ec2) module to create that role/profile (e.g. `pds-cds-<venue>-ec2-role`), or reference another venue-scoped role created elsewhere.

Every instance is tagged `Patch = "true"` (in addition to `required_tags` and `Name`) so it is picked up by patching automation.

Instances are **private by default** — `associate_public_ip_address` defaults to `false`, so no public IP is assigned unless a consumer explicitly opts in via that variable.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `ec2_instance_configs` | List of EC2 instance configuration objects (see below) | `list(object)` | `[]` | yes |
| `ami_id` | AMI ID for the EC2 instances. Must be the exact SA-provided AMI ID for the target venue. | `string` | — | yes |
| `instance_profile` | Name of an existing EC2 instance profile (e.g. from the [`iam/roles/ec2`](../iam/roles/ec2) module's `instance_profile_name` output) | `string` | `""` | yes |
| `associate_public_ip_address` | Whether to associate a public IP address for all EC2 instances created by this module. **Defaults to `false`** — instances are not internet-reachable unless explicitly opted in. | `bool` | `false` | no |
| `bastion_target_sg_ssm_path` | SSM path for the bastion target SG ID (e.g. `/pds/<component>/bastion-core/target-security-group-id`). When set, that SG is appended to every instance's security groups, enabling SSH from the bastion. Empty (default) skips it — set empty on the bastion EC2 itself to avoid a self-referencing loop. | `string` | `""` | no |
| `disable_api_termination` | Enable EC2 termination protection. Prevents accidental deletion via the AWS console or API. Terraform handles disabling this automatically before a `destroy`. | `bool` | `true` | no |
| `pds_resource_prefix` | Optional prefix for resource naming (e.g., `pds-<venue>-<component>`) | `string` | `""` | no |
| `root_volume_delete_on_termination` | Delete the root EBS volume when the instance terminates. Defaults to `false`. | `bool` | `false` | no |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | yes |

### `ec2_instance_configs` object shape

`ec2_instance_configs` is a typed list of objects. Each entry supports the keys below; the input is validated, so a missing required key, a duplicate `instance_name` or an empty `security_groups` list fails at plan time. Instances are keyed by `instance_name`, so adding, removing or reordering entries never replaces unrelated instances.

| Key | Description | Required | Default |
|-----|-------------|----------|---------|
| `instance_name` | Unique name for the instance (combined with `pds_resource_prefix` if set). Also the key of the module outputs. | yes | — |
| `instance_type` | EC2 instance type (e.g. `t3.medium`). See [Changing an existing instance](#changing-an-existing-instance). | yes | — |
| `subnet_id` | Subnet ID to launch the instance in | yes | — |
| `security_groups` | List of security group IDs. Prefer a dedicated SG scoped to this instance/component over reusing a broad, shared SG — see [Usage](#usage) below. | yes | — |
| `key_pair_name` | SSH key pair name | no | `null` |
| `user_data` | Instance user data, **already base64-encoded** (e.g. `base64encode(templatefile(...))`). Passed to the instance as `user_data_base64`. | no | `null` |
| `az` | Availability zone override for the instance | no | `null` |
| `root_volume_size` | Root EBS volume size in GB | no | `50` |
| `root_volume_type` | Root EBS volume type | no | `"gp3"` |
| `ignore_instance_profile_changes` | Set `true` for an instance whose IAM instance profile is swapped outside Terraform after boot, so later applies do not revert it. See [Instances whose IAM instance profile is swapped outside Terraform](#instances-whose-iam-instance-profile-is-swapped-outside-terraform). | no | `false` |

The root EBS volume is always encrypted. Whether it is deleted on termination is controlled by `root_volume_delete_on_termination` (default `false`). IMDSv2 is required (`http_tokens = "required"`).

## Outputs

| Name | Description |
|------|-------------|
| `instance_ids` | Map of `instance_name` to EC2 instance ID |
| `public_ips` | Map of `instance_name` to public IP (empty string when none assigned; changes on stop/start unless an EIP is attached) |
| `private_ips` | Map of `instance_name` to private IP |

Outputs are maps keyed by `instance_name`, e.g. `module.ec2.instance_ids["pds-worker"]`.

## Changing an existing instance

Every setting is declared on `aws_instance`, so Terraform plans every change. How the AWS provider applies them:

| Change | Result |
|--------|--------|
| `tags`, `required_tags`, `pds_resource_prefix` (Name tag), `disable_api_termination` | In place, no downtime |
| `security_groups`, `bastion_target_sg_ssm_path`, `instance_profile` | In place, no downtime (`instance_profile` is not applied to instances with `ignore_instance_profile_changes = true`) |
| `instance_type`, `user_data` | In place, but the provider **stops and restarts** the instance (brief outage). The instance ID is kept. A change to an instance type with a different CPU architecture forces replacement. |
| `root_volume_size`, `root_volume_type` | In place when growing the volume or changing its type (not verified for shrinking; expect replacement) |
| `ami_id`, `subnet_id`, `az`, `key_pair_name`, `associate_public_ip_address` | **Replaces the instance** |
| `ignore_instance_profile_changes` (flipping it on an existing instance) | **Moves the instance to the other resource address** (`pds_ec2` <-> `pds_ec2_profile_unmanaged`). Add a `moved` block, or Terraform plans a replacement. See below. |

Compliance-stamped tags (`Audit`, `CreatedBy`, `CreationTime`) are ignored so they are not stripped on re-apply. By default the module manages `iam_instance_profile`: if a stack swaps the instance profile after boot, a later apply puts the configured profile back. Opt out per instance with `ignore_instance_profile_changes` (next section).

The primary network interface is not tagged separately (`aws_instance` has no argument for it); it relies on provider `default_tags`.

## Instances whose IAM instance profile is swapped outside Terraform

Some hosts launch with a bootstrap profile that has broader access (for example, to fetch secrets at first boot) and are then moved by hand to a locked-down profile once setup finishes. A normal apply would put the configured profile back, undoing the hardening.

Set `ignore_instance_profile_changes = true` on that instance's entry. The profile is set at launch from `instance_profile` and is never changed by later applies, whatever value `instance_profile` has afterwards:

```hcl
ec2_instance_configs = [
  {
    instance_name                   = "app"
    instance_type                   = "t3.large"
    subnet_id                       = var.subnet_id
    security_groups                 = [aws_security_group.app.id]
    ignore_instance_profile_changes = true
  }
]
```

Notes:

- `lifecycle.ignore_changes` only accepts literal attribute names, so the module cannot toggle it with a variable. Instances with the flag are created by `aws_instance.pds_ec2_profile_unmanaged`; all others by `aws_instance.pds_ec2`. The two resources are identical apart from that, and the test suite asserts it. Outputs include both.
- The flag only affects the `iam_instance_profile` attribute. It does not stop Terraform from recreating the instance for other reasons (AMI, subnet, ...); a replacement launches with `instance_profile` again, so repeat the manual swap afterwards.
- Choose the flag when the instance is created. Adding or removing it on an existing instance changes its resource address, so move the state or Terraform plans a replacement:

```hcl
moved {
  from = module.ec2.aws_instance.pds_ec2["app"]
  to   = module.ec2.aws_instance.pds_ec2_profile_unmanaged["app"]
}
```

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
