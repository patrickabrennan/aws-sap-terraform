variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment being built. DEV, QA or PRD"
  type        = string
}

variable "tags" {
  description = "Tags for resources"
  type        = map(string)
}

variable "name" {
  description = "Name of the role"
  type        = string
}

variable "policies" {
  description = "list of the policies to attach"
  type        = list(string)
}

variable "managed_policies" {
  description = "list of the managed policies to attach"
  type        = list(string)
}

variable "permissions_boundary_arn" {
  description = "permissions boundary to attach"
  type        = string
}
