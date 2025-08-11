# Core instance/module inputs (NO subnet/VIP vars here)

variable "aws_region" {
  type = string
}

variable "environment" {
  type = string
}

variable "hostname" {
  type = string
}

variable "domain" {
  type = string
}

variable "private_ip" {
  type    = string
  default = null
}

variable "application_code" {
  type = string
}

variable "application_SID" {
  type = string
}

variable "ha" {
  type = bool
}

variable "ami_ID" {
  type = string
}

variable "instance_type" {
  type = string
}

variable "hana_data_storage_type" {
  type    = string
  default = ""
}

variable "hana_logs_storage_type" {
  type    = string
  default = ""
}

variable "hana_backup_storage_type" {
  type    = string
  default = ""
}

variable "hana_shared_storage_type" {
  type    = string
  default = ""
}

variable "custom_ebs_config" {
  type    = any
  default = null
}

variable "key_name" {
  type = string
}

variable "monitoring" {
  type = bool
}

variable "root_ebs_size" {
  type = string
}

variable "ec2_tags" {
  type = map(any)
}

variable "availability_zone" {
  type = string
}

variable "vpc_id" {
  type = string
}

# Used for primary/VIP ENI security groups
variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "assign_public_eip" {
  description = "Attach a public EIP to the instance's primary ENI"
  type        = bool
  default     = false
}

