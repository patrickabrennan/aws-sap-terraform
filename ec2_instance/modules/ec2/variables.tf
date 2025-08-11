variable "aws_region"  { type = string }
variable "environment" { type = string }

variable "vpc_id"            { type = string }
variable "availability_zone" { type = string }

variable "hostname"         { type = string }
variable "domain"           { type = string }
variable "private_ip"       { type = string,  default = null }
variable "application_code" { type = string } # "hana" or "nw"
variable "application_SID"  { type = string }
variable "ha"               { type = bool }
variable "ami_ID"           { type = string }
variable "instance_type"    { type = string }

variable "hana_data_storage_type"   { type = string, default = "" }
variable "hana_logs_storage_type"   { type = string, default = "" }
variable "hana_backup_storage_type" { type = string, default = "" }
variable "hana_shared_storage_type" { type = string, default = "" }

variable "custom_ebs_config" {
  description = "Optional custom EBS layout (list of objects)"
  type        = any
  default     = []
}

variable "key_name"      { type = string }
variable "monitoring"    { type = bool }
variable "root_ebs_size" { type = string }

variable "ec2_tags" {
  type    = map(any)
  default = {}
}

variable "assign_public_eip" {
  type        = bool
  default     = false
  description = "Attach an Elastic IP to the instance primary ENI"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "Security group IDs to attach to the primary ENI"
}

variable "kms_key_arn" {
  type        = string
  default     = null
  description = "Optional KMS key ARN for EBS encryption; null = default AWS managed"
}





/*
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
  default = ""
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

# Non-hardcoded subnet discovery inputs
variable "vpc_id" {
  type = string
}

variable "availability_zone" {
  type = string
}

variable "subnet_tag_filters" {
  type    = map(string)
  default = {}
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

variable "key_name" {
  type = string
}

variable "monitoring" {
  type = bool
}

# Module expects string; callers can wrap with tostring()
variable "root_ebs_size" {
  type = string
}

variable "ec2_tags" {
  type = map(any)
}

variable "custom_ebs_config" {
  type    = list(map(any))
  default = []
}

variable "assign_public_eip" {
  type        = bool
  default     = false
  description = "Attach an Elastic IP to the instance primary ENI for public access."
}
*/
