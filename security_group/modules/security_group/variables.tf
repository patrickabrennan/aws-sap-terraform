variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
}

variable "environment" {
  description = "Environment being built. DEV, QA or PRD"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID to create resources in"
  type        = string
}

variable "name" {
  description = "Name for the security group"
  type        = string
}

variable "description" {
  description = "Description for the security group"
  type        = string
}

variable "rules" {
  description = "Rules to be applied to the security group"
  type        = any
}

variable "dependency_security_groups" {
  description = "Objects for created security groups"
  type        = any
  default     = {}
}

variable "tags" {
  description = "Tags to be applied"
  type        = map(string)
}

variable "efs_to_allow" {
  description = "List of EFS SG to allow this one in"
  type        = list(string)
}
