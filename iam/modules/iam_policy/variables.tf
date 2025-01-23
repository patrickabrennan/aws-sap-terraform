variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  type        = string
  description = "Environment to create resources in"
}

variable "name" {
  type        = string
  description = "Name for the policy"
}

variable "statements" {
  type        = any
  description = "Statements to be added to the policy"
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to resources"
}
