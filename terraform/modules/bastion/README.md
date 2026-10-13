# bastion

Reusable bastion host for SSH access to private EC2 instances within a VPC.

The module creates the bastion EC2 (via the sibling [`ec2`](../ec2) module), its security group, an optional Elastic IP,
and a **target security group** that callers attach to private EC2s so they accept SSH from the bastion only.

**IAM is not managed here** (P19: IAM resources are deployed by a separate, higher-privilege stack). The caller creates
the instance profile and passes its name in via `instance_profile_name`.

## Resources

| Resource | Description |
|----------|-------------|
| `aws_security_group.bastion` | Inbound SSH from `allowed_ssh_cidrs`; egress SSH to `private_subnet_cidr`, HTTPS to `0.0.0.0/0` |
| `aws_security_group.target` | Inbound SSH from the bastion SG only. Attach to private EC2s |
| `module.ec2` | Launch template + instance (encrypted root volume, IMDSv2 required) |
| `aws_eip.bastion` | Optional, controlled by `assign_eip` |

The HTTPS egress rule (`0.0.0.0/0:443`) is intentionally open-world: the SSM Agent and OS package updates need it and
the bastion has no VPC endpoints. SSH egress is scoped to `private_subnet_cidr`. DNS and NTP traffic to the VPC
resolver / Amazon Time Sync address are link-local and are not filtered by security groups.

## Authentication

The module does not manage SSH keys. Authentication is determined by the AMI and the instance profile: the SA-provided
AMI validates each login against the `ec2users` DynamoDB table, so the caller's instance profile must allow
`dynamodb:GetItem/Query/Scan` on that table. Add `AmazonSSMManagedInstanceCore` to the role in dev/test to allow SSM
Session Manager (passwordless `sudo` as `ssm-user`).

The SA-provided AMI pre-provisions a shared `pdsops` service account on every EC2. Once logged in as your personal
user, switch to it with:

```bash
sudo -iu pdsops
```

## Usage

```hcl
module "bastion" {
  source = "git::ssh://git@github.com/NASA-PDS/pdc-tf-modules.git//terraform/modules/bastion?ref=<release-tag>"

  name_prefix           = "pds-cds"
  resource_name         = "bastion-core"
  vpc_id                = "vpc-0123456789abcdef0"
  subnet_id             = "subnet-0123456789abcdef0"   # public subnet
  ami_id                = "ami-0123456789abcdef0"
  allowed_ssh_cidrs     = ["198.51.100.0/24"]
  private_subnet_cidr   = "10.1.0.0/16"                # CIDR covering all target subnets
  instance_profile_name = "pds-cds-bastion-core-ec2-role"
  assign_eip            = true
  required_tags         = { tenant = "en", venue = "pds-cds-dev", component = "cds-infra", cicd = "iac", managedby = "terraform" }
}
```

Reaching a private EC2 through the bastion: attach `module.bastion.target_security_group_id` to the instance.

```hcl
module "app_ec2" {
  source = "../modules/ec2"
  # ...
  ec2_instance_configs = [{
    instance_name   = "app"
    instance_type   = "t3.medium"
    subnet_id       = var.private_subnet_id
    security_groups = [module.bastion.target_security_group_id]
  }]
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for all resource names (e.g. `pds-cds`) | `string` | n/a | yes |
| `resource_name` | Suffix identifying this bastion; names become `<name_prefix>-<resource_name>-sg`, `-target-sg`, `-eip`, and the instance Name tag | `string` | `"bastion"` | no |
| `vpc_id` | VPC to deploy into | `string` | n/a | yes |
| `subnet_id` | Public subnet for the bastion | `string` | n/a | yes |
| `ami_id` | AMI ID (SA-provided) | `string` | n/a | yes |
| `instance_type` | EC2 instance type | `string` | `"t3.micro"` | no |
| `allowed_ssh_cidrs` | CIDRs allowed to SSH to the bastion on 22 | `list(string)` | n/a | yes |
| `private_subnet_cidr` | CIDR of the private target subnet(s); bastion SSH egress is scoped to this | `string` | n/a | yes |
| `instance_profile_name` | Existing IAM instance profile to attach (created by the caller) | `string` | n/a | yes |
| `assign_eip` | Attach an Elastic IP so the address survives instance replacement | `bool` | `true` | no |
| `required_tags` | Required tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bastion_instance_id` | Instance ID of the bastion |
| `bastion_eip` | Elastic IP; `null` when `assign_eip = false` |
| `bastion_public_ip` | EIP when assigned, otherwise the instance's dynamic public IP (changes on stop/start). Use for DNS records |
| `bastion_security_group_id` | Bastion SG ID |
| `target_security_group_id` | SG to attach to private EC2s reachable via this bastion |
