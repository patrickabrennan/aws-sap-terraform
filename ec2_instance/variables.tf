variable "instances_to_create" {
  description = "Map of instances to create"
  type = map(object({
    domain                   = string
    application_code         = string
    application_SID          = string
    ha                       = bool
    ami_ID                   = string
    subnet_ID                = optional(string, "")
    key_name                 = string
    monitoring               = bool
    root_ebs_size            = number
    ec2_tags                 = map(any)
    instance_type            = string
    private_ip               = optional(string, "")
    hana_data_storage_type   = optional(string, "")
    hana_logs_storage_type   = optional(string, "")
    hana_backup_storage_type = optional(string, "")
    hana_shared_storage_type = optional(string, "")
  }))
}
