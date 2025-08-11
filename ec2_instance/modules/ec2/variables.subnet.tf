############################################
# VPC / AZ context
############################################
variable "vpc_id" {
  type        = string
  description = "VPC ID that holds the target subnets."
}

variable "availability_zone" {
  type        = string
  description = "AZ where this instance (and its VIP, if enabled) should live."
}

############################################
# Instance subnet selection (primary ENI)
############################################
# 1) Direct ID (takes precedence if set)
variable "subnet_ID" {
  type        = string
  default     = ""
  description = "Optional explicit subnet ID for the instance ENI. If set, other hints are ignored."
}

# 2) Tag equals (Tier=app, etc.)
variable "subnet_tag_key" {
  type        = string
  default     = ""
  description = "Optional tag key to narrow subnets (e.g., 'Tier')."
}
variable "subnet_tag_value" {
  type        = string
  default     = ""
  description = "Optional tag value to narrow subnets (e.g., 'app')."
}

# 3) Name wildcard match (*public*, *private*, etc.)
variable "subnet_name_wildcard" {
  type        = string
  default     = ""
  description = "Optional wildcard for tag:Name (e.g., '*public*' or '*private*')."
}

# What to do if >1 remain after filtering
variable "subnet_selection_mode" {
  type        = string
  default     = "unique" # or "first"
  validation {
    condition     = contains(["unique", "first"], var.subnet_selection_mode)
    error_message = "subnet_selection_mode must be 'unique' or 'first'."
  }
}

############################################
# VIP subnet selection (HA floating ENI)
############################################
variable "enable_vip_eni" {
  type        = bool
  default     = false
  description = "Whether to create a VIP ENI alongside this instance."
}

# 1) Direct ID (takes precedence if set)
variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "Optional explicit subnet ID for the VIP ENI."
}

# 2) Tag equals
variable "vip_subnet_tag_key" {
  type        = string
  default     = ""
  description = "Optional tag key to narrow VIP subnets."
}
variable "vip_subnet_tag_value" {
  type        = string
  default     = ""
  description = "Optional tag value to narrow VIP subnets."
}

# 3) Name wildcard
variable "vip_subnet_name_wildcard" {
  type        = string
  default     = ""
  description = "Optional wildcard for tag:Name for VIP (e.g., '*public*')."
}

# VIP tie-break
variable "vip_subnet_selection_mode" {
  type        = string
  default     = "unique" # or "first"
  validation {
    condition     = contains(["unique", "first"], var.vip_subnet_selection_mode)
    error_message = "vip_subnet_selection_mode must be 'unique' or 'first'."
  }
}

