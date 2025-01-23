variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment to be used for this run"
  type        = string
}

variable "iam_roles" {
  description = "IAM roles to create"
  type        = any
}

variable "iam_policies" {
  description = "IAM policies to create"
  type        = any
}
