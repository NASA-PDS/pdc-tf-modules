# Example: bastion-ssh-verify

Deploys a minimal `t3.micro` EC2 in a private subnet to verify end-to-end
SSH access through the CDS core bastion host. Run it, SSH in from the bastion,
then destroy it.

## What this tests

| Acceptance criterion | How verified |
|---|---|
| Bastion target SG is attached and allows inbound SSH from the bastion | `ssh <user>@<private-ip>` succeeds from the bastion |
| DynamoDB SSH auth is working (ec2-users table lookup) | Login succeeds using your personal key — no key pair needed |
| `sudo -iu pdsops` works on the target EC2 | Run it after logging in |
| `bastion_target_sg_ssm_path` wires up correctly via the ec2 module | No manual SG ID lookup needed — the module reads it from SSM |

## Prerequisites

- `pdc-cds-infra/bastion-core` deployed in the target venue
- Your SSH key enrolled in the `ec2-users` DynamoDB table

## Deploy

All commands run from a checkout of `cds-infra-deploy`:

```bash
task apply VENUE=dev COMPONENT=tests/bastion-ssh-verify
```

## Verify

**Step 1 — get the private IP:**

```bash
INSTANCE_ID=$(cd venues/dev/tests/bastion-ssh-verify && terragrunt output -raw instance_id | tail -1)
PRIVATE_IP=$(aws ec2 describe-instances \
  --instance-ids "${INSTANCE_ID}" \
  --query 'Reservations[0].Instances[0].PrivateIpAddress' \
  --output text --region us-west-2)
echo "${PRIVATE_IP}"
```

**Step 2 — SSH through the bastion directly to the test EC2 (run locally):**

```bash
USER="<your-username>"
ZONE=$(aws ssm get-parameter \
  --name /pds/hosted-zone/name \
  --query Parameter.Value --output text --region us-west-2)
ssh -J ${USER}@pds-cds-bastion-core.${ZONE} ${USER}@${PRIVATE_IP}
```

**Step 3 — confirm pdsops access (run on the test EC2):**

```bash
sudo -iu pdsops
```

**Step 4 — confirm DynamoDB auth worked:**

If you reached a shell in steps 2 and 3 with no password or key-pair prompt,
DynamoDB-based authentication is working end-to-end.

## Destroy

```bash
task destroy VENUE=dev COMPONENT=tests/bastion-ssh-verify
```

The test EC2 and its security group are removed. The bastion-core stack is
unaffected.
