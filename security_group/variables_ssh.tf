# modules/security_group/variables_ssh.tf
# (remove ssh_cidrs / ssh_source_security_group_ids from this file)

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
