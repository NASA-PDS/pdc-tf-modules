# bastion

Reusable bastion host for SSH access to private EC2 instances within a VPC.

The module creates the bastion EC2 (via the sibling [`ec2`](../ec2) module), its security group, an optional Elastic IP,
and a **target security group** that callers attach to private EC2s so they accept SSH from the bastion only.

**IAM is not managed here** (P19: IAM resources are deployed by a separate, higher-privilege stack). The caller creates
the instance profile and passes its name in via `instance_profile_name`.

> **JPL network:** to SSH to a bastion from the JPL network, the bastion's public IP must be added to a JPL-managed
> whitelist. See [JPL network whitelist](#jpl-network-whitelist).
>
> **Testing:** every bastion must be tested in every new environment. See
> [Testing the bastion host](#testing-the-bastion-host).

## Where bastions are deployed

This module is used by the stacks below. Each one adds the IAM role, the DNS record and the SSM parameters around it, and
has its own deployment guide.

| Repository | Path | Used for |
|------------|------|----------|
| [`pdc-tenant-infra`](https://github.com/NASA-PDS/pdc-tenant-infra) | `terraform/deployments/bastion` and `terraform/deployments/bastion/iam` | Tenant (PDS node) accounts |
| [`pdc-cds-infra`](https://github.com/NASA-PDS/pdc-cds-infra) | `terraform/bastion-core` and `terraform/bastion-core/iam` | CDS accounts |

Both repositories are private. Their guides cover deployment order, per-venue inputs and the SSM parameters each stack
publishes. This README covers what applies to every bastion built from the module.

## Resources

| Resource | Description |
|----------|-------------|
| `aws_security_group.bastion` | Inbound SSH from `allowed_ssh_cidrs`; egress SSH to `private_subnet_cidr`, HTTPS to `0.0.0.0/0` |
| `aws_security_group.target` | Inbound SSH from the bastion SG only. Attach to private EC2s |
| `module.ec2` | Instance (encrypted root volume, IMDSv2 required) |
| `aws_eip.bastion` + `aws_eip_association.bastion` | EIP allocation and instance association are separate resources — the EIP survives instance replacement without being destroyed |

The HTTPS egress rule (`0.0.0.0/0:443`) is intentionally open-world: the SSM Agent and OS package updates need it and
the bastion has no VPC endpoints. SSH egress is scoped to `private_subnet_cidr`. DNS and NTP traffic to the VPC
resolver / Amazon Time Sync address are link-local and are not filtered by security groups.

## Authentication

The module does not manage SSH keys. Authentication is determined by the AMI and the instance profile: the SA-provided
AMI validates each login against the `ec2users` DynamoDB table, so the caller's instance profile must allow
`dynamodb:GetItem/Query/Scan` on that table. Your SSH key must be enrolled in the table by the SA team before you can
log in.

Attach `AmazonSSMManagedInstanceCore` to the role so the instance registers with SSM. Whether a user can then start an
SSM Session Manager session (passwordless `sudo` as `ssm-user`) is decided by that user's own IAM role
(`ssm:StartSession`), not by the instance role.

The SA-provided AMI pre-provisions a shared `pdsops` service account on every EC2. Once logged in as your personal
user, switch to it with:

```bash
sudo -iu pdsops
```

## JPL network whitelist

**A bastion that you want to SSH into from the JPL network needs its public IP added to a JPL-managed whitelist.** This
applies to every bastion built from this module, in every venue and for every tenant.

- The whitelist is managed by JPL, outside AWS and outside this repository. Terraform cannot create the entry: request
  it through the JPL process for adding to the whitelist.
- Submit the bastion's public IP. It is the `bastion_public_ip` output (the Elastic IP when `assign_eip = true`).
- Request it after the first apply and before testing connectivity. SSH from the JPL network is not expected to work
  until the entry exists.
- It is separate from `allowed_ssh_cidrs`. That input controls which source networks the AWS security group admits to
  the bastion; the whitelist is JPL's permission to reach the bastion's address. Reaching the bastion from the JPL
  network needs both.
- Keep `assign_eip = true`. The Elastic IP survives instance replacement and stop/start, so the whitelisted address stays
  valid. Without it the public IP changes on stop/start and the whitelist entry no longer matches. A new Elastic IP (a new
  venue, or an Elastic IP that was destroyed and recreated) needs a new request.

To read the IP from a deployed bastion, use the Terraform output or the SSM parameter the calling stack publishes for it:

```bash
EIP_SSM_PATH="<ssm-path-of-the-eip-parameter>"
aws ssm get-parameter --name "${EIP_SSM_PATH}" \
  --query Parameter.Value --output text --region us-west-2
```

If SSH to the bastion times out from the JPL network while your source network is listed in `allowed_ssh_cidrs`,
confirm that the whitelist entry exists for the bastion's current public IP.

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
  required_tags         = { tenant = "<tenant>", venue = "<venue>", component = "<component>", cicd = "iac", managedby = "<email>" }
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

With the [`ec2`](../ec2) module, set `bastion_target_sg_ssm_path` to the SSM parameter the calling stack publishes for the
target security group, and the module attaches it for you.

## Connecting

Connect to the bastion by its DNS name (the calling stack creates the record) or its Elastic IP. From the JPL network,
the bastion's IP must already be whitelisted (see [JPL network whitelist](#jpl-network-whitelist)).

```bash
NASA_ID="<nasa-id>"
BASTION_HOST="<bastion-dns-name-or-eip>"
ssh ${NASA_ID}@${BASTION_HOST}
```

To reach a private EC2, SSH to the bastion first, then to the instance. `ssh -J` (ProxyJump) hangs on the first
connection to a new host because both hops prompt for host-key verification but only the first has an interactive
terminal. Accept each host key interactively before relying on ProxyJump.

Where your IAM role allows `ssm:StartSession`, you can also open a shell without SSH. This is for break-glass use:

```bash
INSTANCE_ID="<bastion-instance-id>"
aws ssm start-session --target "${INSTANCE_ID}" --region us-west-2
```

## Testing the bastion host

**A bastion must be tested in every new environment**: in each venue after it is first deployed, and again after any
change to the venue's network or to the bastion's AMI, subnet or security groups. Do not rely on a bastion until all
checks pass.

1. **The instance is healthy.** It is `running` and registered with SSM (`Online`):

   ```bash
   REGION="us-west-2"
   INSTANCE_ID="<bastion-instance-id>"

   aws ec2 describe-instances --instance-ids "${INSTANCE_ID}" \
     --query 'Reservations[0].Instances[0].{PublicIP:PublicIpAddress,State:State.Name,Profile:IamInstanceProfile.Arn}' \
     --output table --region ${REGION}

   aws ssm describe-instance-information \
     --filters "Key=InstanceIds,Values=${INSTANCE_ID}" \
     --query 'InstanceInformationList[*].{Status:PingStatus,Agent:AgentVersion}' \
     --output table --region ${REGION}
   ```

2. **You can SSH to the bastion.** From the JPL network this requires the whitelist entry. Use the command under
   [Connecting](#connecting).
3. **You can SSH from the bastion to a private EC2** in the venue's VPC that has the target security group attached. Use
   an existing instance or launch a temporary one, and terminate the temporary one afterwards. The
   [`bastion-ssh-verify`](../../examples/bastion-ssh-verify) example launches a suitable instance.

## Troubleshooting

**SSH to the bastion times out.** Check, in order: the bastion is `running`; your source network is in
`allowed_ssh_cidrs`; the subnet has a route to an internet gateway; and, from the JPL network, the bastion's current
public IP is on the JPL-managed whitelist.

**SSM shows `TargetNotConnected` or goes offline after the first deploy.** The SSM Agent started before the outbound HTTPS
rule was in place and entered exponential backoff. If SSH works, restart the agent; otherwise reboot the instance (the
Elastic IP keeps the address):

```bash
sudo systemctl restart amazon-ssm-agent
```

```bash
INSTANCE_ID="<bastion-instance-id>"
aws ec2 reboot-instances --instance-ids "${INSTANCE_ID}" --region us-west-2
```

**SSH `Permission denied`.** Read the sshd log from an SSM session with `sudo tail -50 /var/log/secure`:

| Log message | Cause |
|-------------|-------|
| `Invalid user <name>` | The OS user does not exist yet; the DynamoDB lookup never ran. Usually paired with the algorithm error below |
| `ssh-ed25519 not in PubkeyAcceptedAlgorithms` | sshd rejects ed25519 before the DynamoDB lookup runs. Use an RSA key, or ask the SA team to add ed25519 to the AMI baseline |
| `Permission denied (publickey)` | The key is not enrolled in the `ec2users` table. Ask the SA team to enroll it |

The `Invalid user` and algorithm errors occur before DynamoDB is consulted, so an enrolled key still fails if the
algorithm is not accepted.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `name_prefix` | Prefix for all resource names (e.g. `pds-cds`) | `string` | n/a | yes |
| `resource_name` | Suffix identifying this bastion; names become `<name_prefix>-<resource_name>-sg`, `-target-sg`, `-eip`, and the instance Name tag | `string` | `"bastion"` | no |
| `vpc_id` | VPC to deploy into | `string` | n/a | yes |
| `subnet_id` | Public subnet for the bastion | `string` | n/a | yes |
| `ami_id` | AMI ID (SA-provided) | `string` | n/a | yes |
| `instance_type` | EC2 instance type; must have at least 4 GiB of memory (`nano`, `micro`, and `small` sizes are rejected) | `string` | `"t3.medium"` | no |
| `allowed_ssh_cidrs` | CIDRs allowed to SSH to the bastion on 22. This is the AWS security group only; the JPL whitelist is separate | `list(string)` | n/a | yes |
| `private_subnet_cidr` | CIDR of the private target subnet(s); bastion SSH egress is scoped to this | `string` | n/a | yes |
| `instance_profile_name` | Existing IAM instance profile to attach (created by the caller) | `string` | n/a | yes |
| `assign_eip` | Attach an Elastic IP so the address survives instance replacement. Keep `true` for any bastion reached from the JPL network | `bool` | `true` | no |
| `required_tags` | Required tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `bastion_instance_id` | Instance ID of the bastion |
| `bastion_eip` | Elastic IP; `null` when `assign_eip = false` |
| `bastion_public_ip` | EIP when assigned, otherwise the instance's dynamic public IP (changes on stop/start). Use for DNS records and for the JPL whitelist request |
| `bastion_security_group_id` | Bastion SG ID |
| `target_security_group_id` | SG to attach to private EC2s reachable via this bastion |
