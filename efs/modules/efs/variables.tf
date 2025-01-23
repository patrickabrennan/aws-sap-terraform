variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "sid_filesystem_to_create" {
  description = "SAP SID identifying EFS to create"
  type        = string
}

variable "access_point_info" {
  description = "Data for access point creation"
  type        = any
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies if a resource is relevant to HA solution"
  type        = string
}

variable "tags" {
  description = "Tags to be applied"
  type        = map(string)
}