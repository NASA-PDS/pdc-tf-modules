# main OS module
data "aws_caller_identity" "current" {}

resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "pds-mcp-${var.venue}-encryption-policy"
  type        = "encryption"
  description = "Encryption policy for pds-mcp-${var.venue}-collection"
  policy = jsonencode({
    Rules = [
      {
        Resource = [
          "collection/pds-mcp-${var.venue}-collection"
        ],
        ResourceType = "collection"
      }
    ],
    AWSOwnedKey = true
  })
}
resource "aws_opensearchserverless_security_policy" "public_network_policy" {
  name        = "pds-mcp-${var.venue}-network-policy"
  type        = "network"
  description = "Public network access policy for OpenSearch Serverless"

  policy = jsonencode([
    {
      Description = "Public access to collection and Dashboards endpoint for pds-mcp-${var.venue}-collection",
      Rules = [
        {
          ResourceType = "collection",
          Resource = [
            "collection/pds-mcp-${var.venue}-collection*"
          ]
        },
        {
          ResourceType = "dashboard"
          Resource = [
            "collection/pds-mcp-${var.venue}-collection*"
          ]
        }
      ],
      AllowFromPublic = true
    }
  ])
}

resource "aws_opensearchserverless_access_policy" "data_access_policy" {
  name        = "pds-mcp-${var.venue}-data-access-policy"
  type        = "data"
  description = "Allow index and collection access for PDS Registry"
  policy = jsonencode([
    {
      Description = "PDS - OpenSearch Admin Access"
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/*/*"
          ],
          Permission = [
            "aoss:*"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/pds-mcp-${var.venue}-collection*"
          ],
          Permission = [
            "aoss:*"
          ]
        }
      ],
      Principal = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pds-registry-admin-aoss-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/mcp-OU-tenantOperator"
      ]
    },
    {
      Description = "PDS - OpenSearch Read Access"
      Rules = [
        {
          ResourceType = "index",
          Resource = [
            "index/*/*"
          ],
          Permission = [
            "aoss:ReadDocument",
            "aoss:DescribeIndex"
          ]
        },
        {
          ResourceType = "collection",
          Resource = [
            "collection/pds-mcp-${var.venue}-collection*"
          ],
          Permission = [
            "aoss:DescribeCollectionItems"
          ]
        }
      ],
      Principal = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pds-registry-aoss-read-only",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/pds-registry-api-ecs-task-role",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/mcp-OU-tenantDeveloper"
      ]
    }
  ])
}

resource "aws_opensearchserverless_collection" "pds-mcp-registry-collection" {
  name = "pds-mcp-${var.venue}-collection"
  type = var.collection_type

  depends_on = [
    aws_opensearchserverless_security_policy.public_network_policy,
    aws_opensearchserverless_access_policy.data_access_policy
  ]

  tags = merge(var.required_tags)
}
