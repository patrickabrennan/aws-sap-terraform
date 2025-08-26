########################################
# Core / environment
########################################
variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "account_id" {
  type      = string
  default   = ""
  nullable  = true
}
variable "Account_ID" {
  type      = string
  default   = ""
  nullable  = true
}

########################################
# VPC resolution (pick ONE path)
########################################
variable "vpc_id" {
  description = "Explicit VPC ID (wins if set)"
  type        = string
  default     = ""
}

variable "vpc_name" {
  description = "Value of the VPC Name tag to match (e.g., 'sap_vpc')"
  type        = string
  default     = ""
}

variable "vpc_tag_key" {
  description = "Optional arbitrary tag key to match VPC (e.g., 'Project')"
  type        = string
  default     = ""
}

variable "vpc_tag_value" {
  description = "Optional arbitrary tag value to match VPC"
  type        = string
  default     = ""
}

########################################
# Global subnet selection hints
########################################
variable "subnet_tag_key" {
  type        = string
  default     = ""
  description = "Optional tag key to narrow primary subnet selection"
}

variable "subnet_tag_value" {
  type        = string
  default     = ""
  description = "Optional tag value to narrow primary subnet selection"
}

variable "subnet_name_wildcard" {
  type        = string
  default     = ""
  description = "Optional Name wildcard for primary subnet (e.g., '*public*')"
}

variable "subnet_selection_mode" {
  type        = string
  default     = "unique" # or "first"
  description = "If multiple subnets remain: 'unique' (error) or 'first' (auto-pick)"
}

########################################
# Add selection of AMI_ID based on AWS Region 
########################################
variable "ami_id_map" {
  description = "Static map of region -> AMI ID. If set, instances without ami_ID will use ami_id_map[var.aws_region]."
  type        = map(string)
  default     = {}
}


########################################
# VIP ENI/EIP + VIP subnet hints
########################################
variable "enable_vip_eni" {
  type        = bool
  default     = false
  description = "Create a per-instance VIP ENI"
}

variable "enable_vip_eip" {
  type        = bool
  default     = false
  description = "Attach a public EIP to the VIP ENI"
}

# NEW: allow explicit VIP subnet id from root (optional)
variable "vip_subnet_id" {
  type        = string
  default     = ""
  description = "Optional explicit VIP Subnet ID. Leave empty to auto-select by VPC+AZ (+filters)."
}

variable "vip_subnet_tag_key" {
  type        = string
  default     = ""
}

variable "vip_subnet_tag_value" {
  type        = string
  default     = ""
}

variable "vip_subnet_name_wildcard" {
  type        = string
  default     = ""
}

variable "vip_subnet_selection_mode" {
  type        = string
  default     = "unique" # or "first"
}

########################################
# Public EIP on primary ENI (optional)
########################################
variable "assign_public_eip" {
  type        = bool
  default     = false
}

########################################
# KMS inputs (optional)
########################################
variable "kms_key_arn" {
  type        = string
  default     = ""
  description = "KMS key ARN for EBS/root encryption (empty=default)"
}

variable "ebs_kms_ssm_path" {
  type        = string
  default     = ""
  description = "SSM parameter path that stores EBS KMS key ARN"
}

########################################
# Silence org/global tfvars you don't use
########################################
variable "sap_discovery_tag" {
  type        = string
  default     = ""
  description = "Unused; present only to silence TFC var warning"
}

########################################
# Instances map (your dev.auto.tfvars feeds this)
########################################
variable "instances_to_create" {
  description = "Map of instances to create"
  type = map(object({
    # Always-present fields
    domain           = string
    application_code = string
    application_SID  = string
    #comment out ami_id and make optional 
    #ami_ID           = string
    ami_ID           = optional(string)
    key_name         = string
    monitoring       = bool
    root_ebs_size    = number
    ec2_tags         = map(string)
    instance_type    = string

    # Optional / per-instance overrides
    availability_zone        = optional(string)
    private_ip               = optional(string)
    subnet_ID                = optional(string)
    ha                       = optional(bool, false)

    # Optional HANA/NW storage knobs
    hana_data_storage_type   = optional(string)
    hana_logs_storage_type   = optional(string)
    hana_backup_storage_type = optional(string)
    hana_shared_storage_type = optional(string)

    # Optional per-instance custom EBS layout (choose strict schema)
    custom_ebs_config = optional(list(object({
      identifier = string
      disk_nb    = number
      disk_size  = number
      disk_type  = string
      iops       = optional(number)
      throughput = optional(number)
    })))
  }))
}



/*
variable "instances_to_create" {
  description = "Map of instances to create"
  type = map(object({
    #availability_zone        = string
    availability_zone        = optional(string)  # auto-assigned if unset
    domain                   = string
    application_code         = string
    application_SID          = string
    ha                       = bool
    ami_ID                   = string
    key_name                 = string
    monitoring               = bool
    root_ebs_size            = number
    ec2_tags                 = map(any)
    instance_type            = string
    private_ip               = optional(string)
    subnet_ID                = optional(string)  # still allowed; we will autoselect by AZ if empty

    # Optional HANA/NW storage knobs
    hana_data_storage_type   = optional(string)
    hana_logs_storage_type   = optional(string)
    hana_backup_storage_type = optional(string)
    hana_shared_storage_type = optional(string)
    custom_ebs_config        = optional(any)


    #added 8/22/2025 for customer EBS sizes
    # Per-instance custom EBS layout (optional)
    # If you want strict typing, use list(object({ ... })) instead of any:
    custom_ebs_config        = optional(any)
    # Example strict version:
     custom_ebs_config = optional(list(object({
       identifier = string
       disk_nb    = number
       disk_size  = number
       disk_type  = string
       iops       = optional(number)
       throughput = optional(number)
     })))
  }))
}
*/
