variable "default_availability_zone" {
  type        = string
  description = "Default AZ if a node's AZ isn't specified"
}

variable "ha_azs" {
  type        = list(string)
  default     = []
  description = "When ha=true and node doesn't specify secondary AZ, use [A,B]"
}
