variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "account_id" {
  type      = string
  default   = ""
  nullable  = true
}
variable "Account_ID" {
  type      = string
  default   = ""
  nullable  = true
}

variable "iam_roles" {
  description = "IAM roles to create"
  type        = any
}

variable "iam_policies" {
  description = "IAM policies to create"
  type        = any
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
  default     = null
}

variable "sap_discovery_tag" {
  description = "SAP discovery tag"
  type        = string
  default     = null
}
