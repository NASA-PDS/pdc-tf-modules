output "public_network_policy_arn" {
  description = "Name of the public network access policy"
  value       = aws_opensearchserverless_security_policy.public_network_policy.name
}

output "data_access_policy_arn" {
  description = "Name of the data access policy"
  value       = aws_opensearchserverless_access_policy.data_access_policy.name
}

output "collection_name" {
  description = "Name of the serverless collection"
  value       = aws_opensearchserverless_collection.pds-mcp-registry-collection.name
}

output "collection_arn" {
  description = "ARN of the serverless collection"
  value       = aws_opensearchserverless_collection.pds-mcp-registry-collection.arn
}

output "dashboard_endpoint" {
  description = "OpenSearch serverless dashboard endpoint"
  value       = aws_opensearchserverless_collection.pds-mcp-registry-collection.dashboard_endpoint
}
