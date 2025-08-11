############################################
# Root-level inputs for subnet auto-select
############################################

# Primary ENI narrowing hints (forwarded into the module)
variable "subnet_tag_key" {
  type    = string
  default = ""
}
variable "subnet_tag_value" {
  type    = string
  default = ""
}
variable "subnet_name_wildcard" {
  type    = string
  default = ""
}
variable "subnet_selection_mode" {
  type        = string
  default     = "unique" # or "first"
  validation {
    condition     = contains(["unique", "first"], var.subnet_selection_mode)
    error_message = "subnet_selection_mode must be 'unique' or 'first'."
  }
}

# VIP ENI narrowing hints (forwarded into the module)
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
  default     = "unique" # or "first"
  validation {
    condition     = contains(["unique", "first"], var.vip_subnet_selection_mode)
    error_message = "vip_subnet_selection_mode must be 'unique' or 'first'."
  }
}
