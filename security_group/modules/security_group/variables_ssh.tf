# Allow SSH (TCP/22). Leave lists empty to disable.
variable "ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed to SSH (e.g., [\"0.0.0.0/0\"])."
}

variable "ssh_source_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Source SG IDs allowed to SSH (e.g., a bastion SG)."
}
