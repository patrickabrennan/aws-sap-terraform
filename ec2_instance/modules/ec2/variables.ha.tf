############################################
# HA / VIP / Subnet auto-selection inputs
############################################

# Toggle VIP ENI (and optional EIP) creation
variable "enable_vip_eni" {
  type    = bool
  default = false
}

variable "enable_vip_eip" {
  type    = bool
  default = false
}

# -------- Primary ENI subnet selection (for the instance) --------
# If set, use this exact subnet ID. Otherwise, auto-select by VPC+AZ and filters.
variable "subnet_ID" {
  type        = string
  default     = ""
  description = "Optional explicit subnet ID for the instance. Leave empty to auto-select by VPC+AZ+filters."
}

# Optional narrowing filters when auto-selecting:
variable "subnet_tag_key" {
  type    = string
  default = ""
}

variable "subnet_tag_value" {
  type    = string
  default = ""
}

# Matches the Name tag; supports wildcards like *public* or *private*
variable "subnet_name_wildcard" {
  type    = string
  default = ""
}

# Behavior when more than one subnet remains:
# - unique (default) => require exactly 1 match, else fail
# - first            => sort IDs and pick the first deterministically
variable "subnet_selection_mode" {
  type        = string
  default     = "unique"
  validation {
    condition     = contains(["unique", "first"], var.subnet_selection_mode)
    error_message = "subnet_selection_mode must be 'unique' or 'first'."
  }
}

# -------- VIP ENI subnet selection (for the floating IP NIC) --------
# If set, use this exact subnet ID. Otherwise, auto-select by VPC+AZ and filters.
variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "Optional explicit subnet ID for the VIP ENI. Leave empty to auto-select by VPC+AZ+filters."
}

# Optional narrowing filters when auto-selecting VIP subnet:
variable "vip_subnet_tag_key" {
  type    = string
  default = ""
}

variable "vip_subnet_tag_value" {
  type    = string
  default = ""
}

variable "vip_subnet_name_wildcard" {
  type    = string
  default = ""
}

variable "vip_subnet_selection_mode" {
  type        = string
  default     = "unique"
  validation {
    condition     = contains(["unique", "first"], var.vip_subnet_selection_mode)
    error_message = "vip_subnet_selection_mode must be 'unique' or 'first'."
  }
}
