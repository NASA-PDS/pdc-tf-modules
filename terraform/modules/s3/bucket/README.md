# s3/bucket

Shared S3 bucket module. Versioning, Object Lock, access logging and S3 Inventory are **off by default**; the caller turns on what it needs.

If a caller turns versioning on, old versions are capped by default (90 days, keep 2), so a versioned bucket never keeps unlimited versions.

PDS tenant accounts call it from `pdc-tenant-infra` `terraform/deployments/buckets`. The tenant requirements (seven purposes, `pds-<node>-<purpose>-<venue>`, `us-west-2`, which settings each purpose uses) live in that deployment's README, not here.

## Defaults

| Setting | Default | What it does |
|---|---|---|
| `versioning` | `Disabled` | `Enabled` or `Disabled` only. |
| `object_lock_enabled` | `false` | Turns on S3 Object Lock (Governance only). |
| `object_lock_days` | `90` | Default retention. Only used when Object Lock is on. |
| `noncurrent_version_expiration_days` | `90` | Only applies when versioning is `Enabled`. `0` means no rule. |
| `newer_noncurrent_versions` | `2` | Noncurrent versions kept besides the current one. `0` means no count limit. |
| `object_expiration_days` | `0` | `0` leaves current objects alone. |
| `expiration_rules` | `[]` | Prefix-scoped retention. When set, the bucket-wide expiration rules are turned off. See [Prefix retention](#prefix-retention). |
| `logging_target_bucket` | `""` | Empty means no server access logging. |
| `logging_target_prefix` | `s3/access_logs/` | Prefix for log object keys in the target bucket. |
| `logging_partition_date_source` | `"EventTime"` | Partitions log keys by the date of the request. Use the default. `DeliveryTime` is accepted if needed; `""` opts out and keeps the simple key format. |
| `inventory_destination_bucket` | `""` | Empty means no S3 Inventory. |
| `inventory_destination_prefix` | `s3/inventory/` | Prefix for inventory object keys in the destination bucket. |
| `inventory_destination_account_id` | `""` | Account that owns the destination bucket. Omit when empty. |
| `inventory_name` | `entire-bucket` | Inventory configuration name on the source bucket. |
| `inventory_frequency` | `Weekly` | `Daily` or `Weekly`. |
| `inventory_included_object_versions` | `All` | `All` or `Current`. |
| `inventory_format` | `CSV` | `CSV`, `ORC`, or `Parquet`. |
| `enable_blocks` | `true` | Block Public Access on. |

## Versioning

`versioning` is `Enabled` or `Disabled`. `Suspended` is rejected. Object Lock requires `Enabled`.

When versioning is `Enabled`, noncurrent versions are expired by default: a version older than `noncurrent_version_expiration_days` (90) is removed once more than `newer_noncurrent_versions` (2) newer noncurrent versions exist. The bucket keeps the current version plus the 2 newest noncurrent versions.

Set `noncurrent_version_expiration_days = 0` to create no rule and keep every version. Set `newer_noncurrent_versions = 0` to drop the count limit, so every noncurrent version expires after the day count.

Use `newer_noncurrent_versions = 0` where each key is written once, such as a log bucket. Each key's single noncurrent version is always inside the "keep 2" count, so with `2` those versions would never expire.

## Object Lock

Retention is always Governance. There is no Compliance mode. `object_lock_days` sets the default retention.

Object Lock can be enabled on a new bucket or on an existing one, as long as versioning is `Enabled`. On an existing bucket, enabling it does not replace the bucket or change its objects.

Two things to know before turning it on:

- It cannot be turned off again. Setting `object_lock_enabled` back to `false` after it was `true` makes the AWS provider replace the bucket.
- The default retention applies to objects written after it is set. Objects already in the bucket are not locked retroactively.

### Bypassing Governance retention

Governance mode lets a privileged caller shorten or remove retention on an object, or delete a locked object version. A bucket policy or an IAM identity policy must allow `s3:BypassGovernanceRetention` for that caller, and the request must also set the bypass header. The permission alone does nothing.

This module does not build the bucket policy: the caller passes `bucket_policy`. To allow bypass, add the action to the policy the caller supplies, scoped to objects:

```json
{
  "Sid": "AllowOperatorGovernanceBypass",
  "Effect": "Allow",
  "Principal": { "AWS": ["arn:aws:iam::<account-id>:role/<operator-role>"] },
  "Action": ["s3:BypassGovernanceRetention"],
  "Resource": ["arn:aws:s3:::<bucket-name>/*"]
}
```

With the AWS CLI, use `s3api` with `--bypass-governance-retention`. `aws s3 rm` has no bypass option:

```bash
aws s3api delete-object --bucket <bucket-name> --key <key> \
  --version-id <id> --bypass-governance-retention
```

Changing `object_lock_days` does not need bypass, but it only affects objects written after the change. Lifecycle rules cannot delete a version before its retention ends.

## Server access logging

Set `logging_target_bucket` to the name of the bucket that receives the logs. Leave it empty to disable logging. The log bucket itself should leave it empty so it does not log to itself.

By default, `logging_partition_date_source` is `EventTime`, so log objects use S3 partitioned prefixes:

```text
<logging_target_prefix><account-id>/<region>/<source-bucket>/YYYY/MM/DD/<timestamp>-<id>
```

Use this default unless there is a reason not to. `DeliveryTime` is also accepted if needed, and `""` opts out and writes the simple format `<logging_target_prefix><timestamp>-<id>`.

`EventTime` uses the date of the request. `DeliveryTime` uses the date S3 wrote the log object. The key already contains the source bucket name, so the caller does not need to add one to `logging_target_prefix`. Changing this setting on an existing bucket updates the logging configuration in place. Logs already written keep their old keys.

```hcl
logging_target_bucket         = "my-log-bucket"
logging_target_prefix         = "s3/access_logs/"
logging_partition_date_source = "EventTime"
```

`object_expiration_days` deletes current objects after that many days. It is meant for a log bucket; do not set it on a bucket that holds data. A bucket with Object Lock cannot delete objects before their retention ends, so a log bucket that expires objects earlier than `object_lock_days` should leave Object Lock off.

## S3 Inventory

Set `inventory_destination_bucket` to the name of the bucket that receives inventory reports. Leave it empty to disable inventory.

This module does not create the destination bucket policy. The caller must allow the `s3.amazonaws.com` service principal to `s3:PutObject` on the destination (with `aws:SourceArn`, `aws:SourceAccount`, and `s3:x-amz-acl = bucket-owner-full-control`), or reports will not be delivered.

```hcl
inventory_destination_bucket     = "my-log-bucket"
inventory_destination_prefix     = "s3/inventory/"
inventory_destination_account_id = "111122223333"
inventory_frequency              = "Weekly"
inventory_format                 = "CSV"
```

## Prefix retention

`object_expiration_days` and `noncurrent_version_expiration_days` apply to the whole bucket. When different prefixes need different retention (for example a log bucket that keeps access logs 90 days and S3 Inventory reports 24 months), set `expiration_rules` instead.

When `expiration_rules` is not empty:

- The bucket-wide current-object and noncurrent-version rules are **not** created. S3 uses the earliest expiration when rules overlap, so a bucket-wide 90-day rule would delete objects under a prefix that asks for longer.
- Only the listed prefixes expire. S3 cannot express "everything else", so objects under a prefix that is not listed are never expired. List every prefix that should expire.
- Each entry sets `id` (unique), `prefix`, `expiration_days` and, optionally, `noncurrent_expiration_days`. Leave `noncurrent_expiration_days` out to use `noncurrent_version_expiration_days` (90 by default). Set it to `0` to keep noncurrent versions. Noncurrent expiration also uses `newer_noncurrent_versions`, and needs versioning `Enabled`.
- Multipart-upload cleanup and storage class transitions stay bucket-wide.

On a versioned bucket, total retention is `expiration_days` plus `noncurrent_expiration_days`.

```hcl
expiration_rules = [
  { id = "s3-access-logs-90d", prefix = "s3/access_logs/", expiration_days = 90 },
  { id = "s3-inventory-24mo",  prefix = "s3/inventory/",   expiration_days = 730 },
]
newer_noncurrent_versions = 0 # each key is written once
```

With the default `noncurrent_version_expiration_days = 90`, access logs are kept about 180 days and inventory reports about 820 days.

## Public access

Block Public Access is on by default (`enable_blocks = true`, all four block flags true). Set `enable_blocks` false only where the account already enforces the same controls.

## Example: a versioned bucket with Object Lock and access logs

Version cleanup (90 days, keep 2) comes from the defaults.

```hcl
versioning            = "Enabled"
object_lock_enabled   = true
object_lock_days      = 90
logging_target_bucket = "my-log-bucket"
```

## Example: a log bucket

```hcl
versioning                         = "Enabled"
object_lock_enabled                = false
object_expiration_days             = 60
noncurrent_version_expiration_days = 60
newer_noncurrent_versions          = 0
logging_target_bucket              = ""
```
