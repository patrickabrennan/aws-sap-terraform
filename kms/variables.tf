variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "keys_to_create" {
  description = "Keys to create"
  type        = any
}
