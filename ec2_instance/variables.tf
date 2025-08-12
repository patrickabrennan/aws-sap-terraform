# root/variables.tf

variable "aws_region"  { type = string }
variable "environment" { type = string }
variable "vpc_id"      { type = string }

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

variable "enable_vip_eip" {
  type        = bool
  default     = false
  description = "Attach a public EIP to the VIP ENI when true"
}


variable "vip_subnet_id" {
  type    = string
  default = ""
}

# ---- Subnet narrowing for instances ----
variable "subnet_tag_key" { 
  type = string 
  default = "" 
}

variable "subnet_tag_value" { 
  type = string 
  default = "" 
}

variable "subnet_name_wildcard" {
  type = string 
  default = "" 
}

variable "subnet_selection_mode" {
  type    = string
  default = "unique" # or "first"
  validation {
    condition     = contains(["unique","first"], var.subnet_selection_mode)
    error_message = "subnet_selection_mode must be 'unique' or 'first'."
  }
}

# ---- Subnet narrowing for VIP ENI (HA) ----
variable "vip_subnet_tag_key" {
  type = string 
  default = "" 
}

variable "vip_subnet_tag_value" {
  type = string
  default = "" 
}

variable "vip_subnet_name_wildcard" {
  type = string 
  default = "" 
}

variable "vip_subnet_selection_mode" {
  type    = string
  default = "unique" # or "first"
  validation {
    condition     = contains(["unique","first"], var.vip_subnet_selection_mode)
    error_message = "vip_subnet_selection_mode must be 'unique' or 'first'."
  }
}

#add this to ID VPC
variable "vpc_name" {
  description = "Match VPC by Name tag exactly (optional alternative). Optional: match VPC by Name tag (exact)"
  type        = string
  default     = "sap_vpc"
}

variable "vpc_tag_key" {
  description = "Optional: arbitrary VPC tag key to match (used with vpc_tag_value)"
  type        = string
  default     = ""
}

variable "vpc_tag_value" {
  description = "Optional: arbitrary VPC tag value to match (used with vpc_tag_key)"
  type        = string
  default     = ""
}
