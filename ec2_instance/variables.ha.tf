# root/variables.tf  (keep ONLY these here)

variable "aws_region"  { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }

variable "instances_to_create" {
  description = "Map of instance configs keyed by logical name"
  type        = map(any)
}

# optional tag you were passing
variable "sap_discovery_tag" {
  type        = string
  default     = ""
}

# public EIP for instances
variable "assign_public_eip" {
  type    = bool
  default = true
}

# VIP controls passed into the module
variable "enable_vip_eni" {
  type    = bool
  default = false
}
variable "vip_subnet_id" {
  type    = string
  default = ""
}
