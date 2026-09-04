# ECS Module

> ⚠️ **UNTESTED MODULE** — This module has no known production consumers in the NASA-PDS organization. It has not been validated outside of development. Use with caution.
>
> If you adopt this module, please open a pull request to add your project to the [Known Consumers](#known-consumers) table below and include a usage example.

## Known Consumers

_None yet. Be the first — [open a PR](https://github.com/NASA-PDS/pdc-tf-modules/pulls)._

---

# Terraform Module Usage Guide

## What is a Terraform Module?
A **Terraform Module** is a reusable set of Terraform configuration files that encapsulates resources and logic to be used across multiple environments or projects. Modules help in organizing Terraform code, improving maintainability, and enforcing best practices.


## Setting Up SSH Authentication for a Private Terraform Module Repository
Since **pdc-tf-modules** is a private repo, pulling the module code will require SSH Access. To access a private Terraform module repository, you need to generate an SSH key and add it to your GitHub/GitLab account.

**Note:** If you already have an existing SSH key for GitHub access, you can simply use the same key and upload it to GitHub using Steps #4-6 in the section below.

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
module "ecs" {
  source         = "git@github.com:NASA-PDS/pdc-tf-modules.git//terraform/modules/ecs"
  config_file    = var.config_file
  create_service = var.create_service
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

variable "config_file" {
  description = "Path to the environment-specific YAML file (eg: dev.yaml, prod.yaml)"
  type        = string
}

variable "create_service" {
  description = "Flag to control where the ECS service should be created or not"
  type        = bool
  default     = true
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
}
```
### 3. Optional (recommended): Create a `backend.tf`
A `backend.tf` file in terraform defines the remote backend configuration (eg: AWS S3) where Terraform stores the state file. It is recommended to configure a backend before running terraform init to ensure that the state is stored remotely and not locally to ensure multiple team members can work on the same infrastructure without overwriting each other's changes.

```hcl
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
config_file                = "./ecs/task-definitions/<env_config-filename>.yml"
create_service             = true
project                    = "pds-en"
cicd                       = "pds-github"
```
**Note:**
1. Since ECS service creation is optional, the `create_service` variable is a bool. It can be toggled between `true` or `false`. If it's `fasle` the ECS service will not be created.
2. Ensure the path to the `<env_config-filename>.yml` is accurate.

#### Create a `.yml` Configuration File
Modify `<env_config-filename>.yml` with your settings and exact enviornment values. This is why it cannot be uploaded to GitHub.

```yml
clusters:
  - cluster_name: "pds-test-sweeper-cluster"

task_definitions:
  - task_family: "pds-test-sweeper-task"
    container_definitions:
      - name: "test-pds-sweeper-container"
        image: "012345687901.dkr.ecr.us-west-2.amazonaws.com/pds-registry-sweepers:latest"
        logConfiguration:
          logDriver: "awslogs"
          options:
            awslogs-region: "us-west-2"
            awslogs-group: "/ecs/test-pds-sweeper-container"
            awslogs-create-group: "true"
            awslogs-stream-prefix: "ecs"
        healthCheck:
          retries: 3
          command:
            - "CMD-SHELL"
            - "data || exit 1"
          timeout: 5
          interval: 60
          startPeriod: 300
        environment:
          - name: "MULTITENANCY_NODE_ID"
            value: "en"
          - name: "PROV_ENDPOINT" # This is the OpenSearch Serverless Collection Endpoint
            valueFrom: "https://abcdedf012345678abc.us-west-2.aoss.amazonaws.com"
    requires_compatibilities:
      - "FARGATE"
    network_mode: "awsvpc"
    runtimePlatform:
      operatingSystemFamily: "LINUX"
      cpuArchitecture: "X86_64"
    cpu: 1024
    memory: 2048
    execution_role_arn: "arn:aws:iam::012345687901:role/registry-sweepers-ecs-task-execution-role"
    task_role_arn: "arn:aws:iam::012345687901:role/registry-ecs-task-role"

services:
  - service_name: "pds-test-resitry-sweepers-service"
    cluster_name: "pds-test-sweeper-cluster"
    task_family: "pds-test-sweeper-task"
    desired_count: 1
    launch_type: "FARGATE"
    load_balancer:
      target_group_arn: "arn:aws:elasticloadbalancing:us-west-2:012345678901:targetgroup/pds-test-registry-sweeper-tgt/abcd012345678901"
      container_name: "test-pds-sweeper-container"
      container_port: 80
    network_configuration:
      subnets:
        - "subnet-abcd012345678901"
      security_groups:
        - "sg-abcd012345678901"
        - "sg-abcd012345678901"
      assign_public_ip: false
    deployment_controller_type: "ECS"

```

#### Add These Files to `.gitignore`
To prevent any sensitive configuration files from being committed, add the following to `.gitignore`:

**Note** :
1. DO NOT add `*.yml`, `*.yaml`, or `*.json` as some projects might need them to hold other information that is not-sensitive.
2. Replace `<env_config-filename>` with your config filename.
```
# Ignore CLI configuration files
.terraformrc
terraform.rc
*<env_config-filename>.yml
*<env_config-filename>.yaml
*<env_config-filename>.json

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

1. Request PDS project administrators (with PDC Tenant Operator Roles) to update the module.
2. The update should be made in the private module repository **pdc-tf-modules**
3. A Pull Request (PR) should be created and reviewed.
4. Once merged, update your module reference to the latest version.
   ```hcl
   source = "git@github.com:your-org/your-private-module.git//module-path"
   ```
5. Re-run `terraform init -upgrade` to fetch the updated module.

## Conclusion
This guide ensures a smooth setup and usage of the Terraform module from a private repository. Follow these steps carefully, and if you encounter issues, verify SSH authentication and module references before proceeding OR reach out to PDS DevOps Team.
