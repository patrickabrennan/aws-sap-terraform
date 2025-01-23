variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "sg_name" {
  description = "Name of Security Group"
  type        = string
}

variable "vpc" {
  description = "VPC where SG needs to be created"
  type        = string
}

variable "tags" {
  description = "Tags to be assigned to Security Group"
  type        = map(any)
}
