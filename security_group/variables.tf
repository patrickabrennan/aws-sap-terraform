variable "aws_region" {
  description = "Region where to run this TF in"
  type        = string
  #added default
  default = "us-east-1"
}

variable "environment" {
  description = "Environment being built. DEV, QA or PRD"
  type        = string
  #added default
  default = "dev"
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies sap relevant objects"
  type        = string
}

variable "db_sg_list" {
  description = "DB SG List"
  type        = any
}

variable "app_sg_list" {
  description = "App SG List"
  type        = any
}

#new variables / replacement 
#variable "sap_discovery_tag" {
#  type        = string
#  description = "SAP Discovery tag for security group identification"
#}

#variable "db_sg_list" {
#  type = map(object({
#    description   = string
#    ingress_rules = optional(list(object({
#      from_port   = number
#      to_port     = number
#      protocol    = string
#      cidr_blocks = optional(list(string))
#      source_sgs  = optional(list(string))
#    })), [])
#  }))
#}

#variable "app_sg_list" {
#  type = map(object({
#    description   = string
#    ingress_rules = optional(list(object({
#      from_port   = number
#      to_port     = number
#      protocol    = string
#      cidr_blocks = optional(list(string))
#      source_sgs  = optional(list(string))
#    })), [])
#  }))
#}

variable "vpc_id" {
  type        = string
  description = "VPC ID where security groups will be created"
}

#variable "aws_region" {
#  type    = string
#  default = "us-east-1"
#}

#variable "environment" {
#  type    = string
#  default = "dev"
#}

variable "project" {
  type    = string
  default = "sap"
}
