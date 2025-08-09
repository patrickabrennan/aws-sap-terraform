variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, qa, prod)"
  type        = string
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies sap relevant objects"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Exactly two CIDRs for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "extra_tags" {
  description = "Additional tags to add to all resources"
  type        = map(string)
  default     = {}
}
