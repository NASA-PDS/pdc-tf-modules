# main OS module
data "aws_caller_identity" "current" {}

# Load external JSON files
locals {
  data_access_policies = jsondecode(file("${path.module}/policies/dev/data.json"))
  network_policy       = jsondecode(file("${path.module}/policies/dev/network.json"))
}

resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = var.encryption_policy_name
  type        = "encryption"
  description = "Encryption policy for ${var.collection_name}"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/${var.collection_name}"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}
resource "aws_opensearchserverless_security_policy" "public_network_policy" {
  name        = var.network_policy_name
  type        = "network"
  description = "Network Policy for ${var.collection_name}"

  policy = jsonencode({
    Description     = local.network_policy.Description
    Rules           = local.network_policy.Rules
    AllowFromPublic = local.network_policy.AllowFromPublic
  })
}

resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = var.data_access_policy_name
  type        = "data"
  description = "Data access policies to allow index and collection access for ${var.collection_name}"

  policy = jsonencode({
    Rules = [
      for rule in local.data_access_policies.Rules : {
        Description = rule.Description,
        Rules       = rule.Rules,
        Principal   = [for principal in rule.Principal : replace(principal, "{account_id}", data.aws_caller_identity.current.account_id)]
      }
    ]
  })
}

resource "aws_opensearchserverless_collection" "pds-mcp-registry-collection" {
  name = var.collection_name
  type = var.collection_type

  depends_on = [
    aws_opensearchserverless_security_policy.public_network_policy,
    aws_opensearchserverless_access_policy.data_access_policy
  ]

  tags = merge(var.required_tags)
}
