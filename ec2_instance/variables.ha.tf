# root/variables.ha.tf  (HA placement ONLY)

variable "default_availability_zone" {
  type = string
}

variable "ha_azs" {
  type    = list(string)
  default = []
}
