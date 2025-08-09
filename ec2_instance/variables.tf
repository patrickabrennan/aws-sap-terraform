variable "aws_region" {
  description = "AWS region for this workspace"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

# Only add this if you *must* keep a leftover vpc_id var from TFC. Otherwise, delete it in TFC (step 3).
variable "vpc_id" {
  description = "Deprecated/unused. Kept only to silence org-level tfvars."
  type        = string
  default     = ""
}

variable "sap_discovery_tag" {
  description = "Tag key that identifies sap relevant objects"
  type        = string
}

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
