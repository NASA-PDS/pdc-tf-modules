# Terraform Module Usage Guide

## What is a Terraform Module?
A **Terraform Module** is a reusable set of Terraform configuration files that encapsulates resources and logic to be used across multiple environments or projects. Modules help in organizing Terraform code, improving maintainability, and enforcing best practices.


## Setting Up SSH Authentication for a Private Terraform Module Repository
Since **pds-tf-module** is a private repo, pulling the module code will require SSH Access. To access a private Terraform module repository, you need to generate an SSH key and add it to your GitHub/GitLab account.

**Note:** If you already have an existing SSH key for GitHub access, you can simply.

### Generate an SSH Key
[Link to steps on GitHub for SSH Key Generation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent)

1. Open a terminal and run:
   ```sh
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```
2. When prompted, save the key in the default location (`~/.ssh/id_rsa`) or specify a custom location (you can name your file anything you want)
3. Once your key is generated, create a config file at `~.ssh/config` with the following content. This will ensure the correct config gets used everytime.
    ```
    Host github.com
        IdentityFile ~/.ssh/custom-key-name
        User git
        IdentitiesOnly yes
    ```
4. Go to GitHub and navigate to **Settings > SSH and GPG Keys**.
5. Click **New SSH Key**, paste the copied public key, and save it.
6. Test SSH connection to confirm successful setup:
   ```sh
   ssh -T git@github.com
   ```
   If successful, you will see a message like:
   ```
   Hi <your-username>! You've successfully authenticated, but GitHub does not provide shell access.

## Using the Private Terraform Module

### 1. Reference the Module in Your Terraform Code
To use a module stored in a private repository, add the following to your Terraform configuration:
```hcl
module "s3_bucket" {
  source        = "git@github.com:NASA-PDS/pds-tf-modules.git//terraform/modules/s3"
  bucket_name   = var.s3_bucket_name
  partition     = var.partition
  bucket_policy = <<POLICY
 {
     "Version": "2012-10-17",
     "Statement": [
         {
             "Effect": "Deny",
             "Principal": {
                 "AWS": "*"
             },
             "Action": "s3:*",
             "Resource": [
                 "arn:${var.partition}:s3:::${var.s3_bucket_name}/*",
                 "arn:${var.partition}:s3:::${var.s3_bucket_name}"
             ]
         }
     ]
 }
 POLICY
  enable_blocks = true
  enable_policy = true

  required_tags = {
    project = var.project
    cicd    = var.cicd
  }
}
```
Ensure you have SSH access to the repository, or Terraform will fail to fetch the module.

### 2. Ensure you have the following variables defined in your `variables.tf`
```hcl
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "s3_bucket_name" {
  type        = string
  description = "The name of the S3 bucket"
  default     = "my_test_bucket"
}
variable "partition" {
  type    = string
  default = "aws"
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
}
```
### 3. Optional (recommended): Create a `backend.tf`
A `backend.tf` file in terraform defines the remote backend configuration (eg: AWS S3) where Terraform stores the state file. It is recommended to configure a backend before running terraform init to ensure that the state is stored remotely and not locally to ensure multiple team members can work on the same infrastructure without overwriting each other's changes.

```
hcl
terraform {
  backend "s3" {
    bucket = "pds-infra"
    key    = "<path_to_s3_bucket>/<s3_bucket_name>.tfstate"
    region = "us-west-2"
  }
}
```
### 4. Creating Local `.yml` and `.tfvars` Files
To store environment-specific variables locally:

#### Create a `.tfvars` File
Modify `<filename>.tfvars` with the required values.

```hcl
s3_bucket_name             = "s3_bucket_name"
partition                  = "aws"
project                    = "pds-en"
cicd                       = "pds-github"
```

#### Add `.tfvars` to `.gitignore`
To prevent any sensitive configuration files from being committed, add the following to `.gitignore`:

**Note** :
DO NOT add `*.yml`, `*.yaml`, or `*.json` as some projects might need them to hold other information that is not-sensitive.
```
# Ignore CLI configuration files
.terraformrc
terraform.rc

# Local .terraform directories
**/.terraform/*

# .tfstate files
*.tfstate
*.tfstate.*
*.tfvars
```

## Export your AWS Profile locally
Before running below Terraform commands, ensure you're logged into the correct AWS environment locally.

## Running Terraform Commands
After configuring your module, initialize and run Terraform:

1. **Initialize Terraform:**
   ```sh
   cd terraform
   terraform init
   ```

2. **Validate the Configuration:**
   ```sh
   terraform validate
   ```

3. **Plan the Changes:**
   ```sh
   terraform plan -var-file=terraform.tfvars -lock=false
   ```

4. **Apply the Changes:**
   ```sh
   terraform apply -var-file=terraform.tfvars -lock=false
   ```

## Advanced Usage: Adding New Parameters to the Module
If you need to introduce a new parameter to the module:

1. Request PDS project administrators (with MCP Tenant Operator Roles) to update the module.
2. The update should be made in the private module repository **pds-tf-modules**
3. A Pull Request (PR) should be created and reviewed.
4. Once merged, update your module reference to the latest version.
   ```hcl
   source = "git@github.com:your-org/your-private-module.git//module-path?ref=new-version"
   ```
5. Re-run `terraform init -upgrade` to fetch the updated module.

## Conclusion
This guide ensures a smooth setup and usage of the Terraform module from a private repository. Follow these steps carefully, and if you encounter issues, verify SSH authentication and module references before proceeding OR reach out to PDS DevOps Team.
