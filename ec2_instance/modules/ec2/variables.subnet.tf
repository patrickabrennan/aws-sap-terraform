##############################################
# Subnet auto-selection controls (module vars)
##############################################

# Primary ENI subnet — leave empty to auto-select by VPC+AZ (+ optional filters)
variable "subnet_ID" {
  type        = string
  default     = ""
  description = "If empty, auto-select by VPC+AZ (+ optional tag/name filters)."
}
variable "subnet_tag_key" {
  type        = string
  default     = ""
}
variable "subnet_tag_value" {
  type        = string
  default     = ""
}
variable "subnet_name_wildcard" {
  type        = string
  default     = ""
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

# VIP ENI subnet — leave empty to auto-select by VPC+AZ (+ optional filters)
variable "vip_subnet_id" {
  type        = string
  default     = ""
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
