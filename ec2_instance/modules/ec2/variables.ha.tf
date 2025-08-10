# Two AZs to place HA nodes; if you enable VIP ENI, keep both nodes in one AZ/subnet
variable "ha_azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Two AZs used for HA pairs. For ENI VIP, use the same AZ/subnet."
}

variable "availability_zone" {
  type        = string
  description = "AZ to place this instance"
}

# Fallback AZ for non-HA entries if not specified in instances_to_create
variable "default_availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Default AZ for non-HA instances."
}

# ENI VIP controls (optional; same-AZ only)
variable "enable_vip_eni" {
  type        = bool
  default     = false
  description = "Create a floating ENI per HA group (only valid when both nodes share the same subnet/AZ)."
}

variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID for the VIP ENI; leave empty to auto-pick any subnet in var.vpc_id."
}

variable "vip_private_ip" {
  type        = string
  default     = ""
  description = "Optional fixed IP for the VIP ENI; leave empty to auto-assign."
}
