variable "aws_region"  { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }

variable "instances_to_create" {
  description = "Map of instance configs keyed by logical name"
  type        = map(any)
}

# already used by your tfvars
variable "sap_discovery_tag" {
  type        = string
  default     = ""
  description = "Optional tag to mark SAP-discoverable resources"
}

# VIP controls (your tfvars referenced these)
variable "enable_vip_eni" {
  type        = bool
  default     = false
}
variable "vip_subnet_id" {
  type        = string
  default     = ""
}

# HA placement (if you already have these, keep your versions)
variable "default_availability_zone" {
  type = string
}
variable "ha_azs" {
  type    = list(string)
  default = []
}

# Public EIP per instance (used by module)
variable "assign_public_eip" {
  type    = bool
  default = true
}
