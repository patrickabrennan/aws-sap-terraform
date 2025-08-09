variable "custom_ebs_config" {
  description = "Custom EBS configuration list"
  type        = list(map(any))
  default     = []
}
