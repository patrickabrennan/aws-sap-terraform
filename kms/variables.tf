variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
  default     = "dev"
}

keys_to_create = {
  efs = {
    alias_name = "kms-alias-efs"
    enable_key_rotation = true
  }
}


#variable "keys_to_create" {
#  description = "Keys to create"
#  type        = any
#  default     = kms
#}
