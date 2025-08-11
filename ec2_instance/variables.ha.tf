variable "enable_vip_eip" {
  type        = bool
  default     = true       # set false if you don’t want a public IP
  description = "Attach an Elastic IP to each VIP ENI."
}
