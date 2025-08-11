# Which AZ to use when a node doesn't specify one
variable "default_availability_zone" {
  type        = string
  description = "Default AZ for instances when not specified per-node."
}

# When ha=true, optional list of AZs to use for -a and -b nodes
variable "ha_azs" {
  type        = list(string)
  description = "AZs to use when ha=true; index 0 for -a, index 1 for -b."
  default     = []
}

# control whether to attach an Elastic IP to each VIP ENI
variable "enable_vip_eip" {
  type        = bool
  default     = true  # set to false if you don’t want public IPs on VIPs
  description = "Attach an Elastic IP to each VIP ENI."
}


# Give each instance a public EIP (recommended if you SSH directly)
variable "assign_public_eip" {
  type        = bool
  description = "Attach an Elastic IP to each instance's primary ENI."
  default     = true
}



#variable "enable_vip_eip" {
#  type        = bool
#  default     = true       # set false if you don’t want a public IP
#  description = "Attach an Elastic IP to each VIP ENI."
#}
