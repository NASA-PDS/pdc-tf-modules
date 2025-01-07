# variables
variable "venue" {
  type        = string
  description = "Deployment venue for Terraform. Ex: dev, test, prod"
}

variable "collection_type" {
  type        = string
  description = "Type of the serverless collection. Ex: SEARCH, TIMESERIES or VECTORSEARCH"
}

variable "required_tags" {
  description = "Required resource tags"
  type        = map(string)
}
