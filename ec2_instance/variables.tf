variable "aws_region"  { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }

variable "instances_to_create" {
  type        = map(any)
  description = "Map of instance configs keyed by logical name"
}

variable "sap_discovery_tag" {
  type    = string
  default = ""
}

variable "assign_public_eip" {
  type    = bool
  default = true
}

variable "enable_vip_eni" {
  type    = bool
  default = false
}
variable "vip_subnet_id" {
  type    = string
  default = ""
}

variable "enable_vip_eip" {
  type    = bool
  default = false
}

variable "instances_to_create" {
  description = "Per-instance config keyed by logical name"
  type = map(object({
    availability_zone         = string
    private_ip                = optional(string)
    domain                    = string
    application_code          = string      # "hana" or "nw"
    application_SID           = string
    ha                        = bool
    ami_ID                    = string
    key_name                  = string
    monitoring                = bool
    root_ebs_size             = number
    ec2_tags                  = map(string)
    instance_type             = string
    # Optional HANA/NW-specific settings
    hana_data_storage_type    = optional(string)
    hana_logs_storage_type    = optional(string)
    hana_backup_storage_type  = optional(string)
    hana_shared_storage_type  = optional(string)
    custom_ebs_config         = optional(any)
  }))
}
