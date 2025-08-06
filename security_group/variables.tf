variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment being built. DEV, QA or PRD"
  type        = string
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies sap relevant objects"
  type        = string
}

variable "db_sg_list" {
  description = "DB SG List"
  type        = any
}

variable "app_sg_list" {
  description = "App SG List"
  type        = any
}

#added variables:
variable "vpc_id" {
  description = "VPC ID for the selected environment"
  type        = string
}
