# Required by provider/module
variable "aws_region" {
  description = "Region where to run this TF"
  type        = string
}

variable "environment" {
  description = "Environment (dev, qa, prd)"
  type        = string
}

# Used by eni.tf
variable "hostname" {
  description = "Hostname"
  type        = string
}

variable "subnet_ID" {
  description = "Subnet ID for the ENI"
  type        = string
}

variable "application_code" {
  description = "Short code for app (e.g., hana, nw, etc.)"
  type        = string
}

# Optional private IP (let AWS assign if null)
variable "private_ip" {
  description = "Optional static private IP for the ENI"
  type        = string
  default     = null
  nullable    = true
}

# Passed from ec2_instance/main.tf into the module
variable "domain" {
  description = "DNS domain"
  type        = string
}

variable "application_SID" {
  description = "SAP SID (if applicable)"
  type        = string
}

variable "ha" {
  description = "High availability enabled"
  type        = bool
}

variable "ami_ID" {
  description = "AMI to use"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "hana_data_storage_type" {
  description = "HANA data storage type (optional)"
  type        = string
  default     = null
}

variable "hana_logs_storage_type" {
  description = "HANA logs storage type (optional)"
  type        = string
  default     = null
}

variable "hana_backup_storage_type" {
  description = "HANA backup storage type (optional)"
  type        = string
  default     = null
}

variable "hana_shared_storage_type" {
  description = "HANA shared storage type (optional)"
  type        = string
  default     = null
}

variable "custom_ebs_config" {
  description = "Optional custom EBS layout"
  type        = list(any)
  default     = []
}

variable "key_name" {
  description = "SSH key name"
  type        = string
}

variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
}

# Keep as string to match your existing module usage
variable "root_ebs_size" {
  description = "Root volume size (GiB)"
  type        = string
}

variable "ec2_tags" {
  description = "Tags to apply to EC2 resources"
  type        = map(any)
}
















variable "instances_to_create" {
  description = "Data for instances to create"
  type        = any
}

variable "vpc_id" {
  description = "VPC ID for resources"
  type        = string
  default     = null
}

variable "sap_discovery_tag" {
  description = "SAP discovery tag"
  type        = string
  default     = null
}

variable "private_ip" {
  description = "Optional static private IP"
  type        = string
  default     = null
  nullable    = true
}
