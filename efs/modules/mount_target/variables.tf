variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "efs_id" {
  description = "EFS ID of filesystem where mount targets need to be created"
  type        = string
}

variable "sg_id" {
  description = "List of SG IDs to attached to Mount Target"
  type        = list(any)
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies subnets for EFS Mount Target creation"
  type        = string
}
