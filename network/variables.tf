variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
  default     = "dev"
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies sap relevant objects"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
  default     = null
}
