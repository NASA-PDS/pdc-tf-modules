# Example: bastion-ssh-verify

Deploys a minimal `t3.micro` EC2 in a private subnet to verify end-to-end
SSH access through the CDS core bastion host. Run it, SSH in from the bastion,
then destroy it.

## What this tests

| Acceptance criterion | How verified |
|---|---|
| Bastion target SG is attached and allows inbound SSH from the bastion | `ssh ${USER}@bastion-ssh-verify.${ZONE}` succeeds from the bastion |
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

**Step 1 — get the DNS name and connect:**

```bash
USER="<nasa-id>"
ZONE=$(aws ssm get-parameter \
  --name /pds/hosted-zone/name \
  --query Parameter.Value --output text --region us-west-2)
FQDN=$(cd venues/dev/tests/bastion-ssh-verify && terragrunt output -raw fqdn | tail -1)
echo "Test EC2: ${FQDN}"
```

**Step 2 — note the values, then SSH:**

```bash
echo "Bastion:  ${USER}@pds-cds-bastion-core.${ZONE}"
echo "Test EC2: ${USER}@${FQDN}"
ssh ${USER}@pds-cds-bastion-core.${ZONE}
```

Then from the bastion, paste the `Test EC2:` line that was printed above.

> **Note:** `ssh -J` (ProxyJump) hangs on new host keys — both hops prompt for key verification but only the first gets an interactive terminal. Use the two-step approach above instead.

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
