variable "name_prefix" {
  description = "Prefix for all resource names (e.g., pds-portal-dev). Combined with 'bastion' to form resource names."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to deploy the bastion into."
  type        = string
}

variable "subnet_id" {
  description = "Public subnet ID for the bastion host."
  type        = string
}

variable "ami_id" {
  description = "AMI ID for the bastion host."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for the bastion."
  type        = string
  default     = "t3.micro"
}

variable "allowed_ssh_cidrs" {
  description = "CIDRs allowed to SSH to the bastion on port 22."
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "CIDR of the private subnet containing target EC2s. Bastion egress is scoped to this CIDR on port 22."
  type        = string
}

variable "instance_profile_name" {
  description = "Name of the IAM instance profile to attach to the bastion EC2. Must be created by the caller (e.g. terraform/bastion-core/iam/) and passed in — IAM resources are not managed by this module."
  type        = string
}

variable "assign_eip" {
  description = "Assign an Elastic IP to the bastion. Recommended for production so the public address survives instance replacement."
  type        = bool
  default     = true
}

variable "required_tags" {
  description = "Required resource tags (tenant, venue, component, cicd, managedby)."
  type        = map(string)
  default     = {}
}
