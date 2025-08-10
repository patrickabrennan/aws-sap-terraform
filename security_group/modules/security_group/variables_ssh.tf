# modules/security_group/variables_ssh.tf
# Keep only the per-invocation flags here. The SSH vars already exist in variables.tf.

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
