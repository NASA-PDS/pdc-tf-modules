# Cognito Module

> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pdc-tf-modules/pulls)._

---

Creates a Cognito User Pool with app client, domain, user groups, and optional initial users. Pool and client IDs are stored in SSM Parameter Store.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `user_pool_name` | Name of the Cognito User Pool | `string` | `"pds-user-pool"` | no |
| `user_pool_domain` | Unique domain name for the Cognito Pool | `string` | `"pds-user-pool"` | no |
| `email_invitation_message` | Message body for invitation emails | `string` | _(see variables.tf)_ | no |
| `email_invitation_subject` | Subject line for invitation emails | `string` | `"PDS Temporary Cognito Credentials"` | no |
| `sms_text_invitation_message` | Message body for SMS invitations | `string` | _(see variables.tf)_ | no |
| `pds_welcome_page_callback_url` | PDS Welcome page callback URL | `string` | `"https://pds.nasa.gov/"` | no |
| `pds_welcome_page_client_id` | PDS Welcome page client ID | `string` | — | no |
| `ssm_param_cognito_user_pool_id` | SSM path for storing the User Pool ID | `string` | `"/pds/experimental-cognito/cognito-user-pool/user-pool-id"` | no |
| `ssm_param_cognito_user_pool_client_id` | SSM path for storing the User Pool Client ID | `string` | `"/pds/experimental-cognito/cognito-user-pool/user-pool-client-id"` | no |
| `pds_cognito_user_groups` | List of Cognito user groups to create | `list(object({name, description}))` | _(PDS node groups)_ | no |
| `pds_cognito_initial_users` | Optional list of users to pre-populate | `list(object({username, password, group, email}))` | `[]` | no |
| `required_tags` | Required resource tags (tenant, venue, component, cicd, managedby) | `map(string)` | `{}` | yes |

## Outputs

| Name | Description |
|------|-------------|
| `pds_cognito_user_pool_id` | ID of the created Cognito User Pool |
| `pds_cognito_user_pool_client_id` | ID of the created Cognito User Pool Client |
| `pds_cognito_initial_users` | Usernames of any pre-populated initial users |

## Usage

```hcl
module "cognito" {
  source = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/cognito?ref=main"

  user_pool_name   = "my-pds-user-pool"
  user_pool_domain = "my-pds-user-pool"

  required_tags = {
    tenant    = var.tenant
    venue     = var.venue
    component = var.component
    cicd      = var.cicd
    managedby = var.managedby
  }
}
```
