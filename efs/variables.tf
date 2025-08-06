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

variable "keys_to_create" {
  type = map(any)



#variable "efs_to_create" {
#  description = "KMS keys to create"
#  type        = any
#}

#variable "efs_to_create" {
#  type    = map(any)
#  default = { efs = {} }
#}
