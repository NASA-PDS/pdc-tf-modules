variable "collection_name" {
  description = "The name of the OpenSearch Serverless collection"
  type        = string
}

variable "collection_type" {
  type        = string
  description = "Type of the serverless collection. Ex: SEARCH, TIMESERIES or VECTORSEARCH"
}

variable "encryption_policy_name" {
  type        = string
  description = "Name of the Security Encryption Policy"
}

variable "network_policy_name" {
  type        = string
  description = "Name of the Network Policy"
}

variable "data_access_policy_name" {
  type        = string
  description = "Name of the Data Access Policy"
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
  default     = {}
}
