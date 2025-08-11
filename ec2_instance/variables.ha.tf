variable "default_availability_zone" {
  type        = string
  description = "Default AZ if a node's AZ isn't specified"
}

variable "ha_azs" {
  type        = list(string)
  default     = []
  description = "When ha=true and node doesn't specify secondary AZ, use [A,B]"
}







/*
variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "environment" {
  type        = string
  description = "Environment name used in SSM param paths and tags (e.g., dev)"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where instances will be created"
}

variable "instances_to_create" {
  description = "Map of instance configs keyed by logical name (e.g., sapd01db1)"
  type        = map(any)
}

# HA controls (top-level; used by expansion)
variable "default_availability_zone" {
  type        = string
  description = "Default AZ if a node's AZ isn't specified"
}

variable "ha_azs" {
  type        = list(string)
  default     = []
  description = "When ha=true and node doesn't specify secondary AZ, use [A,B]"
}

# Public EIP per-instance toggle
variable "assign_public_eip" {
  type        = bool
  default     = true
  description = "Attach an Elastic IP to each instance's primary ENI"
}


/*
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
*/

*/
#variable "enable_vip_eip" {
#  type        = bool
#  default     = true       # set false if you don’t want a public IP
#  description = "Attach an Elastic IP to each VIP ENI."
#}
