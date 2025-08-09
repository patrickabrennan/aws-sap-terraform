variable "custom_ebs_config" {
  description = "Custom EBS configuration list"
  type        = list(map(any))
  default     = []
}

variable "aws_region"       { type = string }
variable "environment"      { type = string }

variable "hostname"         { type = string }
variable "domain"           { type = string }

variable "private_ip" {
  description = "Optional fixed IP"
  type        = string
  default     = ""
}

variable "application_code" { type = string }
variable "application_SID"  { type = string }
variable "ha"               { type = bool }

variable "ami_ID"           { type = string }

# We’re using NON-hardcoded subnet discovery (VPC+AZ+tags), not subnet_ID
variable "vpc_id"            { type = string }
variable "availability_zone" { type = string }
variable "subnet_tag_filters" {
  type        = map(string)
  default     = {}
}

variable "instance_type"     { type = string }

variable "hana_data_storage_type"   { type = string, default = "" }
variable "hana_logs_storage_type"   { type = string, default = "" }
variable "hana_backup_storage_type" { type = string, default = "" }
variable "hana_shared_storage_type" { type = string, default = "" }

variable "key_name"          { type = string }
variable "monitoring"        { type = bool }

# Your module expects string for root size; callers can tostring() it
variable "root_ebs_size"     { type = string }

variable "ec2_tags"          { type = map(any) }

# From earlier step: avoid null iteration
variable "custom_ebs_config" {
  type        = list(map(any))
  default     = []
}
