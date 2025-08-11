variable "aws_region"  { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }

variable "instances_to_create" {
  type        = map(any)
  description = "Map of instance configs keyed by logical name"
}

variable "sap_discovery_tag" {
  type    = string
  default = ""
}

variable "assign_public_eip" {
  type    = bool
  default = true
}

variable "enable_vip_eni" {
  type    = bool
  default = false
}
variable "vip_subnet_id" {
  type    = string
  default = ""
}
