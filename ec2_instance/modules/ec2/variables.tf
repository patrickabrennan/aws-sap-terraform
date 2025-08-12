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

variable "vpc_id" {
  description = "VPC ID where resources will be created"
  type        = string
}

variable "availability_zone" {
  description = "AZ for this instance (e.g., us-east-1a)"
  type        = string
}

########################################
# EC2 / instance identity
########################################
variable "hostname" {
  description = "Hostname for this instance (used in names and tags)"
  type        = string
}

variable "domain" {
  description = "DNS domain for the host"
  type        = string
}

variable "private_ip" {
  description = "Optional static private IP to assign to the ENI (null to auto-assign)"
  type        = string
  default     = null
}

variable "application_code" {
  description = "App code (e.g., 'hana' or 'nw')"
  type        = string
}

variable "application_SID" {
  description = "Application SID"
  type        = string
}

variable "ha" {
  description = "Whether this node is part of an HA pair"
  type        = bool
}

variable "ami_ID" {
  description = "AMI ID to launch"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
}

variable "monitoring" {
  description = "Enable detailed monitoring for the instance"
  type        = bool
  default     = false
}

variable "root_ebs_size" {
  description = "Root volume size (GB) as a string"
  type        = string
}

variable "ec2_tags" {
  description = "Additional tags to apply to EC2 resources"
  type        = map(any)
  default     = {}
}

########################################
# EBS layout selection (HANA/NW presets)
########################################
variable "hana_data_storage_type" {
  description = "Storage type for HANA data (gp3, io2, etc)"
  type        = string
  default     = ""
}

variable "hana_logs_storage_type" {
  description = "Storage type for HANA logs (gp3, io2, etc)"
  type        = string
  default     = ""
}

variable "hana_backup_storage_type" {
  description = "Storage type for HANA backup (st1, gp3, etc)"
  type        = string
  default     = ""
}

variable "hana_shared_storage_type" {
  description = "Storage type for HANA shared (gp3, etc)"
  type        = string
  default     = ""
}

variable "custom_ebs_config" {
  description = "Optional custom EBS layout (list of maps); if empty, defaults/specs are used"
  type        = any
  default     = []
}

########################################
# KMS / encryption
########################################
variable "kms_key_arn" {
  description = "KMS key ARN to encrypt EBS and root volume (empty to use default volume encryption settings)"
  type        = string
  default     = ""
}

variable "ebs_kms_ssm_path" {
  description = "Optional SSM Parameter Store path that holds the EBS KMS key ARN (e.g., /env/kms/ebs/arn)"
  type        = string
  default     = ""
}

########################################
# Public EIP assignment for primary ENI (optional)
########################################
variable "assign_public_eip" {
  description = "Attach a public EIP to the primary ENI of this instance"
  type        = bool
  default     = false
}

########################################
# Subnet selection (primary ENI) – no hardcoding required
########################################
variable "subnet_ID" {
  description = "Optional explicit Subnet ID for the primary ENI. Leave empty to auto-select by VPC+AZ (with optional narrowing rules)."
  type        = string
  default     = ""
}

variable "subnet_tag_key" {
  description = "Optional tag key to narrow subnet selection (e.g., 'Tier')"
  type        = string
  default     = ""
}

variable "subnet_tag_value" {
  description = "Optional tag value to narrow subnet selection (e.g., 'app')"
  type        = string
  default     = ""
}

variable "subnet_name_wildcard" {
  description = "Optional Name tag wildcard to narrow subnet selection (e.g., '*public*' or '*private*')"
  type        = string
  default     = ""
}

variable "subnet_selection_mode" {
  description = "If multiple subnets remain after filtering: 'unique' (error) or 'first' (auto-pick the first)"
  type        = string
  default     = "unique"
}

########################################
# VIP ENI + VIP EIP (optional)
########################################
variable "enable_vip_eni" {
  description = "Create a VIP ENI for HA scenarios"
  type        = bool
  default     = false
}

variable "enable_vip_eip" {
  description = "Attach a public EIP to the VIP ENI"
  type        = bool
  default     = false
}

variable "vip_subnet_id" {
  description = "Optional explicit Subnet ID for the VIP ENI. Leave empty to auto-select by VPC+AZ (with optional narrowing rules)."
  type        = string
  default     = ""
}

variable "vip_subnet_tag_key" {
  description = "Optional tag key to narrow VIP subnet selection"
  type        = string
  default     = ""
}

variable "vip_subnet_tag_value" {
  description = "Optional tag value to narrow VIP subnet selection"
  type        = string
  default     = ""
}

variable "vip_subnet_name_wildcard" {
  description = "Optional Name tag wildcard to narrow VIP subnet selection (e.g., '*public*' or '*private*')"
  type        = string
  default     = ""
}

variable "vip_subnet_selection_mode" {
  description = "If multiple VIP subnets remain after filtering: 'unique' (error) or 'first' (auto-pick the first)"
  type        = string
  default     = "unique"
}
