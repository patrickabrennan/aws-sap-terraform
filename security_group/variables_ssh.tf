# security_group/variables_ssh.tf (ROOT)
variable "ssh_cidrs" {
  type        = list(string)
  default     = []
  description = "CIDR blocks allowed for SSH (e.g., [\"0.0.0.0/0\"])."
}

variable "ssh_source_security_group_ids" {
  type        = list(string)
  default     = []
  description = "Source SG IDs allowed for SSH."
}
