# --- Subnet auto-selection controls (primary ENI) ---
variable "subnet_ID" {
  type        = string
  default     = ""
  description = "If empty, auto-select by VPC+AZ (+ optional tag/name filters)."
}

variable "subnet_tag_key" {
  type        = string
  default     = ""
  description = "Optional tag key to filter subnets (e.g., 'Tier')."
}

variable "subnet_tag_value" {
  type        = string
  default     = ""
  description = "Optional tag value to filter subnets (e.g., 'app')."
}

variable "subnet_name_wildcard" {
  type        = string
  default     = ""
  description = "Optional wildcard for tag:Name filter (e.g., '*public*')."
}

variable "subnet_selection_mode" {
  type        = string
  default     = "unique"
  description = "'unique' requires exactly one match; 'first' picks the first after sorting IDs."
  validation {
    condition     = contains(["unique","first"], var.subnet_selection_mode)
    error_message = "subnet_selection_mode must be 'unique' or 'first'."
  }
}

# --- VIP ENI auto-selection controls ---
variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "If empty and VIP enabled, auto-select by VPC+AZ (+ optional tag/name filters)."
}

variable "vip_subnet_tag_key" {
  type        = string
  default     = ""
}

variable "vip_subnet_tag_value" {
  type        = string
  default     = ""
}

variable "vip_subnet_name_wildcard" {
  type        = string
  default     = ""
}

variable "vip_subnet_selection_mode" {
  type        = string
  default     = "unique"
  validation {
    condition     = contains(["unique","first"], var.vip_subnet_selection_mode)
    error_message = "vip_subnet_selection_mode must be 'unique' or 'first'."
  }
}
