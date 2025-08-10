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

# variables.ha.tf  (ROOT MODULE)

# Two AZs to place HA nodes when ha = true
variable "ha_azs" {
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
  description = "Two AZs used for HA pairs."
}

# Fallback AZ for non-HA instances if not set per instance
variable "default_availability_zone" {
  type        = string
  default     = "us-east-1a"
  description = "Default AZ for non-HA instances."
}

# Optional floating ENI VIP (same-AZ only). Leave false for cross-AZ HA.
variable "enable_vip_eni" {
  type        = bool
  default     = false
  description = "Create a floating ENI per HA group (only valid when both nodes share the same subnet/AZ)."
}

# If you enable the VIP ENI, you can pin it to a specific subnet (same AZ as active node)
variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "Subnet ID for the VIP ENI; leave empty to auto-pick from var.vpc_id."
}

# Optional fixed private IP for the VIP ENI
variable "vip_private_ip" {
  type        = string
  default     = ""
  description = "Fixed private IP for the VIP ENI; leave empty to auto-assign."
}

variable "instances_to_create" {
  description = "Map of instances to create"
  type = map(object({
    availability_zone        = string
    custom_ebs_config = optional(list(map(any)), [])
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
