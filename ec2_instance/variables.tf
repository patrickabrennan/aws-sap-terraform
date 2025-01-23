variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "instances_to_create" {
  description = "Data for instances to create"
  type        = any
}
