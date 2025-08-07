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

#added the following:
variable "role_name" {
  description = "The name of the IAM role to create"
  type        = string
}

variable "assume_role_policy" {
  description = "The assume role policy document"
  type        = string
}

variable "attach_permissions_boundary" {
  description = "Whether to attach the permissions boundary"
  type        = bool
  default     = false
}

#variable "tags" {
#  description = "Tags to apply to the IAM role"
#  type        = map(string)
#  default     = {}
#}

