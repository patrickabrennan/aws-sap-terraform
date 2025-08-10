variable "ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed for SSH."
}

variable "ssh_source_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Source SG IDs allowed for SSH."
}

# Which SG(s) does THIS module instance manage?
variable "manage_app1" {
  type        = bool
  default     = false
  description = "This module invocation manages the app1 SG."
}

variable "manage_db1" {
  type        = bool
  default     = false
  description = "This module invocation manages the db1 SG."
}
